import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../themes"
import "../../services"
import "../../components"

PanelWindow {
    id: win

    color: "transparent"
    visible: open
    implicitWidth: screen ? screen.width : Styles.mpdClient.windowWidth
    implicitHeight: Styles.mpdClient.windowHeight
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "mpui"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: Styles.topbar.implicitHeight + 8

    property bool open: false
    property bool grabReady: false

    function focusedQuickshellScreen() {
        return Quickshell.screens.find(
            s => s.name === Hyprland.focusedMonitor?.name
        ) ?? Quickshell.screens[0]
    }

    function pinScreen() {
        const next = focusedQuickshellScreen()
        if (next)
            screen = next
    }

    Component.onCompleted: pinScreen()

    HyprlandFocusGrab {
        active: win.open && win.visible && win.grabReady
        windows: [win]
        onCleared: {
            win.open = false
            MpuiService.open = false
        }
    }

    Connections {
        target: MpuiService
        function onOpenChanged() {
            if (MpuiService.open) {
                win.pinScreen()
                win.open = true
            } else {
                win.open = false
            }
        }
    }

    onVisibleChanged: {
        if (!visible)
            win.open = false
    }

    onOpenChanged: {
        if (!win.open) {
            win.grabReady = false
            if (MpuiService.open)
                MpuiService.open = false
            return
        }
        win.pinScreen()
        if (!MpuiService.open)
            MpuiService.open = true
        win.grabReady = false
        grabDelay.restart()
    }

    Timer {
        id: grabDelay
        interval: 120
        onTriggered: {
            if (win.open && win.visible)
                win.grabReady = true
        }
    }

    Shortcut {
        sequences: ["Escape"]
        enabled: win.open
        onActivated: {
            if (root.prompt.open)
                root.prompt.cancel()
            else if (root.contextMenu.open)
                root.contextMenu.close()
            else
                win.open = false
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: win.open = false
    }

    Rectangle {
        id: root
        width: Math.min(Styles.mpdClient.windowWidth, win.width - 16)
        height: win.height
        anchors.horizontalCenter: parent.horizontalCenter
        color: Styles.mpdClient.background.color
        radius: Styles.mpdClient.background.radius
        border.width: Styles.mpdClient.background.border.width
        border.color: Styles.mpdClient.background.border.color
        clip: radius > 0

        readonly property int pad: Styles.mpdClient.padding
        readonly property int gap: Styles.mpdClient.spacing

        property string page: "tracks"
        property alias contextMenu: contextMenu
        property alias prompt: textPrompt

        function promptNewPlaylist(onAccept) {
            textPrompt.openPrompt({
                title: "new playlist",
                placeholder: "playlist name"
            })
            textPrompt._onAccept = onAccept
        }

        MouseArea {
            // Swallows clicks so they don't reach the close-on-click backdrop.
            anchors.fill: parent
            onClicked: {}
        }

        NavSidebar {
            id: navSidebar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: playerBar.top
            anchors.topMargin: root.pad
            anchors.leftMargin: root.pad
            anchors.bottomMargin: root.gap
            width: Styles.mpdClient.nav.width
            current: root.page
            refreshing: contentArea.refreshingLibrary
            onSelected: (id) => root.page = id
            onRefreshRequested: contentArea.refreshLibrary()
        }

        InfoPanel {
            id: infoPanel
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: playerBar.top
            anchors.topMargin: root.pad
            anchors.rightMargin: root.pad
            anchors.bottomMargin: root.gap
            width: Styles.mpdClient.info.width
            info: contentArea.libraryInfo
        }

        ContentArea {
            id: contentArea
            anchors.top: parent.top
            anchors.left: navSidebar.right
            anchors.right: infoPanel.left
            anchors.bottom: playerBar.top
            anchors.topMargin: root.pad
            anchors.leftMargin: root.gap
            anchors.rightMargin: root.gap
            anchors.bottomMargin: root.gap
            page: root.page
            contextMenu: root.contextMenu
            refreshQueue: () => queuePanel.refresh()
            promptNewPlaylist: (cb) => root.promptNewPlaylist(cb)
        }

        QueuePanel {
            id: queuePanel
            anchors.right: playerBar.right
            anchors.bottom: playerBar.top
            anchors.bottomMargin: root.gap
            width: Math.round(root.width * Styles.mpdClient.queue.widthRatio)
            open: playerBar.queueOpen
            z: 5
        }

        LyricsPanel {
            id: lyricsPanel
            anchors.horizontalCenter: playerBar.horizontalCenter
            anchors.bottom: playerBar.top
            anchors.bottomMargin: root.gap
            width: Math.round(root.width * Styles.mpdClient.lyricsPanel.widthRatio)
            open: playerBar.lyricsOpen
            z: 5
        }

        PlayerBar {
            id: playerBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: root.pad
            anchors.rightMargin: root.pad
            anchors.bottomMargin: root.pad
            height: Styles.mpdClient.playerBar.height
        }

        StyledContextMenu {
            id: contextMenu
            anchors.fill: parent
        }

        TextPrompt {
            id: textPrompt
            anchors.fill: parent
            property var _onAccept: null
            onAccepted: (value) => {
                if (typeof textPrompt._onAccept === "function")
                    textPrompt._onAccept(value)
                textPrompt._onAccept = null
            }
            onCancelled: textPrompt._onAccept = null
        }
    }
}
