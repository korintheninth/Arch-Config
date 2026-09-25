import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../themes"

Item {
    id: content

    readonly property var s: Styles.mpdClient.content
    property string page: "tracks"
    property var contextMenu: null
    property var refreshQueue: null
    property var promptNewPlaylist: null
    property string searchQuery: ""
    property var searchResults: ({
        artists: [],
        albums: [],
        tracks: [],
        playlists: []
    })
    property bool searchLoading: false

    readonly property var libraryInfo: content.page === "playlists"
        ? playlistsView.libraryInfo
        : tracksView.libraryInfo

    function refreshAfterMutation(data) {
        const kind = data?.mutated || ""
        if (typeof content.refreshQueue === "function")
            content.refreshQueue()

        if (kind === "playlist" || kind === "library" || data?.playlist) {
            playlistsView.refreshPlaylists(data?.playlist || "")
        }

        if (kind === "library" || data?.deletedFile !== undefined) {
            tracksView.reloadCurrent()
            playlistsView.reloadCurrent()
        }

        if (kind === "queue") {
            // queue panel already refreshed above
        }

        if (content.searchQuery.trim().length)
            content.runSearch()
    }

    function refreshLibrary() {
        tracksView.refreshLibrary()
    }

    readonly property bool refreshingLibrary: tracksView.refreshingLibrary

    function runSearch() {
        const q = content.searchQuery.trim()
        if (!q) {
            content.searchLoading = false
            content.searchResults = ({
                artists: [],
                albums: [],
                tracks: [],
                playlists: []
            })
            return
        }
        content.searchLoading = true
        searchProc.exec(["search", q])
    }

    function clearSearch() {
        searchDebounce.stop()
        if (searchField.text !== "")
            searchField.text = ""
        content.searchQuery = ""
        content.searchLoading = false
        content.searchResults = ({
            artists: [],
            albums: [],
            tracks: [],
            playlists: []
        })
    }

    onPageChanged: {
        // Pull fresh data when switching tabs.
        if (page === "playlists")
            playlistsView.refreshPlaylists()
        else if (page === "tracks")
            tracksView.reloadCurrent()
    }

    Rectangle {
        anchors.fill: parent
        color: content.s.background.color
        radius: content.s.background.radius
        border.width: content.s.background.border.width
        border.color: content.s.background.border.color
        clip: radius > 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 1
        spacing: content.s.spacing

        TextField {
            id: searchField
            Layout.fillWidth: true
            Layout.preferredHeight: content.s.search?.height ?? 32
            Layout.leftMargin: content.s.spacing
            Layout.rightMargin: content.s.spacing
            Layout.topMargin: content.s.spacing
            text: content.searchQuery
            placeholderText: "search artists, albums, songs, playlists..."
            color: content.s.search?.color ?? Styles.fgBase
            placeholderTextColor: content.s.search?.placeholderColor
                ?? Qt.rgba(Styles.fgBase.r, Styles.fgBase.g, Styles.fgBase.b, 0.45)
            font.family: content.s.search?.font?.family ?? Styles.fontFamily
            font.pixelSize: content.s.search?.font?.pixelSize ?? Styles.pixelSize
            leftPadding: content.s.search?.padding ?? 10
            rightPadding: content.s.search?.padding ?? 10
            background: Rectangle {
                color: content.s.search?.background?.color
                    ?? Qt.rgba(Styles.fgBase.r, Styles.fgBase.g, Styles.fgBase.b, 0.06)
                radius: content.s.search?.background?.radius ?? 5
                border.width: content.s.search?.background?.border?.width ?? 1
                border.color: content.s.search?.background?.border?.color ?? Styles.fgBase
            }
            onTextChanged: {
                content.searchQuery = text
                searchDebounce.restart()
            }
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape && text.length) {
                    text = ""
                    event.accepted = true
                }
            }
        }

        Timer {
            id: searchDebounce
            interval: 200
            onTriggered: content.runSearch()
        }

        ToolProcess {
            id: searchProc
            tag: "mpd-search"
            onResult: (data) => {
                content.searchLoading = false
                if (!data || !data.ok) {
                    console.log("[mpd] search:", data?.error || "failed")
                    content.searchResults = ({
                        artists: [],
                        albums: [],
                        tracks: [],
                        playlists: []
                    })
                    return
                }
                if ((data.query || "") !== content.searchQuery.trim())
                    return
                content.searchResults = data
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: content.s.spacing
            Layout.rightMargin: content.s.spacing
            Layout.bottomMargin: content.s.spacing

            TracksView {
                id: tracksView
                anchors.fill: parent
                visible: content.page === "tracks"
                contextMenu: content.contextMenu
                refreshQueue: content.refreshQueue
                promptNewPlaylist: content.promptNewPlaylist
                searchQuery: content.searchQuery
                searchResults: content.searchResults
                searchLoading: content.searchLoading
                clearSearch: () => content.clearSearch()
                onMutated: (data) => content.refreshAfterMutation(data)
            }

            PlaylistsView {
                id: playlistsView
                anchors.fill: parent
                visible: content.page === "playlists"
                contextMenu: content.contextMenu
                refreshQueue: content.refreshQueue
                promptNewPlaylist: content.promptNewPlaylist
                searchQuery: content.searchQuery
                searchResults: content.searchResults
                searchLoading: content.searchLoading
                clearSearch: () => content.clearSearch()
                onMutated: (data) => content.refreshAfterMutation(data)
            }
        }
    }
}
