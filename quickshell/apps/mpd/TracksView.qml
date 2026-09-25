import QtQuick
import QtQuick.Layouts
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

    property var artists: []
    property var albums: []
    property var tracks: []
    property var selectedArtists: []
    property var selectedAlbums: []
    property var selectedTrackFiles: []
    // Album whose tracks are shown when no album is explicitly selected.
    property string previewAlbum: ""
    property bool loadingArtists: false
    property bool loadingAlbums: false
    property bool loadingTracks: false
    property bool refreshingLibrary: false
    property var libraryInfo: ({ mode: "none" })
    property var pendingMenuTrackFiles: []
    property var pendingMenuAlbums: []
    property var pendingMenuArtists: []
    property string pendingMenuKind: "track"
    property real pendingMenuX: 0
    property real pendingMenuY: 0

    readonly property bool searching: (searchQuery || "").trim().length > 0
    readonly property string albumForTracks: view.currentOf(selectedAlbums) || previewAlbum

    readonly property var shownArtists: searching ? (searchResults?.artists || []) : artists
    readonly property var shownAlbums: searching ? (searchResults?.albums || []) : albums
    readonly property var shownTracks: searching ? (searchResults?.tracks || []) : tracks

    onSearchingChanged: {
        if (searching) {
            loadingArtists = false
            loadingAlbums = false
            loadingTracks = false
        } else if (!committingSearch) {
            refreshArtists()
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

    function refreshArtists() {
        loadingArtists = true
        artistsProc.exec(["artists"])
    }

    function refreshLibrary() {
        if (refreshingLibrary)
            return
        refreshingLibrary = true
        loadingArtists = true
        updateProc.exec(["update"])
    }

    function commitSearchPick(opts) {
        const artist = opts?.artist || ""
        const album = opts?.album || ""
        const file = opts?.file || ""
        committingSearch = true
        if (typeof clearSearch === "function")
            clearSearch()
        committingSearch = false

        selectedArtists = artist ? [artist] : []
        selectedAlbums = album ? [album] : []
        selectedTrackFiles = file ? [file] : []
        previewAlbum = ""
        albums = []
        tracks = []

        if (!artist) {
            clearInfo()
            refreshArtists()
            return
        }

        loadingAlbums = true
        albumsProc.exec(["albums", artist])
        if (album) {
            loadingTracks = true
            tracksProc.exec(["tracks", artist, album])
        }
        if (file)
            infoProc.exec(["songinfo", file])
        else if (album)
            infoProc.exec(["albuminfo", artist, album])
        else
            infoProc.exec(["artistinfo", artist])
    }

    function loadTracksFor(album) {
        const artist = view.currentOf(selectedArtists)
        if (!artist || !album) {
            tracks = []
            loadingTracks = false
            return
        }
        loadingTracks = true
        tracksProc.exec(["tracks", artist, album])
    }

    function selectArtist(name) {
        const current = view.currentOf(selectedArtists)
        selectedTrackFiles = []
        selectedAlbums = []
        selectedArtists = name ? [name] : []
        if (current === name) {
            if (name)
                infoProc.exec(["artistinfo", name])
            return
        }
        previewAlbum = ""
        albums = []
        tracks = []
        if (!name) {
            clearInfo()
            return
        }
        loadingAlbums = true
        albumsProc.exec(["albums", name])
        infoProc.exec(["artistinfo", name])
    }

    function clickArtist(name, modifiers) {
        if (searching) {
            commitSearchPick({ artist: name })
            return
        }
        if (hasCtrl(modifiers)) {
            const current = view.currentOf(selectedArtists)
            selectedArtists = toggleKey(selectedArtists, name)
            if (selectedArtists.indexOf(name) >= 0) {
                if (current !== name) {
                    selectedAlbums = []
                    selectedTrackFiles = []
                    previewAlbum = ""
                    albums = []
                    tracks = []
                    loadingAlbums = true
                    albumsProc.exec(["albums", name])
                }
                infoProc.exec(["artistinfo", name])
            } else if (current === name) {
                const next = view.currentOf(selectedArtists)
                if (next) {
                    selectedAlbums = []
                    selectedTrackFiles = []
                    previewAlbum = ""
                    albums = []
                    tracks = []
                    loadingAlbums = true
                    albumsProc.exec(["albums", next])
                    infoProc.exec(["artistinfo", next])
                } else {
                    selectArtist("")
                }
            }
            return
        }
        selectArtist(name)
    }

    function selectAlbum(name) {
        const current = view.currentOf(selectedAlbums)
        const artist = view.currentOf(selectedArtists)
        selectedTrackFiles = []
        selectedAlbums = name ? [name] : []
        if (current === name) {
            if (name && artist)
                infoProc.exec(["albuminfo", artist, name])
            return
        }
        previewAlbum = ""
        tracks = []
        if (!name || !artist) {
            // Fall back to previewing the first album without selecting it.
            previewAlbum = albums.length ? albums[0] : ""
            loadTracksFor(previewAlbum)
            if (artist)
                infoProc.exec(["artistinfo", artist])
            else
                clearInfo()
            return
        }
        loadTracksFor(name)
        infoProc.exec(["albuminfo", artist, name])
    }

    function clickAlbum(item, modifiers) {
        if (searching) {
            const artist = item?.artist || ""
            const album = typeof item === "string" ? item : (item?.album || "")
            commitSearchPick({ artist: artist, album: album })
            return
        }
        const name = typeof item === "string" ? item : (item?.album || "")
        if (hasCtrl(modifiers)) {
            const current = view.currentOf(selectedAlbums)
            const artist = view.currentOf(selectedArtists)
            selectedAlbums = toggleKey(selectedAlbums, name)
            selectedTrackFiles = []
            if (selectedAlbums.indexOf(name) >= 0) {
                previewAlbum = ""
                loadTracksFor(name)
                if (artist)
                    infoProc.exec(["albuminfo", artist, name])
            } else if (current === name) {
                const next = view.currentOf(selectedAlbums)
                if (next) {
                    previewAlbum = ""
                    loadTracksFor(next)
                    if (artist)
                        infoProc.exec(["albuminfo", artist, next])
                } else {
                    previewAlbum = albums.length ? albums[0] : ""
                    loadTracksFor(previewAlbum)
                    if (artist)
                        infoProc.exec(["artistinfo", artist])
                }
            }
            return
        }
        selectAlbum(name)
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
            commitSearchPick({
                artist: item.artist || "",
                album: item.album || "",
                file: item.file || ""
            })
            return
        }
        const file = item.file
        if (hasCtrl(modifiers)) {
            const current = view.currentOf(selectedTrackFiles)
            selectedTrackFiles = toggleKey(selectedTrackFiles, file)
            if (selectedTrackFiles.indexOf(file) >= 0) {
                infoProc.exec(["songinfo", file])
            } else if (current === file) {
                const next = view.currentOf(selectedTrackFiles)
                const album = view.currentOf(selectedAlbums)
                const artist = view.currentOf(selectedArtists)
                if (next)
                    infoProc.exec(["songinfo", next])
                else if (album && artist)
                    infoProc.exec(["albuminfo", artist, album])
                else if (artist)
                    infoProc.exec(["artistinfo", artist])
            }
            return
        }
        selectTrack(item)
    }

    function playTrack(item) {
        if (!item || !item.file)
            return
        if (searching) {
            commitSearchPick({
                artist: item.artist || "",
                album: item.album || "",
                file: item.file || ""
            })
            playProc.exec(["playfile", item.file])
            return
        }
        selectTrack(item)
        playProc.exec(["playfile", item.file])
    }

    function playAlbum(item) {
        if (searching) {
            const artist = item?.artist || ""
            const album = typeof item === "string" ? item : (item?.album || "")
            if (!artist || !album)
                return
            commitSearchPick({ artist: artist, album: album })
            playProc.exec(["playalbum", artist, album])
            return
        }
        const name = typeof item === "string" ? item : (item?.album || "")
        const artist = view.currentOf(selectedArtists)
        if (!name || !artist)
            return
        selectAlbum(name)
        playProc.exec(["playalbum", artist, name])
    }


    function playArtist(item) {
        if (searching) {
            const artist = item || ""
            if (!artist)
                return
            commitSearchPick({ artist: artist })
            playProc.exec(["playartist", artist])
            return
        }
        const name = typeof item === "string" ? item : (item || "")
        if (!name)
            return
        selectArtist(name)
        playProc.exec(["playartist", name])
    }

    function reloadCurrent() {
        if (searching)
            return
        const artist = view.currentOf(selectedArtists)
        const album = view.currentOf(selectedAlbums)
        const track = view.currentOf(selectedTrackFiles)
        if (artist) {
            loadingAlbums = true
            albumsProc.exec(["albums", artist])
            if (albumForTracks)
                loadTracksFor(albumForTracks)
            if (track)
                infoProc.exec(["songinfo", track])
            else if (album)
                infoProc.exec(["albuminfo", artist, album])
            else
                infoProc.exec(["artistinfo", artist])
        } else {
            refreshArtists()
        }
    }

    function openTrackContextMenu(item, x, y) {
        if (!item || !item.file || !view.contextMenu)
            return
        const file = item.file
        if (selectedTrackFiles.indexOf(file) < 0)
            selectTrack(item)
        pendingMenuKind = "track"
        pendingMenuTrackFiles = selectedTrackFiles.slice()
        pendingMenuAlbums = []
        pendingMenuArtists = []
        pendingMenuX = x
        pendingMenuY = y
        playlistsMenuProc.exec(["playlists"])
    }

    function openAlbumContextMenu(album, x, y) {
        if (!album || !view.currentOf(view.selectedArtists) || !view.contextMenu)
            return
        if (selectedAlbums.indexOf(album) < 0)
            selectAlbum(album)
        pendingMenuKind = "album"
        pendingMenuAlbums = selectedAlbums.slice()
        pendingMenuArtists = []
        pendingMenuTrackFiles = []
        pendingMenuX = x
        pendingMenuY = y
        playlistsMenuProc.exec(["playlists"])
    }

    function openArtistContextMenu(artist, x, y) {
        if (!artist || !view.contextMenu)
            return
        if (selectedArtists.indexOf(artist) < 0)
            selectArtist(artist)
        pendingMenuKind = "artist"
        pendingMenuArtists = selectedArtists.slice()
        pendingMenuAlbums = []
        pendingMenuTrackFiles = []
        pendingMenuX = x
        pendingMenuY = y
        playlistsMenuProc.exec(["playlists"])
    }

    function showTrackContextMenu(playlists) {
        if (pendingMenuKind === "album") {
            showAlbumContextMenu(playlists)
            return
        }
        if (pendingMenuKind === "artist") {
            showArtistContextMenu(playlists)
            return
        }
        const files = pendingMenuTrackFiles.length
            ? pendingMenuTrackFiles.slice()
            : (currentOf(pendingMenuTrackFiles) ? [currentOf(pendingMenuTrackFiles)] : [])
        if (!files.length || !view.contextMenu)
            return
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

        view.contextMenu.openAt(view.pendingMenuX, view.pendingMenuY, [
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
            },
            { separator: true },
            {
                text: "delete",
                action: () => actionProc.exec(["songdeletemany"].concat(files))
            }
        ], { files: files })
    }

    function showAlbumContextMenu(playlists) {
        const albums = pendingMenuAlbums.length
            ? pendingMenuAlbums.slice()
            : (currentOf(pendingMenuAlbums) ? [currentOf(pendingMenuAlbums)] : [])
        const artist = view.currentOf(view.selectedArtists)
        if (!albums.length || !artist || !view.contextMenu)
            return
        const names = Array.isArray(playlists) ? playlists : []
        const playlistChildren = names.map((name) => ({
            text: name,
            action: () => actionProc.exec(
                ["playlistaddalbummany", name, artist].concat(albums))
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
                    actionProc.exec(
                        ["playlistaddalbummany", name, artist].concat(albums))
                })
            }
        })

        view.contextMenu.openAt(view.pendingMenuX, view.pendingMenuY, [
            {
                text: "add to queue",
                submenu: [
                    {
                        text: "after this",
                        action: () => actionProc.exec(
                            ["queueaddalbummany", artist, "next"].concat(albums))
                    },
                    {
                        text: "to end",
                        action: () => actionProc.exec(
                            ["queueaddalbummany", artist, "end"].concat(albums))
                    }
                ]
            },
            {
                text: "add to playlist",
                submenu: playlistChildren
            },
            { separator: true },
            {
                text: "delete",
                action: () => actionProc.exec(
                    ["albumdeletemany", artist].concat(albums))
            }
        ], { artist: artist, albums: albums })
    }

    function showArtistContextMenu(playlists) {
        const artists = pendingMenuArtists.length
            ? pendingMenuArtists.slice()
            : (currentOf(pendingMenuArtists) ? [currentOf(pendingMenuArtists)] : [])
        if (!artists.length || !view.contextMenu)
            return
        const names = Array.isArray(playlists) ? playlists : []
        const playlistChildren = names.map((name) => ({
            text: name,
            action: () => actionProc.exec(
                ["playlistaddartistmany", name].concat(artists))
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
                    actionProc.exec(
                        ["playlistaddartistmany", name].concat(artists))
                })
            }
        })

        view.contextMenu.openAt(view.pendingMenuX, view.pendingMenuY, [
            {
                text: "add to queue",
                submenu: [
                    {
                        text: "after this",
                        action: () => actionProc.exec(
                            ["queueaddartistmany", "next"].concat(artists))
                    },
                    {
                        text: "to end",
                        action: () => actionProc.exec(
                            ["queueaddartistmany", "end"].concat(artists))
                    }
                ]
            },
            {
                text: "add to playlist",
                submenu: playlistChildren
            },
            { separator: true },
            {
                text: "delete",
                action: () => actionProc.exec(["artistdeletemany"].concat(artists))
            }
        ], { artists: artists })
    }

    Component.onCompleted: refreshArtists()

    ToolProcess {
        id: updateProc
        tag: "mpd-update"
        onResult: (data) => {
            view.refreshingLibrary = false
            if (!data || !data.ok) {
                console.log("[mpd] update:", data?.error || "failed")
                view.loadingArtists = false
                return
            }
            view.refreshArtists()
            view.mutated(data)
        }
    }

    ToolProcess {
        id: artistsProc
        tag: "mpd-artists"
        onResult: (data) => {
            view.loadingArtists = false
            if (!data || !data.ok) {
                console.log("[mpd] artists:", data?.error || "failed")
                view.artists = []
                return
            }
            view.artists = data.artists || []
            if (!view.artists.length) {
                view.selectArtist("")
                return
            }
            // Default: first artist selected so columns stay populated.
            const current = view.currentOf(view.selectedArtists)
            if (!current || view.artists.indexOf(current) < 0)
                view.selectArtist(view.artists[0])
            else
                view.reloadCurrent()
        }
    }

    ToolProcess {
        id: albumsProc
        tag: "mpd-albums"
        onResult: (data) => {
            view.loadingAlbums = false
            if (!data || !data.ok) {
                console.log("[mpd] albums:", data?.error || "failed")
                view.albums = []
                view.previewAlbum = ""
                view.tracks = []
                return
            }
            const artist = view.currentOf(view.selectedArtists)
            if (data.artist !== artist)
                return
            view.albums = data.albums || []
            const album = view.currentOf(view.selectedAlbums)
            if (album) {
                if (view.albums.indexOf(album) < 0) {
                    view.selectedAlbums = []
                    view.previewAlbum = view.albums.length ? view.albums[0] : ""
                    view.loadTracksFor(view.previewAlbum)
                }
                return
            }
            // No album selected: preview first album's tracks without selecting it.
            view.previewAlbum = view.albums.length ? view.albums[0] : ""
            view.loadTracksFor(view.previewAlbum)
        }
    }

    ToolProcess {
        id: tracksProc
        tag: "mpd-tracks"
        onResult: (data) => {
            view.loadingTracks = false
            if (!data || !data.ok) {
                console.log("[mpd] tracks:", data?.error || "failed")
                view.tracks = []
                return
            }
            if (data.artist !== view.currentOf(view.selectedArtists) || data.album !== view.albumForTracks)
                return
            view.tracks = data.tracks || []
        }
    }

    ToolProcess {
        id: infoProc
        tag: "mpd-info"
        onResult: (data) => {
            if (!data || !data.ok) {
                console.log("[mpd] info:", data?.error || "failed")
                return
            }
            const artist = view.currentOf(view.selectedArtists)
            const album = view.currentOf(view.selectedAlbums)
            const track = view.currentOf(view.selectedTrackFiles)
            // Ignore stale replies that no longer match selection.
            if (data.mode === "artist" && data.artist !== artist)
                return
            if (data.mode === "album"
                && (data.artist !== artist || data.album !== album || track))
                return
            if (data.mode === "song" && data.file !== track)
                return
            view.setInfo(data)
        }
    }

    ToolProcess {
        id: playProc
        tag: "mpd-play"
        onResult: (data) => {
            if (!data || !data.ok) {
                console.log("[mpd] play:", data?.error || "failed")
                return
            }
            view.mutated({ mutated: "queue" })
        }
    }

    ToolProcess {
        id: playlistsMenuProc
        tag: "mpd-track-menu-playlists"
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
        tag: "mpd-track-action"
        onResult: (data) => {
            if (!data || !data.ok) {
                console.log("[mpd] track action:", data?.error || "failed")
                return
            }
            if (data.deletedFile !== undefined || data.deletedFiles !== undefined) {
                if (data.artists) {
                    view.selectedArtists = []
                    view.selectedAlbums = []
                    view.selectedTrackFiles = []
                    view.albums = []
                    view.tracks = []
                    view.refreshArtists()
                    view.clearInfo()
                } else if (data.albums && data.artist) {
                    view.selectedAlbums = []
                    view.selectedTrackFiles = []
                    if (view.currentOf(view.selectedArtists) === data.artist) {
                        albumsProc.exec(["albums", data.artist])
                        infoProc.exec(["artistinfo", data.artist])
                    }
                } else if (data.files || data.file) {
                    const gone = data.files || (data.file ? [data.file] : [])
                    view.selectedTrackFiles = view.selectedTrackFiles.filter(f => gone.indexOf(f) < 0)
                    const artist = view.currentOf(view.selectedArtists)
                    const album = view.currentOf(view.selectedAlbums)
                    const track = view.currentOf(view.selectedTrackFiles)
                    view.loadTracksFor(view.albumForTracks)
                    if (track)
                        infoProc.exec(["songinfo", track])
                    else if (album && artist)
                        infoProc.exec(["albuminfo", artist, album])
                    else if (artist)
                        infoProc.exec(["artistinfo", artist])
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
            title: "artists"
            model: view.shownArtists
            selectedKeys: view.searching ? [] : view.selectedArtists
            loading: view.searching ? view.searchLoading : view.loadingArtists
            emptyText: view.searching ? "no matches" : "no artists"
            onItemClicked: (item, modifiers) => view.clickArtist(item, modifiers)
            onItemDoubleClicked: (item) => view.playArtist(item)
            onItemRightClicked: (item, x, y) => {
                if (view.searching) {
                    view.commitSearchPick({ artist: item })
                    Qt.callLater(() => view.openArtistContextMenu(item, x, y))
                    return
                }
                view.openArtistContextMenu(item, x, y)
            }
        }

        ColumnList {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            menuTarget: view.contextMenu || view
            title: "albums"
            model: view.shownAlbums
            selectedKeys: view.searching ? [] : view.selectedAlbums
            loading: view.searching ? view.searchLoading : view.loadingAlbums
            emptyText: view.searching
                ? "no matches"
                : (view.currentOf(view.selectedArtists) ? "no albums" : "no artists")
            keyOf: (item) => {
                if (item && typeof item === "object")
                    return (item.artist || "") + "\n" + (item.album || "")
                return String(item ?? "")
            }
            labelOf: (item) => {
                if (item && typeof item === "object") {
                    if (item.artist && item.album)
                        return item.album + " — " + item.artist
                    return item.album || item.artist || ""
                }
                return String(item ?? "")
            }
            onItemClicked: (item, modifiers) => view.clickAlbum(item, modifiers)
            onItemDoubleClicked: (item) => view.playAlbum(item)
            onItemRightClicked: (item, x, y) => {
                if (view.searching) {
                    const artist = item?.artist || ""
                    const album = typeof item === "string" ? item : (item?.album || "")
                    view.commitSearchPick({ artist: artist, album: album })
                    Qt.callLater(() => view.openAlbumContextMenu(album, x, y))
                    return
                }
                view.openAlbumContextMenu(item, x, y)
            }
        }

        ColumnList {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            menuTarget: view.contextMenu || view
            title: "tracks"
            model: view.shownTracks
            selectedKeys: view.searching ? [] : view.selectedTrackFiles
            loading: view.searching ? view.searchLoading : view.loadingTracks
            emptyText: view.searching
                ? "no matches"
                : (view.albumForTracks ? "no tracks" : (view.currentOf(view.selectedArtists) ? "no albums" : "no artists"))
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
            onItemDoubleClicked: (item) => view.playTrack(item)
            onItemRightClicked: (item, x, y) => {
                if (view.searching) {
                    view.commitSearchPick({
                        artist: item?.artist || "",
                        album: item?.album || "",
                        file: item?.file || ""
                    })
                    Qt.callLater(() => view.openTrackContextMenu(item, x, y))
                    return
                }
                view.openTrackContextMenu(item, x, y)
            }
        }
    }
}
