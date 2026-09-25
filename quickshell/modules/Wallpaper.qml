import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import QtQuick.Controls
import "../components"
import "../services"
import "../themes"



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
                property int widthPadding: Styles.wallpaper.tasks.widthPadding
                property int heightPadding: Styles.wallpaper.tasks.heightPadding
                width: todoistTasks.width + widthPadding
                height: todoistTasks.height + heightPadding
                color: Styles.wallpaper.tasks.color
                radius: Styles.wallpaper.tasks.radius
                border.width: Styles.wallpaper.tasks.border.width
                border.color: Styles.wallpaper.tasks.border.color
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: Styles.wallpaper.tasks.anchors.topMargin
                anchors.leftMargin: Styles.wallpaper.tasks.anchors.leftMargin
                BetterText {
                    id: tasksHeader
                    text: Styles.wallpaper.tasks.header.text
                    color: Styles.wallpaper.tasks.header.color
                    font.family: Styles.wallpaper.tasks.header.font.family
                    font.pixelSize: Styles.wallpaper.tasks.header.font.pixelSize
                    font.bold: Styles.wallpaper.tasks.header.font.bold
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: Styles.wallpaper.tasks.header.anchors.topMargin
                    anchors.leftMargin: Styles.wallpaper.tasks.header.anchors.leftMargin
                }
                Todoist {
                    id: todoistTasks
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Styles.wallpaper.tasks.todoist.anchors.verticalCenterOffset
                    styleOverride: Styles.wallpaper.tasks.todoist.styleOverride
                    date: Date.today
                }
            }
            
            Rectangle {
                id: clockWidget
                color: Styles.wallpaper.clock.color
                radius: Styles.wallpaper.clock.radius
                z: 1
                anchors.centerIn: mediaControl
                implicitWidth: clockRow.implicitWidth
                implicitHeight: clockRow.implicitHeight

                layer.enabled: true
                layer.smooth: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Styles.wallpaper.clock.shadow.color
                    shadowOpacity: Styles.wallpaper.clock.shadow.opacity
                    shadowBlur: Styles.wallpaper.clock.shadow.blur
                    shadowHorizontalOffset: Styles.wallpaper.clock.shadow.horizontalOffset
                    shadowVerticalOffset: Styles.wallpaper.clock.shadow.verticalOffset
                }
                
                SystemClock {
                    id: clock
                    precision: SystemClock.Minutes
                }

                Row {
                    id: clockRow

                    BetterText {
                        id: clockHour
                        color: Styles.wallpaper.clock.text.color
                        font.family: Styles.wallpaper.clock.text.font.family
                        font.pixelSize: Styles.wallpaper.clock.text.font.pixelSize
                        font.bold: Styles.wallpaper.clock.text.font.bold
                        text: Qt.formatDateTime(clock.date, "hh")
                    }
                    BetterText {
                        id: dot
                        color: Styles.wallpaper.clock.text.color
                        font.family: Styles.wallpaper.clock.text.font.family
                        font.pixelSize: Styles.wallpaper.clock.text.font.pixelSize
                        font.bold: Styles.wallpaper.clock.text.font.bold
                        text: ":"
                    }
                    BetterText {
                        id: clockMinute
                        color: Styles.wallpaper.clock.text.color
                        font.family: Styles.wallpaper.clock.text.font.family
                        font.pixelSize: Styles.wallpaper.clock.text.font.pixelSize
                        font.bold: Styles.wallpaper.clock.text.font.bold
                        text: Qt.formatDateTime(clock.date, "mm")
                    }
                }

            }

            Rectangle {
                id: mediaControl
                color: Styles.wallpaper.media.color
                width: Styles.wallpaper.media.width
                height: Styles.wallpaper.media.height
                property int controlsSpacing: Styles.wallpaper.media.controls.spacing
                property int controlsBottomOffset: Styles.wallpaper.media.controls.bottomOffset
                property int titleMaxLength: Styles.wallpaper.media.titleMaxLength
                property int artistMaxLength: Styles.wallpaper.media.artistMaxLength
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: Styles.wallpaper.media.anchors.bottomMargin
                anchors.rightMargin: Styles.wallpaper.media.anchors.rightMargin
                
                function truncate(str, max) {
                    if (!str || max <= 0) return str ?? ""
                    return str.length > max ? str.slice(0, max - 1) + "…" : str
                }

                Cava {
                    id: wallpaperCava
                    anchors.fill: parent
                    anchors.leftMargin: 0
                    bars.anchors.bottomMargin: 0
                    bars.spacing: Styles.wallpaper.media.cava.bars.spacing
                    barCount: Styles.wallpaper.media.cava.barCount
                    barWidth: (mediaControl.width - (barCount - 1) * bars.spacing) / barCount
                    barColor: Styles.wallpaper.media.cava.barColor
                    visible: PlayerService.active
                    running: PlayerService.active
                }

                /*
                Oscilloscope {
                    id: wallpaperOscilloscope
                    anchors.fill: parent
                    visible: PlayerService.active
                    running: visible && modelData === Quickshell.screens[0]
                }
                */

                Column {
                    anchors.top: parent.bottom
                    BetterText {
                        id: wallpaperTitle
                        color: Styles.wallpaper.media.text.color
                        font.family: Styles.wallpaper.media.text.font.family
                        font.pixelSize: Styles.wallpaper.media.text.font.pixelSize
                        font.bold: Styles.wallpaper.media.text.font.bold
                        text: PlayerService.active ? mediaControl.truncate(PlayerService.trackTitle, mediaControl.titleMaxLength) : ""
                    }
                    BetterText {
                        id: wallpaperArtist
                        color: Styles.wallpaper.media.text.color
                        font.family: Styles.wallpaper.media.text.font.family
                        font.pixelSize: Styles.wallpaper.media.text.font.pixelSize
                        font.bold: Styles.wallpaper.media.text.font.bold
                        text: mediaControl.truncate(PlayerService.trackArtist + " - " + PlayerService.trackAlbum, mediaControl.artistMaxLength)
                    }
                }
                
                MediaSlider {
                    id: seekSlider
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: parent.width
                    implicitHeight: Styles.wallpaper.media.seekSlider.implicitHeight
                    trackColor: Styles.wallpaper.media.slider.background.color
                    fillColor: Styles.wallpaper.media.slider.bar.color
                    handleColor: Styles.wallpaper.media.slider.handle.color
                    radius: Styles.wallpaper.media.slider.radius
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
                        size: Styles.wallpaper.media.button.size
                        radius: Styles.wallpaper.media.button.radius
                        normalColor: Styles.wallpaper.media.button.normalColor
                        hoverColor: Styles.wallpaper.media.button.hoverColor
                        pressedColor: Styles.wallpaper.media.button.pressedColor
                        iconSize: Styles.wallpaper.media.button.iconSize
                        iconColor: Styles.wallpaper.media.button.iconColor
                        iconHoverColor: Styles.wallpaper.media.button.iconHoverColor
                        iconPressedColor: Styles.wallpaper.media.button.iconPressedColor
                        shadow: Styles.wallpaper.media.button.shadow
                        enabled: PlayerService.active
                        onClicked: PlayerService.previous()
                    }
                    MediaMenuButton {
                        id: playBtn
                        iconType: PlayerService.isPlaying ? "pause" : "play"
                        size: Styles.wallpaper.media.button.size
                        radius: Styles.wallpaper.media.button.radius
                        normalColor: Styles.wallpaper.media.button.normalColor
                        hoverColor: Styles.wallpaper.media.button.hoverColor
                        pressedColor: Styles.wallpaper.media.button.pressedColor
                        iconSize: Styles.wallpaper.media.button.iconSize
                        iconColor: Styles.wallpaper.media.button.iconColor
                        iconHoverColor: Styles.wallpaper.media.button.iconHoverColor
                        iconPressedColor: Styles.wallpaper.media.button.iconPressedColor
                        shadow: Styles.wallpaper.media.button.shadow
                        enabled: PlayerService.active
                        onClicked: PlayerService.togglePlayPause()
                    }
                    MediaMenuButton {
                        id: nextBtn
                        iconType: "next"
                        size: Styles.wallpaper.media.button.size
                        radius: Styles.wallpaper.media.button.radius
                        normalColor: Styles.wallpaper.media.button.normalColor
                        hoverColor: Styles.wallpaper.media.button.hoverColor
                        pressedColor: Styles.wallpaper.media.button.pressedColor
                        iconSize: Styles.wallpaper.media.button.iconSize
                        iconColor: Styles.wallpaper.media.button.iconColor
                        iconHoverColor: Styles.wallpaper.media.button.iconHoverColor
                        iconPressedColor: Styles.wallpaper.media.button.iconPressedColor
                        shadow: Styles.wallpaper.media.button.shadow
                        enabled: PlayerService.active
                        onClicked: PlayerService.next()
                    }
                }
            }
            Lyrics {
                id: lyrics
                visible: PlayerService.active
                anchors.top: parent.top
                anchors.right: parent.right
                width: mediaControl.width
                height: Styles.wallpaper.lyrics.height
                padding: Styles.wallpaper.lyrics.padding
                inactiveColor: Styles.wallpaper.lyrics.inactiveColor
                anchors.topMargin: Styles.wallpaper.lyrics.anchors.topMargin
                anchors.rightMargin: Styles.wallpaper.lyrics.anchors.rightMargin
                background.color: Styles.wallpaper.lyrics.background.color
                background.radius: Styles.wallpaper.lyrics.background.radius
                background.visible: Styles.wallpaper.lyrics.background.visible
                background.opacity: Styles.wallpaper.lyrics.background.opacity
                background.border.width: Styles.wallpaper.lyrics.background.border.width
                background.border.color: Styles.wallpaper.lyrics.background.border.color
                lr1.font.family: Styles.wallpaper.lyrics.text.font.family
                lr1.font.pixelSize: Styles.wallpaper.lyrics.text.font.pixelSize
                lr1.font.bold: Styles.wallpaper.lyrics.text.font.bold
                lr2.color: Styles.wallpaper.lyrics.text.color
                lr2.font.family: Styles.wallpaper.lyrics.text.font.family
                lr2.font.pixelSize: Styles.wallpaper.lyrics.text.font.pixelSize
                lr2.font.bold: Styles.wallpaper.lyrics.text.font.bold
                lr3.font.family: Styles.wallpaper.lyrics.text.font.family
                lr3.font.pixelSize: Styles.wallpaper.lyrics.text.font.pixelSize
                lr3.font.bold: Styles.wallpaper.lyrics.text.font.bold
                lr4.font.family: Styles.wallpaper.lyrics.text.font.family
                lr4.font.pixelSize: Styles.wallpaper.lyrics.text.font.pixelSize
                lr4.font.bold: Styles.wallpaper.lyrics.text.font.bold
                position: PlayerService.position
            }

            Keyboard {
                id: keyboardWidget
                anchors.centerIn: parent
            }

            /*
            Vectorscope {
                id: wallpaperScope
                anchors.centerIn: parent
                visible: PlayerService.active
                running: visible && modelData === Quickshell.screens[0]
            }
            */

        }
    }
}
