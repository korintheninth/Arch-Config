import QtQuick
import QtQuick.Controls
import "../../components"
import "../../themes"
import "../../services"

Item {
    id: panel

    readonly property var s: Styles.mpdClient.queue
    property bool open: false
    property var tracks: []
    property int current: -1
    property bool userScrolled: false
    property bool _programmaticScroll: false
    readonly property bool layoutReady: open && height >= (s.height - 1) && list.height > 0

    visible: height > 0
    opacity: open ? 1 : 0
    height: open ? s.height : 0
    clip: true

    Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
    }
    Behavior on height {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    function applyQueue(data) {
        if (!data || !data.ok) {
            console.log("[mpd] queue:", data?.error || "failed")
            panel.tracks = []
            panel.current = -1
            return
        }
        panel.tracks = data.tracks || []
        panel.current = data.current ?? -1
        if (panel.open && !panel.userScrolled)
            Qt.callLater(panel.scrollToCurrent)
    }

    function refresh() {
        queueProc.exec(["queue"])
    }

    function playAt(pos) {
        actionProc.exec(["queueplay", String(pos)])
    }

    function removeId(songId) {
        actionProc.exec(["queuedel", String(songId)])
    }

    function clearQueue() {
        actionProc.exec(["queueclear"])
    }

    function scrollToCurrent() {
        if (!open || current < 0 || userScrolled || !layoutReady)
            return
        if (list.count <= 0 || current >= list.count)
            return
        _programmaticScroll = true
        list.positionViewAtIndex(current, ListView.Center)
        Qt.callLater(() => {
            if (panel.open && !panel.userScrolled && panel.current >= 0
                && panel.current < list.count)
                list.positionViewAtIndex(panel.current, ListView.Center)
            panel._programmaticScroll = false
        })
    }

    onOpenChanged: {
        if (!open)
            return
        userScrolled = false
        refresh()
    }

    onLayoutReadyChanged: {
        if (layoutReady && !userScrolled)
            Qt.callLater(scrollToCurrent)
    }

    onCurrentChanged: {
        if (open && current >= 0 && !userScrolled && layoutReady)
            scrollToCurrent()
    }

    Connections {
        target: PlayerService
        function onTrackTitleChanged() {
            if (panel.open)
                panel.refresh()
        }
        function onTrackArtistChanged() {
            if (panel.open)
                panel.refresh()
        }
    }

    ToolProcess {
        id: queueProc
        tag: "mpd-queue"
        onResult: (data) => panel.applyQueue(data)
    }

    ToolProcess {
        id: actionProc
        tag: "mpd-queue-action"
        onResult: (data) => panel.applyQueue(data)
    }

    Rectangle {
        anchors.fill: parent
        color: panel.s.background.color
        radius: panel.s.background.radius
        border.width: panel.s.background.border.width
        border.color: panel.s.background.border.color
        clip: radius > 0
    }

    BetterText {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: clearBtn.left
        anchors.topMargin: panel.s.padding
        anchors.leftMargin: panel.s.padding
        anchors.rightMargin: panel.s.padding
        height: panel.s.headerHeight
        verticalAlignment: Text.AlignVCenter
        text: "queue" + (panel.tracks.length ? " · " + panel.tracks.length : "")
        color: panel.s.header.color
        font.family: panel.s.header.font.family
        font.pixelSize: panel.s.header.font.pixelSize
        font.bold: panel.s.header.font.bold
    }

    Item {
        id: clearBtn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: panel.s.padding + Math.max(0, (panel.s.headerHeight - height) / 2)
        anchors.rightMargin: panel.s.padding
        height: panel.s.clear?.height ?? panel.s.headerHeight
        width: visible
            ? clearLabel.implicitWidth + (panel.s.clear?.padding ?? 8) * 2
            : 0
        visible: panel.tracks.length > 0
        opacity: clearMouse.containsMouse ? 1 : 0.85

        Rectangle {
            anchors.fill: parent
            radius: panel.s.clear?.radius ?? 5
            color: clearMouse.containsMouse
                ? (panel.s.clear?.hoverColor ?? "transparent")
                : "transparent"
        }

        BetterText {
            id: clearLabel
            anchors.centerIn: parent
            text: "clear"
            color: clearMouse.containsMouse
                ? (panel.s.clear?.activeColor ?? panel.s.header.color)
                : (panel.s.clear?.color ?? panel.s.header.color)
            font.family: panel.s.clear?.font?.family ?? panel.s.header.font.family
            font.pixelSize: panel.s.clear?.font?.pixelSize ?? panel.s.header.font.pixelSize
        }

        MouseArea {
            id: clearMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: panel.clearQueue()
        }
    }

    ListView {
        id: list
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: panel.s.padding
        anchors.rightMargin: panel.s.padding
        anchors.bottomMargin: panel.s.padding
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: panel.s.spacing
        model: panel.tracks

        onMovementStarted: {
            if (!panel._programmaticScroll)
                panel.userScrolled = true
        }
        onDraggingChanged: {
            if (dragging && !panel._programmaticScroll)
                panel.userScrolled = true
        }

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index

            readonly property bool isCurrent: row.index === panel.current
            readonly property string title: modelData?.title || modelData?.file || ""
            readonly property string artist: modelData?.artist || ""
            readonly property int songId: modelData?.id ?? -1

            width: ListView.view.width
            height: panel.s.item.height
            radius: panel.s.item.radius
            color: {
                if (row.isCurrent)
                    return panel.s.item.currentColor
                if (mouse.containsMouse)
                    return panel.s.item.hoverColor
                return panel.s.item.normalColor
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.playAt(row.index)
            }

            BetterText {
                id: indexLabel
                anchors.left: parent.left
                anchors.leftMargin: panel.s.item.padding
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                z: 1
                text: String(row.index + 1)
                color: row.isCurrent ? panel.s.item.text.currentColor : panel.s.item.muted.color
                font.family: panel.s.item.muted.font.family
                font.pixelSize: panel.s.item.muted.font.pixelSize
            }

            Column {
                id: labels
                anchors.left: indexLabel.right
                anchors.right: removeBtn.left
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                z: 1

                BetterText {
                    width: parent.width
                    text: row.title
                    elide: Text.ElideRight
                    color: row.isCurrent ? panel.s.item.text.currentColor : panel.s.item.text.color
                    font.family: panel.s.item.text.font.family
                    font.pixelSize: panel.s.item.text.font.pixelSize
                    font.bold: panel.s.item.text.font.bold
                }
                BetterText {
                    width: parent.width
                    visible: row.artist.length > 0
                    text: row.artist
                    elide: Text.ElideRight
                    color: panel.s.item.muted.color
                    font.family: panel.s.item.muted.font.family
                    font.pixelSize: panel.s.item.muted.font.pixelSize
                }
            }

            Item {
                id: removeBtn
                anchors.right: parent.right
                anchors.rightMargin: panel.s.item.padding
                anchors.verticalCenter: parent.verticalCenter
                width: panel.s.remove.size
                height: panel.s.remove.size
                z: 2

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: removeMouse.containsMouse
                        ? panel.s.remove.hoverColor
                        : "transparent"
                }

                BetterText {
                    anchors.centerIn: parent
                    text: "×"
                    color: removeMouse.containsMouse
                        ? panel.s.remove.activeColor
                        : panel.s.remove.color
                    font.family: panel.s.remove.font.family
                    font.pixelSize: panel.s.remove.font.pixelSize
                    font.bold: true
                }

                MouseArea {
                    id: removeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        mouse.accepted = true
                        if (row.songId >= 0)
                            panel.removeId(row.songId)
                    }
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
            }
            onPressedChanged: {
                if (pressed)
                    panel.userScrolled = true
            }
            onPositionChanged: {
                if (pressed)
                    panel.userScrolled = true
            }
        }
    }

    BetterText {
        anchors.centerIn: list
        visible: panel.open && panel.tracks.length === 0
        text: "queue empty"
        color: panel.s.item.muted.color
        font.family: panel.s.item.muted.font.family
        font.pixelSize: panel.s.item.muted.font.pixelSize
    }
}
