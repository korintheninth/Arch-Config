import QtQuick
import "../themes"
import "../components"
import "../services"

Rectangle {
    id: media
    anchors.verticalCenter: parent.verticalCenter
    color: Styles.media.color
    radius: Styles.media.radius

    property alias text: label
    property int titleMaxLength: Styles.media.titleMaxLength
    property int artistMaxLength: Styles.media.artistMaxLength
    property int albumMaxLength: Styles.media.albumMaxLength

    function truncate(str, max) {
        if (!str || max <= 0) return str ?? ""
        return str.length > max ? str.slice(0, max - 1) + "…" : str
    }

    MediaMenu {
        id: menu
    }

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        spacing: Styles.media.oscilloscope.anchors.leftMargin

        BetterText {
            id: label
            color: Styles.media.text.color
            font.family: Styles.media.text.font.family
            font.bold: Styles.media.text.font.bold
            text: PlayerService.active
                ? media.truncate(PlayerService.trackTitle || "", media.titleMaxLength)
                    + " - " + media.truncate(PlayerService.trackArtist || "", media.artistMaxLength)
                    + " - " + media.truncate(PlayerService.trackAlbum || "", media.albumMaxLength)
                    + " " + PlayerService.playTime
                : "No Music"
        }

        Item {
            id: scopeSlot
            visible: PlayerService.active
            width: scope.displayWidth
            height: scope.displayHeight

            Oscilloscope {
                id: scope
                anchors.fill: parent
                displayWidth: Styles.media.oscilloscope.width
                displayHeight: Styles.media.oscilloscope.height
                lineWidth: Styles.media.oscilloscope.lineWidth
                traceColor: Styles.media.oscilloscope.color
                backgroundColor: Styles.media.oscilloscope.background
                visible: PlayerService.isPlaying
                running: PlayerService.isPlaying
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: {
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                PlayerService.togglePlayPause()
            } else if (mouse.button === Qt.RightButton) {
                menu.anchorTarget = media
                menu.open = true
            }
        }
        onWheel: (wheel) => {
            if (!PlayerService.active) return
            if (wheel.angleDelta.y > 0)
                PlayerService.next()
            else if (wheel.angleDelta.y < 0)
                PlayerService.previous()
        }
    }

    implicitWidth: content.implicitWidth + 20
}
