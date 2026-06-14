import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Controls
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../components"
import "../themes"
import "../themes/StyleEngine.js" as Styler



Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            required property var modelData
            screen: modelData
            
            id: bgLayer
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            aboveWindows: false 
            WlrLayershell.layer: WlrLayer.Bottom 
            
            exclusionMode: ExclusionMode.Ignore
            
            mask: Region {
                Region { item: tasksRegion }
                Region { item: mediaControl }
            }
            Rectangle {
                id: tasksRegion
                width: todoistTasks.width + 50
                height: todoistTasks.height + 80
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: 100
                anchors.leftMargin: 100
                color: Qt.rgba(Styles.bgBase.r, Styles.bgBase.g, Styles.bgBase.b, 0.02)
                radius: 10
                BetterText {
                    text: "Today's Tasks:"
                    font.family: "Silkscreen"
                    font.pixelSize: 20
                    color: Styles.fgBase
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 20
                    anchors.leftMargin: 25
                }
                Todoist {
                    id: todoistTasks
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 25
                    styleOverride: {
                        "rowSpacing": 20,
                        "taskMaxWidth": 320,
                        "task": {
                            "text": {
                                "font": {
                                    "pixelSize": 20,
                                    "family": "Silkscreen",
                                },
                            },
                            "due": {
                                "font": {
                                },
                            },
                            "check": {
                                "font": {
                                    "pixelSize": 20
                                },
                            }
                        },
                        "empty": {
                            "text": {
                                "font": {
                                },
                            }
                        },
                        "error": {
                            "text": {
                                "font": {
                                },
                                "color": "#e54545"
                            }
                        },
                    }
                    date: Date.today
                }
            }
            
            Rectangle {
                id: clockWidget
                
                anchors.centerIn: mediaControl

                property var clock: ({
                    "color": "transparent",
                    "radius": 0,
                    "text": {
                        "font": {
                            "family": "Silkscreen",
                            "pixelSize": 200,
                            "bold": false
                        },
                        "color": Styles.fgBase
                    }
                })
                
                property alias text: clock_display
                
                Component.onCompleted: Styler.apply(clockWidget, clockWidget.clock)
                
                SystemClock {
                    id: clock
                    precision: SystemClock.Minutes
                }

                BetterText {
                    id: clock_display
                    text: Qt.formatDateTime(clock.date, "hh:mm")
                    anchors.centerIn: parent
                }

                implicitWidth: clock_display.paintedWidth + 20

            }

            Rectangle {
                id: mediaControl
                color: "transparent"
                width: 800
                height: 300
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: 60
                anchors.rightMargin: 100
                property color cavaColor: "transparent"
                property int controlsSpacing: 20
                property int controlsBottomOffset: 35
                
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

                Component.onCompleted: {
                    if (typeof Styles !== "undefined" && Styles.mediaMenu)
                        Styler.apply(mediaControl, Styles.mediaMenu)
                }

                Cava {
                    override: true
                    anchors.fill: parent
                    barWidth: (mediaControl.width - 69) / 70
                    bars.spacing: 1
                    confPath: "wallpaper.conf"
                    barColor: Qt.rgba(Styles.bgSecondary.r, Styles.bgSecondary.g, Styles.bgSecondary.b, 0.6)
                    visible: mediaControl.player && mediaControl.player.isPlaying
                    cavaProcess.running: mediaControl.player && mediaControl.player.isPlaying
                }

                Column {
                    anchors.top: parent.bottom
                    BetterText {
                        id: title
                        text: mediaControl.player ? mediaControl.truncate(mediaControl.player.trackTitle, 60) : ""

                        Component.onCompleted: Styler.apply(title, Styles.mediaMenu.text)
                    }
                    BetterText {
                        id: artist
                        text: mediaControl.truncate(mediaControl.player?.trackArtist + " - " + mediaControl.player?.trackAlbum, 60)

                        Component.onCompleted: Styler.apply(artist, Styles.mediaMenu.text)
                    }
                }

                Timer {
                    interval: 100
                    running: mediaControl.player && mediaControl.player.isPlaying
                    repeat: true
                    onTriggered: {
                        if (mediaControl.player) {
                            seekSlider.value = mediaControl.player.position
                        }
                    }
                }

                Slider {
                    id: seekSlider
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    from: 0
                    to: mediaControl.player ? mediaControl.player.length : 0
                    live: true
                    onMoved: {
                        mediaControl.player.position = value
                    }
                    
                    implicitWidth: parent.width
                    implicitHeight: 6

                    background: Rectangle {
                        x: seekSlider.leftPadding
                        y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2

                        implicitWidth: seekSlider.width
                        implicitHeight: seekSlider.height

                        width: seekSlider.availableWidth
                        height: implicitHeight
                        radius: 0
                        color: Styles.fgBase

                        Rectangle {
                            width: parent.width * seekSlider.visualPosition
                            height: parent.height
                            color: Styles.bgBase
                            radius: 0
                        }
                    }

                    handle: Rectangle {
                        implicitWidth: 0
                        implicitHeight: seekSlider.height
                        color: Styles.fgBase
                        x: seekSlider.leftPadding
                            + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                        y: 0
                    }
                }

                Row {
                    id: mediaButtons
                    spacing: mediaControl.controlsSpacing
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.bottom
                    anchors.verticalCenterOffset: -mediaControl.controlsBottomOffset

                    MediaMenuButton {
                        id: prevBtn
                        iconType: "prev"
                        enabled: mediaControl.player !== null
                        onClicked: {
                            if (mediaControl.player)
                                mediaControl.player.previous()
                        }
                        Component.onCompleted: Styler.apply(prevBtn, Styles.mediaMenu.button)
                    }
                    MediaMenuButton {
                        id: playBtn
                        iconType: mediaControl.player?.isPlaying ? "pause" : "play"
                        enabled: mediaControl.player !== null
                        onClicked: {
                            const p = mediaControl.player
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
                        enabled: mediaControl.player !== null
                        onClicked: {
                            if (mediaControl.player)
                                mediaControl.player.next()
                        }
                        Component.onCompleted: Styler.apply(nextBtn, Styles.mediaMenu.button)
                    }
                }
            }
        }
    }
}