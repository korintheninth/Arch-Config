import QtQuick
import "../components"
import "../services"

Item {
    id: lyrics
    clip: true

    property var activeLyrics: ["", "", "", ""]
    property real position: 0
    property int spacing: 5

    property alias lr1: lr1
    property alias lr2: lr2
    property alias lr3: lr3
    property alias lr4: lr4

    function populateLyrics() {
        var key = LyricsService.trackKey
        if (!LyricsService.lyricsMap[key] || LyricsService.lyricsMap[key].length <= 0) {
            activeLyrics = ["", "", "", ""]
            return
        }
        var lyricIndex = 0
        while (lyricIndex < LyricsService.lyricsMap[key].length && LyricsService.lyricsMap[key][lyricIndex].timestamp <= position + 0.15) lyricIndex += 1
        activeLyrics = [
            lyricIndex < 2 ? "" : LyricsService.lyricsMap[key][lyricIndex - 2].lyric,
            lyricIndex < 1 ? "" : LyricsService.lyricsMap[key][lyricIndex - 1].lyric,
            lyricIndex >= LyricsService.lyricsMap[key].length ? "" : LyricsService.lyricsMap[key][lyricIndex].lyric,
            lyricIndex + 1 >= LyricsService.lyricsMap[key].length ? "" : LyricsService.lyricsMap[key][lyricIndex + 1].lyric
            ]
    }

    BetterText {
        id: lr2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -parent.height * 0.125
        width: parent.width
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        text: lyrics.activeLyrics[1]
    }
    BetterText {
        id: lr1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: lr2.top
        anchors.bottomMargin: lyrics.spacing
        width: parent.width
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        text: lyrics.activeLyrics[0]
    }
    BetterText {
        id: lr3
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: lr2.bottom
        anchors.topMargin: lyrics.spacing
        width: parent.width
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        text: lyrics.activeLyrics[2]
    }
    BetterText {
        id: lr4
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: lr3.bottom
        anchors.topMargin: lyrics.spacing
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: lyrics.activeLyrics[3]
    }
}
