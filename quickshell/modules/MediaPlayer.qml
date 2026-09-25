import QtQuick
import QtQuick.Controls
import Quickshell
import QtQuick.Effects
import "../themes"
import "../components"
import "../services"

Item {
    id: mediaPlayer

    implicitWidth: Styles.mediaMenu.menuWidth
    implicitHeight: Styles.mediaMenu.menuHeight

    property int controlsSpacing: Styles.mediaMenu.controls.spacing
    property int controlsBottomOffset: Styles.mediaMenu.controls.bottomOffset

    property alias background: bg

    function truncate(str, max) {
        if (!str || max <= 0) return str ?? ""
        return str.length > max ? str.slice(0, max - 1) + "…" : str
    }

    Component.onCompleted: LyricsService.updateLyrics()

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Styles.mediaMenu.background.color
        radius: Styles.mediaMenu.background.radius
        border.width: Styles.mediaMenu.background.border.width
        border.color: Styles.mediaMenu.background.border.color
    }

    Rectangle {
        id: bgMask
        anchors.fill: bg
        radius: bg.radius
        color: "white"
        visible: false
        layer.enabled: true
        layer.smooth: true
    }

    Item {
        id: clippedContent
        anchors.fill: bg
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: bgMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        Oscilloscope {
            id: menuScope
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: 1
            width: parent.width + 1
            height: Styles.mediaMenu.oscilloscope.height
            displayWidth: Styles.mediaMenu.oscilloscope.width
            displayHeight: Styles.mediaMenu.oscilloscope.height
            lineWidth: Styles.mediaMenu.oscilloscope.lineWidth
            traceColor: Styles.mediaMenu.oscilloscope.color
            backgroundColor: Styles.mediaMenu.oscilloscope.background
            visible: PlayerService.active
            running: PlayerService.active
        }

        /*
        Cava {
            id: menuCava
            anchors.verticalCenter: undefined
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: 1
            anchors.leftMargin: 0
            width: parent.width + 1
            height: Styles.mediaMenu.cava.height
            barCount: Styles.mediaMenu.cava.barCount
            barColor: Styles.mediaMenu.cava.barColor
            bars.spacing: Styles.mediaMenu.cava.bars.spacing
            bars.anchors.bottomMargin: Styles.mediaMenu.cava.bars.anchors.bottomMargin
            barWidth: (this.width - (barCount - 1) * bars.spacing - 1) / barCount
            visible: PlayerService.active
            running: PlayerService.active
        }
        */
    }

    Item {
        id: coverFrame
        anchors.left: bg.left
        anchors.top: bg.top
        width: Styles.mediaMenu.cover.width
        height: Styles.mediaMenu.cover.height
        anchors.leftMargin: Styles.mediaMenu.cover.anchors.leftMargin
        anchors.topMargin: Styles.mediaMenu.cover.anchors.topMargin
        property int coverRadius: Styles.mediaMenu.cover.radius
        property int coverBorderWidth: Styles.mediaMenu.cover.border.width
        property color coverBorderColor: Styles.mediaMenu.cover.border.color
        visible: PlayerService.active && PlayerService.trackArtUrl.length > 0

        Rectangle {
            id: coverMask
            anchors.fill: parent
            radius: coverFrame.coverRadius
            color: Styles.mediaMenu.cover.mask.color
            visible: false
            layer.enabled: true
            layer.smooth: true
        }

        Image {
            id: cover
            anchors.fill: parent
            source: PlayerService.trackArtUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: coverMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: coverFrame.coverRadius
            color: "transparent"
            border.width: coverFrame.coverBorderWidth
            border.color: coverFrame.coverBorderColor
        }
    }
    Lyrics {
        id: lyrics
        anchors.right: bg.right
        anchors.top: bg.top
        width: bg.width - coverFrame.width - 2 * coverFrame.anchors.leftMargin - 30
        height: Styles.mediaMenu.lyrics.height
        spacing: Styles.mediaMenu.lyrics.spacing
        padding: Styles.mediaMenu.lyrics.padding
        inactiveColor: Styles.mediaMenu.lyrics.inactiveColor
        anchors.topMargin: Styles.mediaMenu.lyrics.anchors.topMargin
        anchors.rightMargin: Styles.mediaMenu.lyrics.anchors.rightMargin
        background.color: Styles.mediaMenu.lyrics.background.color
        background.radius: Styles.mediaMenu.lyrics.background.radius
        background.visible: Styles.mediaMenu.lyrics.background.visible
        background.opacity: Styles.mediaMenu.lyrics.background.opacity
        background.border.width: Styles.mediaMenu.lyrics.background.border.width
        background.border.color: Styles.mediaMenu.lyrics.background.border.color
        lr1.font.family: Styles.mediaMenu.text.font.family
        lr1.font.pixelSize: Styles.mediaMenu.lyrics.font.pixelSize
        lr1.font.bold: Styles.mediaMenu.text.font.bold
        lr2.color: Styles.mediaMenu.lyrics.activeColor
        lr2.font.family: Styles.mediaMenu.text.font.family
        lr2.font.pixelSize: Styles.mediaMenu.lyrics.font.pixelSize
        lr2.font.bold: Styles.mediaMenu.text.font.bold
        lr3.font.family: Styles.mediaMenu.text.font.family
        lr3.font.pixelSize: Styles.mediaMenu.lyrics.font.pixelSize
        lr3.font.bold: Styles.mediaMenu.text.font.bold
        lr4.font.family: Styles.mediaMenu.text.font.family
        lr4.font.pixelSize: Styles.mediaMenu.lyrics.font.pixelSize
        lr4.font.bold: Styles.mediaMenu.text.font.bold
        position: PlayerService.position
    }

    Column {
        anchors.bottom: seekSlider.top
        anchors.left: seekSlider.left
        anchors.bottomMargin: Styles.mediaMenu.text.anchors.bottomMargin
        anchors.leftMargin: Styles.mediaMenu.text.anchors.leftMargin
        BetterText {
            id: title
            color: Styles.mediaMenu.text.color
            font.family: Styles.mediaMenu.text.font.family
            font.pixelSize: Styles.mediaMenu.text.font.pixelSize
            font.bold: Styles.mediaMenu.text.font.bold
            text: PlayerService.active ? mediaPlayer.truncate(PlayerService.trackTitle, 60) : ""
        }
        BetterText {
            id: artist
            color: Styles.mediaMenu.text.color
            font.family: Styles.mediaMenu.text.font.family
            font.pixelSize: Styles.mediaMenu.text.font.pixelSize
            font.bold: Styles.mediaMenu.text.font.bold
            text: mediaPlayer.truncate(PlayerService.trackArtist + " - " + PlayerService.trackAlbum, 60)
        }
    }

    Slider {
        id: volumeSlider
        anchors.left: coverFrame.right
        anchors.top: coverFrame.top
        implicitWidth: Styles.mediaMenu.volumeSlider.implicitWidth
        implicitHeight: Styles.mediaMenu.volumeSlider.implicitHeight
        anchors.leftMargin: Styles.mediaMenu.volumeSlider.anchors.leftMargin
        anchors.topMargin: Styles.mediaMenu.volumeSlider.anchors.topMargin
        orientation: Qt.Vertical
        from: 0.0
        to: 1.0
        live: true

        Binding {
            target: volumeSlider
            property: "value"
            value: PlayerService.volume
            when: !volumeSlider.pressed
        }

        property alias bar: volumeBar

        onMoved: PlayerService.setVolume(value)

        background: Rectangle {
            x: volumeSlider.leftPadding + volumeSlider.availableWidth / 2 - width / 2
            y: volumeSlider.topPadding

            width: volumeSlider.implicitWidth
            height: volumeSlider.availableHeight
            radius: Styles.mediaMenu.slider.radius
            color: Styles.mediaMenu.slider.background.color

            SliderFill {
                id: volumeBar
                orientation: Qt.Vertical
                position: volumeSlider.position
                radius: Styles.mediaMenu.slider.radius
                color: Styles.mediaMenu.slider.bar.color
            }
        }

        handle: Rectangle {
            implicitWidth: volumeSlider.width
            implicitHeight: 0
            color: Styles.mediaMenu.slider.handle.color
            x: 0
            y: volumeSlider.topPadding + volumeSlider.visualPosition * (volumeSlider.availableHeight - height)
        }
    }

    MediaSlider {
        id: seekSlider
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        implicitWidth: bg.width - 40
        implicitHeight: Styles.mediaMenu.seekSlider.implicitHeight
        anchors.bottomMargin: Styles.mediaMenu.seekSlider.anchors.bottomMargin
        trackColor: Styles.mediaMenu.slider.background.color
        fillColor: Styles.mediaMenu.slider.bar.color
        handleColor: Styles.mediaMenu.slider.handle.color
        radius: Styles.mediaMenu.slider.radius
        onTick: lyrics.populateLyrics()
    }

    Row {
        id: mediaButtons
        spacing: mediaPlayer.controlsSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.bottom
        anchors.verticalCenterOffset: -mediaPlayer.controlsBottomOffset

        MediaMenuButton {
            id: prevBtn
            iconType: "prev"
            enabled: PlayerService.active
            onClicked: PlayerService.previous()
        }
        MediaMenuButton {
            id: playBtn
            iconType: PlayerService.isPlaying ? "pause" : "play"
            enabled: PlayerService.active
            onClicked: PlayerService.togglePlayPause()
        }
        MediaMenuButton {
            id: nextBtn
            iconType: "next"
            enabled: PlayerService.active
            onClicked: PlayerService.next()
        }
    }
    Button {
        id: ytmusic
        anchors.bottom: seekSlider.top
        anchors.right: seekSlider.right
        width: Styles.mediaMenu.ytmusic.width
        height: Styles.mediaMenu.ytmusic.height
        anchors.bottomMargin: Styles.mediaMenu.ytmusic.anchors.bottomMargin
        anchors.rightMargin: Styles.mediaMenu.ytmusic.anchors.rightMargin
        icon.width: Styles.mediaMenu.ytmusic.icon.width
        icon.height: Styles.mediaMenu.ytmusic.icon.height
        background.visible: Styles.mediaMenu.ytmusic.background.visible
        icon.source: "../icons/ytmusicblack.svg"
        icon.color: Styles.mediaMenu.ytmusic.icon.color
        display: AbstractButton.IconOnly
        onClicked: {
                Quickshell.execDetached(["pear-desktop"])
        }

    }

    Rectangle {
        id: bgBorder
        anchors.fill: bg
        radius: bg.radius
        color: "transparent"
        border.width: Styles.mediaMenu.background.border.width
        border.color: Styles.mediaMenu.background.border.color
    }
}
