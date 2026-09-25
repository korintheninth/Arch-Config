import Quickshell
import QtQuick
import "../themes"
import "../apps/wallpaper"
import "../apps/mpd"

Scope {
    Connections {
        target: Quickshell

        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup()
        }

        function onReloadFailed(error) {
            Quickshell.inhibitReloadPopup()
            console.error("Config Error: " + error)
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: topbar
                required property var modelData
                screen: modelData

                anchors.top: true
                anchors.left: true
                anchors.right: true
                color: Styles.topbar.color
                implicitHeight: Styles.topbar.implicitHeight
                margins.top: Styles.topbar.margins.top
                margins.left: Styles.topbar.margins.left
                margins.right: Styles.topbar.margins.right
                margins.bottom: Styles.topbar.margins.bottom
                property alias background: bg

                Rectangle {
                    id: bg
                    anchors.fill: parent
                    color: Styles.topbar.background.color
                    border.width: Styles.topbar.background.border.width
                    border.color: Styles.topbar.background.border.color
                }

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    Workspaces { implicitHeight: topbar.height }
                    Systray { barHeight: topbar.height }
                    Media { implicitHeight: topbar.height }
                    spacing: 10
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Clock { implicitHeight: topbar.height }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    Updates { height: topbar.height }
                    Sound { height: topbar.height }
                    Battery { height: topbar.height }
                    HWState { height: topbar.height - 4 }
                }
            }
        }
    }

    GalleryWindow {}
    MpdWindow {}
}
