import QtQuick
import Quickshell.Services.Mpris
import "../themes"
import "../themes/StyleEngine.js" as Styler
import "../components"

Rectangle {
    id: media
    anchors.verticalCenter: parent.verticalCenter

    property alias text: label
    property int titleMaxLength: 24
    property int artistMaxLength: 16
    property int albumMaxLength: 16
    
    Component.onCompleted: {
        Styler.apply(media, Styles.media)
        Styler.apply(label, Styles.media.text)
    }

    function truncate(str, max) {
        if (!str || max <= 0) return str ?? ""
        return str.length > max ? str.slice(0, max - 1) + "…" : str
    }
    function isRealPlayer(p) {
        const entry = (p?.desktopEntry ?? "").toLowerCase()
        const identity = (p?.identity ?? "").toLowerCase()
        return p && (entry === "spotify"
            || identity.includes("youtube-music")
            || identity.includes("mixtapes"))
    }
    
    property MprisPlayer player: {
        const players = Mpris.players.values
        for (const p of players)
            if (p.isPlaying && isRealPlayer(p)) return p
        for (const p of players)
            if (isRealPlayer(p)) return p
        return null
    }

    function formatTime(seconds) {
        if (seconds == null || seconds < 0 || !isFinite(seconds))
            return "0:00"
        const total = Math.floor(seconds)
        const h = Math.floor(total / 3600)
        const m = Math.floor((total % 3600) / 60)
        const s = total % 60
        const ss = s < 10 ? "0" + s : "" + s
        if (h > 0) {
            const mm = m < 10 ? "0" + m : "" + m
            return h + ":" + mm + ":" + ss
        }
        return m + ":" + ss
    }

    readonly property string playTime: player
        ? "[" + formatTime(player.position) + "/" + formatTime(player.length) + "]"
        : ""

    Timer {
        running: media.player && media.player.isPlaying
        repeat: true
        interval: 1000
        onTriggered: if (media.player) media.player.positionChanged()
    }

    BetterText {
        id: label
        anchors.centerIn: parent
        text: media.player
            ? media.truncate(media.player.trackTitle || "", media.titleMaxLength)
                + " - " + media.truncate(media.player.trackArtist || "", media.artistMaxLength)
                + " - " + media.truncate(media.player.trackAlbum || "", media.albumMaxLength)
                + " " + media.playTime
            : "No Music"
    }

    MediaMenu {
        id: menu
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: {
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                if (media.player.canPause) media.player.pause()
                if (media.player.canPlay) media.player.play()
            } else if (mouse.button === Qt.RightButton) {
                menu.anchorTarget = media
                menu.open = true
            }
        }
        onWheel: (wheel) => {
            if (!media.player) return
            if (wheel.angleDelta.y > 0)
                media.player.next()
            else if (wheel.angleDelta.y < 0)
                media.player.previous()
        }
    }

    Cava {
        height: media.implicitHeight - 2
        anchors.left: label.right
        visible: media.player && media.player.isPlaying
        cavaProcess.running: media.player && media.player.isPlaying
        }

    implicitWidth: label.paintedWidth + 20
}
