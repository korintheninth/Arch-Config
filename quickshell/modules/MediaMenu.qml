import QtQuick
import QtQuick.Controls
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell
import QtQuick.Effects
import Quickshell.Services.Pipewire
import "../themes"
import "../themes/StyleEngine.js" as Styler
import "../components"
import "../services"

PopupWindow {
    id: mediaMenu

    color: "transparent"
    property int menuWidth: 301
    property int menuHeight: 200
    property int controlsSpacing: 20
    property int controlsBottomOffset: 35
    property color cavaColor: "transparent"

    property alias background: bg

    implicitWidth: menuWidth + 10
    implicitHeight: menuHeight + 10

    property bool open: false

    HyprlandFocusGrab {
        active: mediaMenu.open
        windows: [mediaMenu]
        onCleared: mediaMenu.open = false
    }

    onVisibleChanged: {
        if (!visible)
            open = false
    }

    property Item anchorTarget: null
    anchor.item: anchorTarget
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 20
    anchor.margins.right: 5
    onOpenChanged: {
        if (open) {
            visible = true
            anchor.updateAnchor()
        }
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

    property var outputStreams: []

    property int _nodeCount: Pipewire.nodes.values.length
    property string _playerName: player ? player.dbusName : ""
    
    function updateStreams() {
        const out = []
        
        if (!player) {
            outputStreams = out
            return
        }
        
        for (var n of Pipewire.nodes.values) {
            if (player.dbusName.toLowerCase().includes(n.name.toLowerCase())) {
                out.push(n)
            }
        }
        
        outputStreams = out 
    }
    on_NodeCountChanged: updateStreams()
    on_PlayerNameChanged: updateStreams()
    PwObjectTracker {
        objects: outputStreams
    }

    Component.onCompleted: {
        Styler.apply(mediaMenu, Styles.mediaMenu)
        Styler.apply(coverFrame, Styles.mediaMenu.cover)
        Styler.apply(coverMask, Styles.mediaMenu.cover.mask)
        Styler.apply(menuCava, Styles.mediaMenu.cava)
        Styler.apply(title, Styles.mediaMenu.text)
        Styler.apply(artist, Styles.mediaMenu.text)
        Styler.apply(lyrics.lr1, Styles.mediaMenu.text)
        Styler.apply(lyrics.lr2, Styles.mediaMenu.text)
        Styler.apply(lyrics.lr3, Styles.mediaMenu.text)
        Styler.apply(lyrics.lr4, Styles.mediaMenu.text)
        Styler.apply(lyrics.lr1, { color: Styles.mediaMenu.lyrics.inactiveColor })
        Styler.apply(lyrics.lr3, { color: Styles.mediaMenu.lyrics.inactiveColor })
        Styler.apply(lyrics.lr4, { color: Styles.mediaMenu.lyrics.inactiveColor })
        Styler.apply(volumeSlider, Styles.mediaMenu.slider)
        Styler.apply(volumeSlider, Styles.mediaMenu.volumeSlider)
        Styler.apply(seekSlider, Styles.mediaMenu.slider)
        Styler.apply(seekSlider, Styles.mediaMenu.seekSlider)
        Styler.apply(prevBtn, Styles.mediaMenu.button)
        Styler.apply(playBtn, Styles.mediaMenu.button)
        Styler.apply(nextBtn, Styles.mediaMenu.button)
        Styler.apply(ytmusic, Styles.mediaMenu.ytmusic)
        Styler.apply(lyrics, Styles.mediaMenu.lyrics)
        Styler.apply(lyricsBg, Styles.mediaMenu.lyrics.background)
        updateStreams()
        LyricsService.updateLyrics()
    }

    Rectangle {
        id: content
        color: "transparent"
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -5
        width: parent.width
        height: parent.height

        transform: Rotation {
            id: xAxisRotation
            origin.x: content.width / 2
            axis { x: 1; y: 0; z: 0 } 
            angle: -90 
        }

        NumberAnimation {
            id: openAnim
            target: xAxisRotation
            property: "angle"
            from: -90
            to: 0
            duration: 300
            
            easing.type: Easing.OutBack

            onFinished: {
                if (!mediaMenu.open)
                    mediaMenu.visible = false
            }
        }

        Connections {
            target: mediaMenu
            function onOpenChanged() {
                if (mediaMenu.open) {
                    xAxisRotation.angle = -90
                    openAnim.from = -90
                    openAnim.to = 0
                    openAnim.start()
                } else {
                    openAnim.from = xAxisRotation.angle
                    openAnim.to = -90
                    openAnim.start()
                }
            }
        }
        Rectangle {
            id: bg
            anchors.centerIn: parent
            width: mediaMenu.menuWidth
            height: mediaMenu.menuHeight
        }

        Image {
            id: coverbg
            anchors.centerIn: parent
            width: bg.width - bg.border.width * 2
            height: bg.height - bg.border.width * 2
            visible: mediaMenu.player && mediaMenu.player.trackArtUrl.length > 0
            source: mediaMenu.player ? mediaMenu.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.8
                blurMax: 32
                brightness: -0.4
                autoPaddingEnabled: false
            }
        }

        Cava {
            id: menuCava
            override: true
            anchors.centerIn: bg
            anchors.horizontalCenterOffset: 1

            barWidth: (this.width - Styles.mediaMenu.cava.barCount - 2) / Styles.mediaMenu.cava.barCount
            bars.spacing: 1
            cavaProcess.running: mediaMenu.player && mediaMenu.player.isPlaying
            visible: mediaMenu.player && mediaMenu.player.isPlaying
        }

        Item {
            id: coverFrame
            anchors.left: bg.left
            anchors.top: bg.top
            anchors.leftMargin: 30
            property int coverRadius: 0
            property int coverBorderWidth: 1
            property color coverBorderColor: "transparent"
            visible: mediaMenu.player && mediaMenu.player.trackArtUrl.length > 0
            
            Rectangle {
                id: coverMask
                anchors.fill: parent
                radius: coverFrame.coverRadius
                visible: false
                layer.enabled: true
                layer.smooth: true
            }
            
            Image {
                id: cover
                anchors.fill: parent
                source: mediaMenu.player ? mediaMenu.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: coverMask
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
        Rectangle {
            id: lyricsBg
            anchors.centerIn: bg
            width: lyrics.width
            color: "transparent"
            clip: true
            
            Lyrics {
                id: lyrics
                anchors.centerIn: parent
                width: bg.width - coverFrame.width - coverFrame.anchors.leftMargin - 10
                height: parent.height
                position: seekSlider.value
            }
        }

        Column {
            anchors.bottom: seekSlider.top
            anchors.left: seekSlider.left
            BetterText {
                id: title
                text: player ? truncate(player.trackTitle, 27) : ""
            }
            BetterText {
                id: artist
                text: truncate(player?.trackArtist + " - " + player?.trackAlbum, 27)
            }
        }

        Slider {
            id: volumeSlider
            anchors.left: parent.left
            anchors.top: parent.top
            orientation: Qt.Vertical
            from: 0.0
            to: 1.0
            live: true
            value: mediaMenu.outputStreams[0] ? mediaMenu.outputStreams[0].audio.volume : 0

            property alias bar: volumeBar

            onMoved: {
                for (var n of outputStreams) {
                    n.audio.volume = value
                }
            }

            background: Rectangle {
                x: volumeSlider.leftPadding + volumeSlider.availableWidth / 2 - width / 2
                y: volumeSlider.topPadding

                width: volumeSlider.implicitWidth
                height: volumeSlider.availableHeight
                radius: 0

                Rectangle {
                    id: volumeBar
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * volumeSlider.position
                    radius: 0
                }
            }

            handle: Rectangle {
                implicitWidth: volumeSlider.width
                implicitHeight: 0
                x: 0
                y: volumeSlider.topPadding + volumeSlider.visualPosition * (volumeSlider.availableHeight - height)
            }
        }

        MediaSlider {
            id: seekSlider
            player: mediaMenu.player
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            onTick: lyrics.populateLyrics()
        }

        Row {
            id: mediaButtons
            spacing: mediaMenu.controlsSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.bottom
            anchors.verticalCenterOffset: -mediaMenu.controlsBottomOffset

            MediaMenuButton {
                id: prevBtn
                iconType: "prev"
                enabled: mediaMenu.player !== null
                onClicked: {
                    if (mediaMenu.player)
                        mediaMenu.player.previous()
                }
            }
            MediaMenuButton {
                id: playBtn
                iconType: mediaMenu.player?.isPlaying ? "pause" : "play"
                enabled: mediaMenu.player !== null
                onClicked: {
                    const p = mediaMenu.player
                    if (!p)
                        return
                    if (p.isPlaying && p.canPause)
                        p.pause()
                    else if (p.canPlay)
                        p.play()
                }
            }
            MediaMenuButton {
                id: nextBtn
                iconType: "next"
                enabled: mediaMenu.player !== null
                onClicked: {
                    if (mediaMenu.player)
                        mediaMenu.player.next()
                }
            }
        }
        Button {
            id: ytmusic
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            icon.source: "../icons/ytmusic.svg"
            icon.color: "transparent"
            display: AbstractButton.IconOnly
            onClicked: {
                    Quickshell.execDetached(["pear-desktop"])
            }
        }
    }
}
