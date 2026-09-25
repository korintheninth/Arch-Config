import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../themes"

PopupWindow {
    id: mediaMenu

    color: "transparent"
    property int menuWidth: Styles.mediaMenu.menuWidth
    property int menuHeight: Styles.mediaMenu.menuHeight

    implicitWidth: menuWidth
    implicitHeight: menuHeight

    property bool open: false

    HyprlandFocusGrab {
        active: mediaMenu.open
        windows: [mediaMenu]
        onCleared: mediaMenu.open = false
    }

    onVisibleChanged: {
        if (!visible)
            open = false
    }

    property Item anchorTarget: null
    anchor.item: anchorTarget
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 20
    anchor.margins.right: 5
    onOpenChanged: {
        if (open) {
            visible = true
            anchor.updateAnchor()
        }
    }

    Item {
        id: content
        width: mediaMenu.menuWidth
        height: mediaMenu.menuHeight
        anchors.centerIn: parent

        transform: Translate {
            id: slideTransform
            y: -content.height
        }

        NumberAnimation {
            id: openAnim
            target: slideTransform
            property: "y"
            from: -content.height
            to: 0
            duration: 300
            easing.type: Easing.OutQuart

            onFinished: {
                if (!mediaMenu.open)
                    mediaMenu.visible = false
            }
        }

        Connections {
            target: mediaMenu
            function onOpenChanged() {
                if (mediaMenu.open) {
                    slideTransform.y = -content.height
                    openAnim.from = -content.height
                    openAnim.to = 0
                    openAnim.start()
                } else {
                    openAnim.from = slideTransform.y
                    openAnim.to = -content.height
                    openAnim.start()
                }
            }
        }

        MediaPlayer {
            anchors.fill: parent
        }
    }
}
