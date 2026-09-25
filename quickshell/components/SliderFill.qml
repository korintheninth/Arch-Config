import QtQuick

Item {
    id: root

    property color color: "black"
    property real radius: 0
    property int orientation: Qt.Horizontal
    property real position: 0
    property alias fill: fillRect

    readonly property bool vertical: orientation === Qt.Vertical
    readonly property int overlap: 1
    readonly property real capSize: Math.min(Math.max(0, radius), vertical ? width / 2 : height / 2) * 2

    anchors.left: parent ? parent.left : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    width: parent ? (vertical ? parent.width : parent.width * position) : 0
    height: parent ? (vertical ? parent.height * position : parent.height) : 0

    Item {
        id: fillClip
        clip: true
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.vertical ? 0 : -root.overlap
        anchors.bottomMargin: root.vertical ? -root.overlap : 0
        width: {
            if (root.vertical)
                return parent.width
            if (parent.width <= 0)
                return 0
            return Math.max(0, parent.width - root.radius) + root.overlap
        }
        height: {
            if (!root.vertical)
                return parent.height
            if (parent.height <= 0)
                return 0
            return Math.max(0, parent.height - root.radius) + root.overlap
        }

        Rectangle {
            id: fillRect
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: (root.parent ? root.parent.width : 0) + (root.vertical ? 0 : root.overlap)
            height: (root.parent ? root.parent.height : 0) + (root.vertical ? root.overlap : 0)
            radius: root.radius
            color: root.color
        }
    }

    Rectangle {
        id: cap
        visible: root.radius > 0
        radius: root.radius
        color: root.color
        width: root.vertical ? parent.width : Math.min(parent.width, root.capSize)
        height: root.vertical ? Math.min(parent.height, root.capSize) : parent.height
        anchors.left: root.vertical ? parent.left : undefined
        anchors.right: root.vertical ? undefined : parent.right
        anchors.top: root.vertical ? parent.top : undefined
        anchors.bottom: root.vertical ? undefined : parent.bottom
    }
}
