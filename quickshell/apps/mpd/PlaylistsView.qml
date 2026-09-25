import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components"
import "../../themes"

Item {
    id: view

    readonly property var s: Styles.mpdClient.content

    property var contextMenu: null
    property var refreshQueue: null
    property var promptNewPlaylist: null
    property var clearSearch: null
    property string searchQuery: ""
    property var searchResults: ({ artists: [], albums: [], tracks: [], playlists: [] })
    property bool searchLoading: false
    property bool committingSearch: false

    signal mutated(var data)

    property var playlists: []
    property var tracks: []
    property var selectedPlaylists: []
    property var selectedTrackFiles: []
    property string pendingFocusPlaylist: ""
    property bool loadingPlaylists: false
    property bool loadingTracks: false
    property var libraryInfo: ({ mode: "none" })
    property var pendingMenuTrackFiles: []
    property var pendingMenuPlaylists: []
    property real pendingMenuX: 0
    property real pendingMenuY: 0

    readonly property bool searching: (searchQuery || "").trim().length > 0

    readonly property var shownPlaylists: searching
        ? (searchResults?.playlists || [])
        : playlists
    readonly property var shownTracks: searching
        ? (searchResults?.tracks || [])
        : tracks

    onSearchingChanged: {
        if (searching) {
            loadingPlaylists = false
            loadingTracks = false
        } else if (!committingSearch) {
            if (currentOf(selectedPlaylists))
                reloadCurrent()
            else
                refreshPlaylists()
        }
    }

    function toggleKey(list, key) {
        const next = Array.isArray(list) ? list.slice() : []
        const i = next.indexOf(key)
        if (i >= 0)
            next.splice(i, 1)
        else
            next.push(key)
        return next
    }

    function hasCtrl(modifiers) {
        return !!(modifiers & Qt.ControlModifier)
    }

    function currentOf(list) {
        if (!Array.isArray(list) || list.length < 1)
            return ""
        return list[list.length - 1] || ""
    }

    function setInfo(data) {
        libraryInfo = data && data.ok ? data : ({ mode: "none" })
    }

    function clearInfo() {
        setInfo({ mode: "none" })
    }

    function refreshPlaylists(focusName) {
        pendingFocusPlaylist = focusName || ""
        loadingPlaylists = true
        playlistsProc.exec(["playlists"])
    }

    function reloadCurrent() {
        const playlist = currentOf(selectedPlaylists)
        if (!playlist)
            return
        const track = currentOf(selectedTrackFiles)
        loadTracksFor(playlist)
        if (track)
            infoProc.exec(["songinfo", track])
        else
            infoProc.exec(["playlistinfo", playlist])
    }

    function reloadPlaylist(name) {
        if (!name)
            return
        if (currentOf(selectedPlaylists) === name)
            reloadCurrent()
    }

    function loadTracksFor(name) {
        if (!name) {
            tracks = []
            loadingTracks = false
            return
        }
        loadingTracks = true
        tracksProc.exec(["playlisttracks", name])
    }

    function commitSearchPick(opts) {
        const playlist = opts?.playlist || ""
        const file = opts?.file || ""
        committingSearch = true
        if (typeof clearSearch === "function")
            clearSearch()
        committingSearch = false

        selectedTrackFiles = file ? [file] : []
        selectedPlaylists = playlist ? [playlist] : []
        tracks = []

        if (playlist) {
            loadTracksFor(playlist)
            if (file)
                infoProc.exec(["songinfo", file])
            else
                infoProc.exec(["playlistinfo", playlist])
        } else if (file) {
            infoProc.exec(["songinfo", file])
            refreshPlaylists()
        } else {
            clearInfo()
            refreshPlaylists()
        }
    }

    function selectPlaylist(name) {
        const current = currentOf(selectedPlaylists)
        selectedTrackFiles = []
        selectedPlaylists = name ? [name] : []
        if (current === name) {
            if (name)
                infoProc.exec(["playlistinfo", name])
            return
        }
        tracks = []
        if (!name) {
            clearInfo()
            return
        }
        loadTracksFor(name)
        infoProc.exec(["playlistinfo", name])
    }

    function clickPlaylist(name, modifiers) {
        if (searching) {
            commitSearchPick({ playlist: name })
            return
        }
        if (hasCtrl(modifiers)) {
            const current = currentOf(selectedPlaylists)
            selectedPlaylists = toggleKey(selectedPlaylists, name)
            selectedTrackFiles = []
            if (selectedPlaylists.indexOf(name) >= 0) {
                if (current !== name) {
                    tracks = []
                    loadTracksFor(name)
                }
                infoProc.exec(["playlistinfo", name])
            } else if (current === name) {
                const next = currentOf(selectedPlaylists)
                if (next) {
                    tracks = []
                    loadTracksFor(next)
                    infoProc.exec(["playlistinfo", next])
                } else {
                    selectPlaylist("")
                }
            }
            return
        }
        selectPlaylist(name)
    }

    function selectTrack(item) {
        if (!item || !item.file)
            return
        selectedTrackFiles = [item.file]
        infoProc.exec(["songinfo", item.file])
    }

    function clickTrack(item, modifiers) {
        if (!item || !item.file)
            return
        if (searching) {
            commitSearchPick({ file: item.file })
            return
        }
        const file = item.file
        if (hasCtrl(modifiers)) {
            const current = currentOf(selectedTrackFiles)
            selectedTrackFiles = toggleKey(selectedTrackFiles, file)
            if (selectedTrackFiles.indexOf(file) >= 0) {
                infoProc.exec(["songinfo", file])
            } else if (current === file) {
                const next = currentOf(selectedTrackFiles)
                const playlist = currentOf(selectedPlaylists)
                if (next)
                    infoProc.exec(["songinfo", next])
                else if (playlist)
                    infoProc.exec(["playlistinfo", playlist])
                else
                    clearInfo()
            }
            return
        }
        selectTrack(item)
    }

    function playTrack(item) {
        if (!item || !item.file)
            return
        selectTrack(item)
        playProc.exec(["playfile", item.file])
    }

    function playPlaylist(name) {
        if (!name)
            return
        selectPlaylist(name)
        playProc.exec(["playplaylist", name])
    }

    function openPlaylistContextMenu(name, x, y) {
        if (!name || !view.contextMenu)
            return
        if (selectedPlaylists.indexOf(name) < 0)
            selectPlaylist(name)
        const names = selectedPlaylists.slice()
        pendingMenuPlaylists = names
        pendingMenuTrackFiles = []
        pendingMenuX = x
        pendingMenuY = y
        view.contextMenu.openAt(x, y, [
            {
                text: "add to queue",
                submenu: [
                    {
                        text: "after this",
                        action: () => actionProc.exec(
                            ["queueaddplaylistmany", "next"].concat(names))
                    },
                    {
                        text: "to end",
                        action: () => actionProc.exec(
                            ["queueaddplaylistmany", "end"].concat(names))
                    }
                ]
            },
            { separator: true },
            {
                text: "delete playlist",
                action: () => actionProc.exec(["rmplaylistmany"].concat(names))
            }
        ], { playlists: names })
    }

    function openTrackContextMenu(item, x, y) {
        if (!item || !item.file || !view.contextMenu)
            return
        if (selectedTrackFiles.indexOf(item.file) < 0)
            selectTrack(item)
        pendingMenuTrackFiles = selectedTrackFiles.slice()
        pendingMenuPlaylists = []
        pendingMenuX = x
        pendingMenuY = y
        playlistsMenuProc.exec(["playlists"])
    }

    function showTrackContextMenu(playlists) {
        const files = pendingMenuTrackFiles.slice()
        if (!files.length || !view.contextMenu)
            return
        const currentPl = currentOf(view.selectedPlaylists)
        const names = Array.isArray(playlists) ? playlists : []
        const playlistChildren = names.map((name) => ({
            text: name,
            action: () => actionProc.exec(["playlistaddmany", name].concat(files))
        }))
        if (playlistChildren.length)
            playlistChildren.push({ separator: true })
        playlistChildren.push({
            text: "create new",
            action: () => {
                if (typeof view.promptNewPlaylist !== "function")
                    return
                view.promptNewPlaylist((name) => {
                    if (!name)
                        return
                    actionProc.exec(["playlistaddmany", name].concat(files))
                })
            }
        })

        const entries = [
            {
                text: "add to queue",
                submenu: [
                    {
                        text: "after this",
                        action: () => actionProc.exec(["queueaddmany", "next"].concat(files))
                    },
                    {
                        text: "to end",
                        action: () => actionProc.exec(["queueaddmany", "end"].concat(files))
                    }
                ]
            },
            {
                text: "add to playlist",
                submenu: playlistChildren
            }
        ]
        if (currentPl) {
            entries.push({
                text: "remove from playlist",
                action: () => actionProc.exec(
                    ["playlistremovemany", currentPl].concat(files))
            })
        }
        entries.push({ separator: true })
        entries.push({
            text: "delete",
            action: () => actionProc.exec(["songdeletemany"].concat(files))
        })

        view.contextMenu.openAt(view.pendingMenuX, view.pendingMenuY, entries, { files: files })
    }

    Component.onCompleted: refreshPlaylists()

    ToolProcess {
        id: playlistsProc
        tag: "mpd-playlists"
        onResult: (data) => {
            view.loadingPlaylists = false
            if (!data || !data.ok) {
                console.log("[mpd] playlists:", data?.error || "failed")
                view.playlists = []
                return
            }
            view.playlists = data.playlists || []
            const focus = view.pendingFocusPlaylist
            view.pendingFocusPlaylist = ""

            if (!view.playlists.length) {
                view.selectPlaylist("")
                return
            }

            const current = currentOf(view.selectedPlaylists)
            if (focus && view.playlists.indexOf(focus) >= 0) {
                if (current === focus)
                    view.reloadCurrent()
                else
                    view.selectPlaylist(focus)
                return
            }

            if (!current || view.playlists.indexOf(current) < 0) {
                view.selectPlaylist(view.playlists[0])
                return
            }

            // Keep selection, but reload songs/info so additions show up.
            view.reloadCurrent()
        }
    }

    ToolProcess {
        id: tracksProc
        tag: "mpd-playlist-tracks"
        onResult: (data) => {
            view.loadingTracks = false
            if (!data || !data.ok) {
                console.log("[mpd] playlisttracks:", data?.error || "failed")
                view.tracks = []
                return
            }
            if (data.playlist !== currentOf(view.selectedPlaylists))
                return
            view.tracks = data.tracks || []
        }
    }

    ToolProcess {
        id: infoProc
        tag: "mpd-playlist-info"
        onResult: (data) => {
            if (!data || !data.ok) {
                console.log("[mpd] playlist info:", data?.error || "failed")
                return
            }
            const playlist = currentOf(view.selectedPlaylists)
            const track = currentOf(view.selectedTrackFiles)
            if (data.mode === "playlist" && (data.playlist !== playlist || track))
                return
            if (data.mode === "song" && data.file !== track)
                return
            view.setInfo(data)
        }
    }

    ToolProcess {
        id: playProc
        tag: "mpd-playlist-play"
        onResult: (data) => {
            if (!data || !data.ok) {
                console.log("[mpd] playlist play:", data?.error || "failed")
                return
            }
            view.mutated({ mutated: "queue" })
        }
    }

    ToolProcess {
        id: playlistsMenuProc
        tag: "mpd-pl-menu-playlists"
        onResult: (data) => {
            if (!data || !data.ok) {
                console.log("[mpd] playlists menu:", data?.error || "failed")
                view.showTrackContextMenu([])
                return
            }
            view.showTrackContextMenu(data.playlists || [])
        }
    }

    ToolProcess {
        id: actionProc
        tag: "mpd-pl-track-action"
        onResult: (data) => {
            if (!data || !data.ok) {
                console.log("[mpd] playlist track action:", data?.error || "failed")
                return
            }
            if (data.deletedFile !== undefined || data.removed !== undefined || data.files) {
                const gone = data.files || (data.file ? [data.file] : [])
                if (gone.length) {
                    view.selectedTrackFiles = view.selectedTrackFiles.filter(f => gone.indexOf(f) < 0)
                    const playlist = currentOf(view.selectedPlaylists)
                    const track = currentOf(view.selectedTrackFiles)
                    if (playlist)
                        infoProc.exec(track
                            ? ["songinfo", track]
                            : ["playlistinfo", playlist])
                    else
                        view.clearInfo()
                }
            }
            if (data.removedPlaylist) {
                const removed = data.playlists || (data.playlist ? [data.playlist] : [])
                const current = currentOf(view.selectedPlaylists)
                view.selectedPlaylists = view.selectedPlaylists.filter(p => removed.indexOf(p) < 0)
                if (removed.indexOf(current) >= 0) {
                    view.selectedTrackFiles = []
                    view.tracks = []
                    const next = currentOf(view.selectedPlaylists)
                    if (next) {
                        view.loadTracksFor(next)
                        infoProc.exec(["playlistinfo", next])
                    } else {
                        view.clearInfo()
                    }
                }
            }
            view.mutated(data)
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: view.s.spacing

        ColumnList {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            menuTarget: view.contextMenu || view
            title: "playlists"
            model: view.shownPlaylists
            selectedKeys: view.searching ? [] : view.selectedPlaylists
            loading: view.searching ? view.searchLoading : view.loadingPlaylists
            emptyText: view.searching ? "no matches" : "no playlists"
            onItemClicked: (item, modifiers) => view.clickPlaylist(item, modifiers)
            onItemDoubleClicked: (item) => {
                if (view.searching) {
                    view.commitSearchPick({ playlist: item })
                    Qt.callLater(() => view.playPlaylist(item))
                    return
                }
                view.playPlaylist(item)
            }
            onItemRightClicked: (item, x, y) => {
                if (view.searching) {
                    view.commitSearchPick({ playlist: item })
                    Qt.callLater(() => view.openPlaylistContextMenu(item, x, y))
                    return
                }
                view.openPlaylistContextMenu(item, x, y)
            }
        }

        ColumnList {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            menuTarget: view.contextMenu || view
            title: "songs"
            model: view.shownTracks
            selectedKeys: view.searching ? [] : view.selectedTrackFiles
            loading: view.searching ? view.searchLoading : view.loadingTracks
            emptyText: view.searching
                ? "no matches"
                : (currentOf(view.selectedPlaylists) ? "no songs" : "no playlists")
            keyOf: (item) => item?.file || ""
            labelOf: (item) => {
                if (!item)
                    return ""
                if (typeof item === "string")
                    return item
                const title = item.title || item.file || ""
                let label = item.track ? (item.track + ". " + title) : title
                if (view.searching && item.artist)
                    label += " — " + item.artist
                return label
            }
            onItemClicked: (item, modifiers) => view.clickTrack(item, modifiers)
            onItemDoubleClicked: (item) => {
                if (view.searching) {
                    view.commitSearchPick({ file: item?.file || "" })
                    Qt.callLater(() => view.playTrack(item))
                    return
                }
                view.playTrack(item)
            }
            onItemRightClicked: (item, x, y) => {
                if (view.searching) {
                    view.commitSearchPick({ file: item?.file || "" })
                    Qt.callLater(() => view.openTrackContextMenu(item, x, y))
                    return
                }
                view.openTrackContextMenu(item, x, y)
            }
        }
    }
}
