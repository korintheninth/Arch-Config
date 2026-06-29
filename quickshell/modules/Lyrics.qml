import QtQuick
import "../components"
import "../services"

Column {
    id: lyrics

    property var activeLyrics: ["", "", "", ""]
    property real position: 0

    property alias lr1: lr1
    property alias lr2: lr2
    property alias lr3: lr3
    property alias lr4: lr4

    function populateLyrics() {
        if (LyricsService.activeLyrics.length <= 0) {
            activeLyrics = ["", "", "", ""]
            return
        }
        var lyricIndex = 0
        while (LyricsService.activeLyrics[lyricIndex].timestamp < position && lyricIndex < LyricsService.activeLyrics.length) lyricIndex += 1
        activeLyrics = [
            lyricIndex < 2 ? "" : LyricsService.activeLyrics[lyricIndex - 2].lyric,
            lyricIndex < 1 ? "" : LyricsService.activeLyrics[lyricIndex - 1].lyric,
            lyricIndex >= LyricsService.activeLyrics.length ? "" : LyricsService.activeLyrics[lyricIndex].lyric,
            lyricIndex + 1 >= LyricsService.activeLyrics.length ? "" : LyricsService.activeLyrics[lyricIndex + 1].lyric
            ]
    }

    BetterText {
        id: lr1
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        text: lyrics.activeLyrics[0]
    }
    BetterText {
        id: lr2
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        text: lyrics.activeLyrics[1]
    }
    BetterText {
        id: lr3
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        text: lyrics.activeLyrics[2]
    }
    BetterText {
        id: lr4
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: lyrics.activeLyrics[3]
    }
}
