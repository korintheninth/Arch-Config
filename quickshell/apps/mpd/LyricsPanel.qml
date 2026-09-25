import QtQuick
import QtQuick.Controls
import "../../components"
import "../../themes"
import "../../services"

Item {
    id: panel

    readonly property var s: Styles.mpdClient.lyricsPanel
    property bool open: false
    property var lines: []
    property int currentIndex: -1
    property string _shownKey: ""
    property bool userScrolled: false
    property bool _programmaticScroll: false

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

    // Same access pattern as Lyrics.qml / PlayerBar: read lyricsMap on demand.
    function refreshLyrics() {
        const key = LyricsService.trackKey
        const all = key ? LyricsService.lyricsMap[key] : null
        if (!all || all.length <= 0) {
            if (key && key !== _shownKey) {
                lines = []
                currentIndex = -1
                _shownKey = key
                userScrolled = false
            }
            return
        }
        if (key !== _shownKey)
            userScrolled = false
        _shownKey = key

        const out = []
        for (let i = 0; i < all.length; i++) {
            const row = all[i]
            if (String(row?.lyric ?? "").trim().length)
                out.push(row)
        }
        lines = out

        const position = PlayerService.position
        let after = 0
        while (after < out.length && out[after].timestamp <= position + 0.15)
            after += 1
        currentIndex = after - 1
    }

    function seekTo(ts) {
        if (ts == null || !isFinite(ts) || ts < 0)
            return
        PlayerService.seek(ts)
    }

    // Height animates open; ListView viewport is wrong until that finishes.
    readonly property bool layoutReady: open && height >= (s.height - 1) && list.height > 0

    function scrollToCurrent() {
        if (!open || currentIndex < 0 || userScrolled || !layoutReady)
            return
        if (list.count <= 0 || currentIndex >= list.count)
            return
        _programmaticScroll = true
        list.positionViewAtIndex(currentIndex, ListView.Center)
        Qt.callLater(() => {
            if (panel.open && !panel.userScrolled && panel.currentIndex >= 0
                && panel.currentIndex < list.count)
                list.positionViewAtIndex(panel.currentIndex, ListView.Center)
            panel._programmaticScroll = false
        })
    }

    onOpenChanged: {
        if (!open)
            return
        userScrolled = false
        refreshLyrics()
    }

    onLayoutReadyChanged: {
        if (layoutReady && !userScrolled)
            Qt.callLater(scrollToCurrent)
    }

    onCurrentIndexChanged: {
        if (open && currentIndex >= 0 && !userScrolled && layoutReady)
            scrollToCurrent()
    }

    Connections {
        target: PlayerService
        function onTick() {
            if (panel.open)
                panel.refreshLyrics()
        }
        function onPositionChanged() {
            if (panel.open)
                panel.refreshLyrics()
        }
        function onTrackTitleChanged() {
            if (panel.open)
                panel.refreshLyrics()
        }
        function onTrackArtistChanged() {
            if (panel.open)
                panel.refreshLyrics()
        }
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
        anchors.right: parent.right
        anchors.topMargin: panel.s.padding
        anchors.leftMargin: panel.s.padding
        anchors.rightMargin: panel.s.padding
        height: panel.s.headerHeight
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: "lyrics"
        color: panel.s.header.color
        font.family: panel.s.header.font.family
        font.pixelSize: panel.s.header.font.pixelSize
        font.bold: panel.s.header.font.bold
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
        model: panel.lines

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

            readonly property bool isCurrent: row.index === panel.currentIndex
            readonly property string lyric: String(modelData?.lyric ?? "").trim()

            width: ListView.view.width
            height: Math.max(panel.s.item.height, label.implicitHeight + panel.s.item.padding)
            radius: panel.s.item.radius
            color: {
                if (row.isCurrent)
                    return panel.s.item.currentColor
                if (mouse.containsMouse)
                    return panel.s.item.hoverColor
                return panel.s.item.normalColor
            }

            BetterText {
                id: label
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: panel.s.item.padding
                anchors.rightMargin: panel.s.item.padding
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: row.isCurrent
                    ? panel.s.item.text.activeColor
                    : panel.s.item.text.color
                font.family: panel.s.item.text.font.family
                font.pixelSize: panel.s.item.text.font.pixelSize
                font.bold: row.isCurrent
                    ? (panel.s.item.text.activeBold ?? panel.s.item.text.font.bold)
                    : panel.s.item.text.font.bold
                text: row.lyric
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.seekTo(row.modelData?.timestamp)
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
        visible: panel.open && panel.lines.length === 0
        text: "no lyrics"
        color: panel.s.item.text.color
        font.family: panel.s.item.text.font.family
        font.pixelSize: panel.s.item.text.font.pixelSize
        opacity: 0.55
    }
}
