import QtQuick
import "../../components"
import "../../themes"

Item {
    id: nav

    readonly property var s: Styles.mpdClient.nav
    property string current: "tracks"
    property bool refreshing: false
    readonly property var items: [
        { id: "tracks", label: "tracks" },
        { id: "playlists", label: "playlists" }
    ]

    signal selected(string id)
    signal refreshRequested()

    Rectangle {
        anchors.fill: parent
        color: nav.s.background.color
        radius: nav.s.background.radius
        border.width: nav.s.background.border.width
        border.color: nav.s.background.border.color
        clip: radius > 0
    }

    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: nav.s.padding
        anchors.leftMargin: nav.s.padding
        anchors.rightMargin: nav.s.padding
        spacing: nav.s.spacing

        BetterText {
            width: parent.width
            height: nav.s.headerHeight ?? 24
            verticalAlignment: Text.AlignVCenter
            text: "navigation"
            color: nav.s.header?.color ?? nav.s.item.text.color
            font.family: nav.s.header?.font?.family ?? nav.s.item.text.font.family
            font.pixelSize: nav.s.header?.font?.pixelSize ?? nav.s.item.text.font.pixelSize
            font.bold: nav.s.header?.font?.bold ?? false
        }

        Repeater {
            model: nav.items

            Rectangle {
                id: item
                required property var modelData
                width: parent.width
                height: nav.s.item.height
                radius: nav.s.item.radius
                color: {
                    if (nav.current === modelData.id)
                        return nav.s.item.selectedColor
                    if (mouse.containsMouse)
                        return nav.s.item.hoverColor
                    return nav.s.item.normalColor
                }
                border.width: nav.s.item.border.width
                border.color: nav.s.item.border.color

                BetterText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: nav.s.item.padding
                    anchors.rightMargin: nav.s.item.padding
                    text: item.modelData.label
                    elide: Text.ElideRight
                    color: nav.current === item.modelData.id
                        ? nav.s.item.text.selectedColor
                        : nav.s.item.text.color
                    font.family: nav.s.item.text.font.family
                    font.pixelSize: nav.s.item.text.font.pixelSize
                    font.bold: nav.s.item.text.font.bold
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        nav.current = item.modelData.id
                        nav.selected(item.modelData.id)
                    }
                }
            }
        }
    }

    Rectangle {
        id: refreshBtn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: nav.s.padding
        anchors.rightMargin: nav.s.padding
        anchors.bottomMargin: nav.s.padding
        height: nav.s.item.height
        radius: nav.s.item.radius
        readonly property real fade: nav.refreshing ? 0.55 : 1
        color: {
            const base = refreshMouse.containsMouse && !nav.refreshing
                ? nav.s.item.hoverColor
                : nav.s.item.normalColor
            return Qt.rgba(base.r, base.g, base.b, base.a * fade)
        }
        border.width: nav.s.item.border.width
        border.color: {
            const base = nav.s.item.border.color
            return Qt.rgba(base.r, base.g, base.b, base.a * fade)
        }

        BetterText {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: nav.s.item.padding
            anchors.rightMargin: nav.s.item.padding
            text: nav.refreshing ? "refreshing..." : "refresh"
            elide: Text.ElideRight
            color: faded(nav.s.item.text.color, parent.fade)
            font.family: nav.s.item.text.font.family
            font.pixelSize: nav.s.item.text.font.pixelSize
            font.bold: nav.s.item.text.font.bold
        }

        MouseArea {
            id: refreshMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !nav.refreshing
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.refreshRequested()
        }
    }
}
