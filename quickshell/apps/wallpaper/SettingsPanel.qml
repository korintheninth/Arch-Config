import QtQuick
import "../../components"
import "../../themes"

Item {
    id: panel

    required property var gallery
    readonly property string tab: gallery.settingsTab
    readonly property string trans: gallery.awwwTransition

    Rectangle {
        anchors.fill: parent
        color: Styles.wallpaperGallery.sidebar.color
        radius: Styles.wallpaperGallery.sidebar.radius
        border.width: Styles.wallpaperGallery.sidebar.border.width
        border.color: Styles.wallpaperGallery.sidebar.border.color
        clip: radius > 0

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }
    }

    GalleryChipRow {
        id: tabs
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        model: ["wallust", "settings"]
        selected: gallery.settingsTab
        onPicked: gallery.settingsTab = value
    }

    Flickable {
        id: flick
        anchors.top: tabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 10
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: 10
        contentWidth: width
        contentHeight: body.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: flick.width
            spacing: 10

            Column {
                width: parent.width
                spacing: 10
                visible: panel.tab === "wallust"

                GalleryLabel { text: "backend" }
                GalleryChipRow {
                    model: gallery.wallustBackends
                    selected: gallery.wallustBackend
                    onPicked: gallery.wallustBackend = value
                }

                GalleryLabel { text: "color space" }
                GalleryChipRow {
                    model: gallery.wallustColorSpaces
                    selected: gallery.wallustColorSpace
                    onPicked: gallery.wallustColorSpace = value
                }

                GalleryLabel { text: "palette" }
                GalleryChipRow {
                    model: gallery.wallustPalettes
                    selected: gallery.wallustPalette
                    onPicked: gallery.wallustPalette = value
                }

                GalleryLabel { text: "fallback" }
                GalleryChipRow {
                    model: gallery.wallustFallbacks
                    selected: gallery.wallustFallback
                    onPicked: gallery.wallustFallback = value
                }

                Flow {
                    width: parent.width
                    spacing: 6
                    GalleryChip {
                        label: "contrast"
                        selected: gallery.wallustContrast
                        onClicked: gallery.wallustContrast = !gallery.wallustContrast
                    }
                    GalleryChip {
                        label: "saturation"
                        selected: gallery.wallustSatOn
                        onClicked: gallery.wallustSatOn = !gallery.wallustSatOn
                    }
                    GalleryChip {
                        label: "threshold"
                        selected: gallery.wallustThrOn
                        onClicked: gallery.wallustThrOn = !gallery.wallustThrOn
                    }
                }

                GallerySliderRow {
                    visible: gallery.wallustSatOn
                    label: "sat"
                    from: 1
                    to: 100
                    syncedValue: gallery.wallustSat
                    valueText: String(gallery.wallustSat)
                    onMoved: gallery.wallustSat = Math.round(value)
                }

                GallerySliderRow {
                    visible: gallery.wallustThrOn
                    label: "thr"
                    from: 0
                    to: 100
                    syncedValue: gallery.wallustThr
                    valueText: String(gallery.wallustThr)
                    onMoved: gallery.wallustThr = Math.round(value)
                }
            }

            Column {
                width: parent.width
                spacing: 10
                visible: panel.tab === "settings"

                GalleryLabel { text: "manager" }
                GalleryChipRow {
                    model: ["auto", "awww", "mpvpaper"]
                    selected: gallery.manager
                    onPicked: gallery.manager = value
                }

                Column {
                    width: parent.width
                    spacing: 8
                    visible: gallery.manager !== "mpvpaper"

                    GalleryLabel { text: "awww transition" }
                    GalleryChipRow {
                        model: gallery.awwwTransitions
                        selected: panel.trans
                        onPicked: gallery.awwwTransition = value
                    }

                    GallerySliderRow {
                        visible: panel.trans !== "none" && panel.trans !== "simple"
                        label: "time"
                        from: 1
                        to: 10
                        syncedValue: gallery.awwwDuration
                        valueText: gallery.awwwDuration + "s"
                        onMoved: gallery.awwwDuration = Math.round(value)
                    }

                    GallerySliderRow {
                        visible: panel.trans !== "none"
                        label: "step"
                        from: 1
                        to: 255
                        syncedValue: gallery.awwwStep
                        valueText: String(gallery.awwwStep)
                        onMoved: gallery.awwwStep = Math.round(value)
                    }

                    GallerySliderRow {
                        visible: panel.trans !== "none"
                        label: "fps"
                        from: 15
                        to: 120
                        syncedValue: gallery.awwwFps
                        valueText: String(gallery.awwwFps)
                        onMoved: gallery.awwwFps = Math.round(value)
                    }

                    GallerySliderRow {
                        visible: panel.trans === "wipe" || panel.trans === "wave"
                        label: "angle"
                        from: 0
                        to: 360
                        syncedValue: gallery.awwwAngle
                        valueText: String(gallery.awwwAngle)
                        onMoved: gallery.awwwAngle = Math.round(value)
                    }

                    GallerySliderRow {
                        visible: panel.trans === "wave"
                        label: "wave"
                        from: 1
                        to: 100
                        syncedValue: gallery.awwwWave
                        valueText: String(gallery.awwwWave)
                        onMoved: gallery.awwwWave = Math.round(value)
                    }

                    GalleryLabel {
                        visible: panel.trans === "grow" || panel.trans === "outer"
                        text: "position"
                    }
                    GalleryChipRow {
                        visible: panel.trans === "grow" || panel.trans === "outer"
                        model: gallery.awwwPositions
                        selected: gallery.awwwPos
                        onPicked: gallery.awwwPos = value
                    }

                    GalleryLabel {
                        visible: panel.trans === "fade"
                        text: "curve"
                    }
                    GalleryChipRow {
                        visible: panel.trans === "fade"
                        model: gallery.awwwBeziers
                        selected: gallery.awwwBezier
                        onPicked: gallery.awwwBezier = value
                    }
                }

                GalleryLabel { text: "keyboard" }
                GalleryChipRow {
                    model: gallery.keyboardModes
                    selected: gallery.keyboardMode
                    onPicked: {
                        gallery.keyboardMode = value
                        gallery.applyKeyboard()
                    }
                }
                Flow {
                    width: parent.width
                    spacing: 6
                    visible: gallery.keyboardMode === "color"

                    Repeater {
                        model: gallery.keyboardColorKeys
                        Rectangle {
                            id: swatch
                            required property string modelData
                            width: 20
                            height: 20
                            radius: Styles.wallpaperGallery.chip.radius
                            color: gallery.keyboardSwatch(modelData)
                            border.width: gallery.keyboardColor === modelData ? 2 : 1
                            border.color: Styles.fgBase

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    gallery.keyboardColor = swatch.modelData
                                    gallery.applyKeyboard()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
