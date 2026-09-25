import QtQuick
import QtQuick.Controls
import "../../components"
import "../../themes"

Item {
    id: col

    property string title: ""
    property var model: []
    property var selectedKeys: []
    property bool loading: false
    property string emptyText: ""
    property var labelOf: (item) => String(item ?? "")
    property var keyOf: (item) => String(item ?? "")
    // Item whose coordinate space right-click positions are mapped into.
    property var menuTarget: null

    signal itemClicked(var item, int modifiers)
    signal itemDoubleClicked(var item)
    signal itemRightClicked(var item, real x, real y)

    readonly property var contentStyle: Styles.mpdClient.content
    readonly property var ls: contentStyle.list

    Rectangle {
        anchors.fill: parent
        color: col.ls.column.color
        radius: col.ls.column.radius
        border.width: col.ls.column.border.width
        border.color: col.ls.column.border.color
        clip: radius > 0
    }

    BetterText {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: col.contentStyle.padding
        anchors.leftMargin: col.contentStyle.padding
        anchors.rightMargin: col.contentStyle.padding
        height: col.ls.headerHeight
        verticalAlignment: Text.AlignVCenter
        text: col.title
        color: col.ls.header.color
        font.family: col.ls.header.font.family
        font.pixelSize: col.ls.header.font.pixelSize
        font.bold: col.ls.header.font.bold
    }

    ListView {
        id: list
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: col.contentStyle.padding
        anchors.rightMargin: col.contentStyle.padding
        anchors.bottomMargin: col.contentStyle.padding
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: col.ls.spacing
        model: col.model

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index

            readonly property string label: col.labelOf(modelData)
            readonly property string key: col.keyOf(modelData)
            readonly property bool isSelected: {
                const keys = col.selectedKeys
                return Array.isArray(keys) && keys.indexOf(row.key) >= 0
            }

            width: ListView.view.width
            height: col.ls.item.height
            radius: col.ls.item.radius
            color: {
                if (row.isSelected)
                    return col.ls.item.selectedColor
                if (mouse.containsMouse)
                    return col.ls.item.hoverColor
                return col.ls.item.normalColor
            }
            border.width: col.ls.item.border.width
            border.color: col.ls.item.border.color

            BetterText {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: col.ls.item.padding
                anchors.rightMargin: col.ls.item.padding
                text: row.label
                elide: Text.ElideRight
                color: row.isSelected ? col.ls.item.text.selectedColor : col.ls.item.text.color
                font.family: col.ls.item.text.font.family
                font.pixelSize: col.ls.item.text.font.pixelSize
                font.bold: col.ls.item.text.font.bold
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouseEvent) => {
                    if (mouseEvent.button === Qt.RightButton) {
                        const target = col.menuTarget || col
                        const p = row.mapToItem(target, mouseEvent.x, mouseEvent.y)
                        col.itemRightClicked(row.modelData, p.x, p.y)
                    } else {
                        col.itemClicked(row.modelData, mouseEvent.modifiers)
                    }
                }
                onDoubleClicked: (mouseEvent) => {
                    if (mouseEvent.button === Qt.LeftButton)
                        col.itemDoubleClicked(row.modelData)
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            id: vbar
            policy: list.contentHeight > list.height
                ? ScrollBar.AsNeeded
                : ScrollBar.AlwaysOff
            visible: list.contentHeight > list.height
            contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: Styles.fgBase
                opacity: vbar.policy === ScrollBar.AlwaysOff ? 0 : 1
            }
        }
    }

    BetterText {
        anchors.centerIn: list
        visible: !col.loading && col.model.length === 0
        text: col.emptyText
        color: col.ls.muted.color
        font.family: col.ls.muted.font.family
        font.pixelSize: col.ls.muted.font.pixelSize
    }

    BetterText {
        anchors.centerIn: list
        visible: col.loading
        text: "loading..."
        color: col.ls.muted.color
        font.family: col.ls.muted.font.family
        font.pixelSize: col.ls.muted.font.pixelSize
    }
}
