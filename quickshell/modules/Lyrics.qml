import QtQuick
import "../components"
import "../services"

Item {
    id: lyrics
    clip: true

    property var activeLyrics: ["", "", "", ""]
    property string _shownKey: ""
    property real position: 0
    property int spacing: 5
    property int padding: 0
    property color inactiveColor: "transparent"
    property alias background: lyricsBg
    property alias lr1: lr1
    property alias lr2: lr2
    property alias lr3: lr3
    property alias lr4: lr4

    function nextNonEmpty(lines, from, dir) {
        var i = from
        while (i >= 0 && i < lines.length) {
            if (String(lines[i].lyric ?? "").trim())
                return { i: i, lyric: lines[i].lyric }
            i += dir
        }
        return null
    }

    function populateLyrics() {
        var key = LyricsService.trackKey
        var lines = key ? LyricsService.lyricsMap[key] : null
        if (!lines || lines.length <= 0) {
            // Real track change: clear once. Transient cache misses keep the last lines.
            if (key && key !== _shownKey)
                activeLyrics = ["", "", "", ""]
            return
        }
        _shownKey = key
        var after = 0
        while (after < lines.length && lines[after].timestamp <= position + 0.15)
            after += 1
        var current = nextNonEmpty(lines, after - 1, -1)
        var prev = current ? nextNonEmpty(lines, current.i - 1, -1) : null
        var n1 = nextNonEmpty(lines, after, 1)
        var n2 = n1 ? nextNonEmpty(lines, n1.i + 1, 1) : null
        activeLyrics = [
            prev ? prev.lyric : "",
            current ? current.lyric : "",
            n1 ? n1.lyric : "",
            n2 ? n2.lyric : ""
        ]
    }

    Rectangle {
        id: lyricsBg
        anchors.fill: parent
        z: -1
        color: "transparent"
        radius: 0
        visible: true
        border.width: 0
        border.color: "transparent"
    }

    BetterText {
        id: lr2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -parent.height * 0.125
        width: parent.width - lyrics.padding * 2
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        text: lyrics.activeLyrics[1]
    }
    BetterText {
        id: lr1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: lr2.top
        anchors.bottomMargin: lyrics.spacing
        width: parent.width - lyrics.padding * 2
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        color: lyrics.inactiveColor
        text: lyrics.activeLyrics[0]
    }
    BetterText {
        id: lr3
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: lr2.bottom
        anchors.topMargin: lyrics.spacing
        width: parent.width - lyrics.padding * 2
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        color: lyrics.inactiveColor
        text: lyrics.activeLyrics[2]
    }
    BetterText {
        id: lr4
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: lr3.bottom
        anchors.topMargin: lyrics.spacing
        width: parent.width - lyrics.padding * 2
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: lyrics.inactiveColor
        text: lyrics.activeLyrics[3]
    }
}
