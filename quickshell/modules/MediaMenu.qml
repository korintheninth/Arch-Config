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

PopupWindow {
    id: mediaMenu

    color: "transparent"
    property int menuWidth: 300
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
            || identity.includes("youtube_music"))
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
        if (typeof Styles !== "undefined" && Styles.mediaMenu)
            Styler.apply(mediaMenu, Styles.mediaMenu)
        updateStreams()
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
            color: mediaMenu.background.color
        }

        Image {
            id: coverbg
            anchors.centerIn: parent
            width: mediaMenu.menuWidth - Styles.mediaMenu.background.border.width * 2
            height: mediaMenu.menuHeight - Styles.mediaMenu.background.border.width * 2
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
            override: true
            height: 200
            width: 300
            anchors.centerIn: bg
            bars.anchors.bottomMargin: 0
            barWidth: 5
            bars.spacing: 1
            confPath: "menu.conf"
            barColor: Qt.rgba(mediaMenu.cavaColor.r, mediaMenu.cavaColor.g, mediaMenu.cavaColor.b, 0.4)
            cavaProcess.running: mediaMenu.player && mediaMenu.player.isPlaying
            visible: mediaMenu.player && mediaMenu.player.isPlaying
        }

        Item {
            id: coverFrame
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -60
            width: 64
            height: 64
            visible: mediaMenu.player && mediaMenu.player.trackArtUrl.length > 0
            property int coverRadius: 0
            property int coverBorderWidth: 1
            property color coverBorderColor: Styles.mediaMenu.background.border.color
            
            Rectangle {
                id: coverMask
                anchors.fill: parent
                radius: coverFrame.coverRadius
                color: Styles.mediaMenu.background.border.color
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

        Column {
            anchors.centerIn: parent
            BetterText {
                id: title
                text: player ? truncate(player.trackTitle, 27) : ""

                Component.onCompleted: Styler.apply(title, Styles.mediaMenu.text)
            }
            BetterText {
                id: artist
                text: truncate(player?.trackArtist + " - " + player?.trackAlbum, 27)
                Component.onCompleted: Styler.apply(artist, Styles.mediaMenu.text)
            }
        }

        Timer {
            interval: 100
            running: player && player.isPlaying
            repeat: true
            onTriggered: {
                if (player) {
                    seekSlider.value = player.position
                }
            }
        }
        
        Slider {
            id: volumeSlider
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -55
            anchors.leftMargin: 15
            orientation: Qt.Vertical
            from: 0.0
            to: 1.0
            live: true
            value: mediaMenu.outputStreams[0] ? mediaMenu.outputStreams[0].audio.volume : 0

            implicitHeight: 70
            implicitWidth: 6
            
            onMoved: {
                for (var n of outputStreams) {
                    n.audio.volume = value
                }
            }

            background: Rectangle {
                x: volumeSlider.leftPadding + volumeSlider.availableWidth / 2 - width / 2
                y: volumeSlider.topPadding

                implicitWidth: 6
                implicitHeight: 70

                width: implicitWidth
                height: volumeSlider.availableHeight
                radius: 0
                color: Styles.mediaMenu.background.border.color

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * volumeSlider.position
                    color: Styles.mediaMenu.background.color
                    radius: 0
                }
            }

            handle: Rectangle {
                implicitWidth: volumeSlider.width
                implicitHeight: 0
                color: Styles.mediaMenu.background.border.color
                x: 0
                y: volumeSlider.topPadding + volumeSlider.visualPosition * (volumeSlider.availableHeight - height)
            }
        }

        Slider {
            id: seekSlider
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 25
            from: 0
            to: player ? player.length : 0
            live: true
            onMoved: {
                player.position = value
            }
            
            implicitWidth: 270
            implicitHeight: 6

            background: Rectangle {
                x: seekSlider.leftPadding
                y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2

                implicitWidth: 270
                implicitHeight: 6

                width: seekSlider.availableWidth
                height: implicitHeight
                radius: 0
                color: Styles.mediaMenu.background.border.color

                Rectangle {
                    width: parent.width * seekSlider.visualPosition
                    height: parent.height
                    color: Styles.mediaMenu.background.color
                    radius: 0
                }
            }

            handle: Rectangle {
                implicitWidth: 0
                implicitHeight: seekSlider.height
                color: Styles.mediaMenu.background.border.color
                x: seekSlider.leftPadding
                    + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                y: 0
            }
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
                Component.onCompleted: Styler.apply(prevBtn, Styles.mediaMenu.button)
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
                Component.onCompleted: Styler.apply(playBtn, Styles.mediaMenu.button)
            }
            MediaMenuButton {
                id: nextBtn
                iconType: "next"
                enabled: mediaMenu.player !== null
                onClicked: {
                    if (mediaMenu.player)
                        mediaMenu.player.next()
                }
                Component.onCompleted: Styler.apply(nextBtn, Styles.mediaMenu.button)
            }
        }
        Button {
            id: ytmusic
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.rightMargin: 10
            icon.source: "../icons/ytmusic.svg"
            background.visible: false
            icon.color: "transparent"
            display: AbstractButton.IconOnly
            onClicked: {
                    Quickshell.execDetached(["pear-desktop"])
            }
            Component.onCompleted: Styler.apply(ytmusic, Styles.mediaMenu.ytmusic)
        }
    }
}
