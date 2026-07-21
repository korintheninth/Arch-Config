import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Controls
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../components"
import "../services"
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

            Component.onCompleted: {
                Styler.apply(tasksRegion, Styles.wallpaper.tasks)
                Styler.apply(tasksHeader, Styles.wallpaper.tasks.header)
                Styler.apply(todoistTasks.anchors, Styles.wallpaper.tasks.todoist.anchors)
                Styler.apply(clockWidget, Styles.wallpaper.clock)
                Styler.apply(clockHour, Styles.wallpaper.clock.text)
                Styler.apply(dot, Styles.wallpaper.clock.text)
                Styler.apply(clockMinute, Styles.wallpaper.clock.text)
                Styler.apply(mediaControl, Styles.wallpaper.media)
                Styler.apply(wallpaperCava, Styles.wallpaper.media.cava)
                Styler.apply(wallpaperTitle, Styles.wallpaper.media.text)
                Styler.apply(wallpaperArtist, Styles.wallpaper.media.text)
                Styler.apply(lyrics, Styles.wallpaper.lyrics)
                Styler.apply(lyrics.lr1, Styles.wallpaper.lyrics.text)
                Styler.apply(lyrics.lr2, Styles.wallpaper.lyrics.text)
                Styler.apply(lyrics.lr3, Styles.wallpaper.lyrics.text)
                Styler.apply(lyrics.lr4, Styles.wallpaper.lyrics.text)
                Styler.apply(lyrics.lr1, { color: Styles.wallpaper.lyrics.inactiveColor })
                Styler.apply(lyrics.lr3, { color: Styles.wallpaper.lyrics.inactiveColor })
                Styler.apply(lyrics.lr4, { color: Styles.wallpaper.lyrics.inactiveColor })
                Styler.apply(seekSlider, Styles.wallpaper.media.slider)
                Styler.apply(seekSlider, Styles.wallpaper.media.seekSlider)
                Styler.apply(prevBtn, Styles.wallpaper.media.button)
                Styler.apply(playBtn, Styles.wallpaper.media.button)
                Styler.apply(nextBtn, Styles.wallpaper.media.button)
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
                property int widthPadding: 20
                property int heightPadding: 80
                width: todoistTasks.width + widthPadding
                height: todoistTasks.height + heightPadding
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: 50
                anchors.leftMargin: 50
                radius: 10
                BetterText {
                    id: tasksHeader
                    text: "Today's Tasks:"
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 20
                    anchors.leftMargin: 25
                }
                Todoist {
                    id: todoistTasks
                    anchors.centerIn: parent
                    styleOverride: Styles.wallpaper.tasks.todoist.styleOverride
                    date: Date.today
                }
            }
            
            Rectangle {
                id: clockWidget
                color: "transparent"
                radius: 0
                z: 1
                anchors.centerIn: mediaControl
                
                SystemClock {
                    id: clock
                    precision: SystemClock.Minutes
                }
        
                BetterText {
                    id: clockHour
                    anchors.right: dot.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "hh")
                }
                BetterText {
                    id: dot
                    anchors.centerIn: parent
                    text: ":"
                }
                BetterText {
                    id: clockMinute
                    anchors.left: dot.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "mm")
                }

            }

            Rectangle {
                id: mediaControl
                color: "transparent"
                width: 800
                height: 300
                property int controlsSpacing: 20
                property int controlsBottomOffset: 35
                property int titleMaxLength: 75
                property int artistMaxLength: 75
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: 60
                anchors.rightMargin: 60
                
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

                Cava {
                    id: wallpaperCava
                    override: true
                    anchors.fill: parent
                    property int barCount: 70
                    barWidth: (mediaControl.width - (barCount - 1)) / barCount
                    confPath: "wallpaper.conf"
                    barColor: Qt.rgba(Styles.bgSecondary.r, Styles.bgSecondary.g, Styles.bgSecondary.b, 0.6)
                    visible: mediaControl.player && mediaControl.player.isPlaying
                    cavaProcess.running: mediaControl.player && mediaControl.player.isPlaying
                }

                Column {
                    anchors.top: parent.bottom
                    BetterText {
                        id: wallpaperTitle
                        text: mediaControl.player ? mediaControl.truncate(mediaControl.player.trackTitle, mediaControl.titleMaxLength) : ""
                    }
                    BetterText {
                        id: wallpaperArtist
                        text: mediaControl.truncate(mediaControl.player?.trackArtist + " - " + mediaControl.player?.trackAlbum, mediaControl.artistMaxLength)
                    }
                }
                
                MediaSlider {
                    id: seekSlider
                    player: mediaControl.player
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: parent.width
                    onTick: lyrics.populateLyrics()
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
                    }
                    MediaMenuButton {
                        id: nextBtn
                        iconType: "next"
                        enabled: mediaControl.player !== null
                        onClicked: {
                            if (mediaControl.player)
                                mediaControl.player.next()
                        }
                    }
                }
            }
            Lyrics {
                id: lyrics
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: 60
                anchors.topMargin: 60
                width: mediaControl.width
                position: seekSlider.value
            }
        }
    }
}
