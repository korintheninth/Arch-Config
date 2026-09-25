import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtMultimedia
import "../../themes"

Item {
    id: panel

    required property var gallery
    readonly property var file: gallery.selectedFile
    readonly property string previewKind: file ? file.kind : ""
    readonly property bool videoFilteredStill: previewKind === "video" && gallery.previewPath !== ""

    // Filtered preview if one has been rendered, otherwise the original file.
    readonly property string previewUrl: gallery.previewPath
        ? gallery.fileUrl(gallery.previewPath) + "?n=" + gallery.previewNonce
        : (file ? gallery.fileUrl(file.path) : "")

    Rectangle {
        anchors.fill: parent
        color: Styles.wallpaperGallery.preview.color
        radius: Styles.wallpaperGallery.preview.radius
        border.width: Styles.wallpaperGallery.preview.border.width
        border.color: Styles.wallpaperGallery.preview.border.color
        clip: radius > 0

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 10
        contentWidth: width
        contentHeight: body.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: flick.width
            spacing: 10

            Rectangle {
                id: previewFrame
                width: parent.width
                height: Math.round(width * 9 / 16)
                color: Styles.wallpaperGallery.preview.frame.color
                radius: Styles.wallpaperGallery.preview.frame.radius

                Rectangle {
                    id: previewMask
                    anchors.fill: parent
                    radius: previewFrame.radius
                    color: "white"
                    visible: false
                    layer.enabled: true
                    layer.smooth: true
                }

                Item {
                    id: previewContents
                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: previewMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                    }

                    Image {
                        id: previewImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        visible: source !== "" && status === Image.Ready
                        source: {
                            if (panel.previewKind === "image")
                                return panel.previewUrl
                            if (panel.videoFilteredStill)
                                return gallery.fileUrl(gallery.previewPath) + "?n=" + gallery.previewNonce
                            return ""
                        }
                    }

                    AnimatedImage {
                        id: previewGif
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        playing: visible && gallery.open
                        visible: panel.previewKind === "gif" && source !== ""
                        source: panel.previewKind === "gif" ? panel.previewUrl : ""
                    }

                    Video {
                        anchors.fill: parent
                        muted: true
                        volume: 0
                        autoPlay: true
                        loops: MediaPlayer.Infinite
                        fillMode: VideoOutput.PreserveAspectCrop
                        visible: panel.previewKind === "video" && gallery.open && !panel.videoFilteredStill
                        source: panel.previewKind === "video" ? gallery.fileUrl(panel.file.path) : ""
                        onVisibleChanged: visible ? play() : stop()
                        onSourceChanged: {
                            if (visible && source !== "")
                                play()
                        }
                    }

                    GalleryLabel {
                        anchors.centerIn: parent
                        visible: {
                            if (!panel.file)
                                return true
                            if (panel.previewKind === "video")
                                return panel.videoFilteredStill && !previewImage.visible
                            if (panel.previewKind === "gif")
                                return previewGif.status !== Image.Ready
                            return !previewImage.visible
                        }
                        text: panel.file ? "loading" : "select a wallpaper"
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: previewFrame.radius
                    color: "transparent"
                    border.width: Styles.wallpaperGallery.preview.frame.border.width
                    border.color: Styles.wallpaperGallery.preview.frame.border.color
                }
            }

            GalleryLabel {
                width: parent.width
                role: "text"
                wrapMode: Text.Wrap
                elide: Text.ElideMiddle
                maximumLineCount: 2
                text: panel.file ? panel.file.name : "nothing selected"
            }

            GalleryLabel {
                width: parent.width
                visible: !!panel.file
                text: panel.file ? panel.file.kind + "  ·  " + (panel.file.folder || "root") : ""
            }

            Column {
                width: parent.width
                spacing: 8
                visible: gallery.liveVideo

                GalleryLabel { text: "wallpaper video" }
                Flow {
                    width: parent.width
                    spacing: 6
                    GalleryChip {
                        label: gallery.livePaused ? "play" : "pause"
                        selected: !gallery.livePaused
                        onClicked: gallery.liveTogglePause()
                    }
                    GalleryChip {
                        label: gallery.liveMuted ? "sound off" : "sound on"
                        selected: !gallery.liveMuted
                        onClicked: gallery.liveToggleMute()
                    }
                    GalleryChip {
                        label: "restart"
                        onClicked: gallery.mpvIpc("restart")
                    }
                    GalleryChip {
                        label: "-5s"
                        onClicked: gallery.mpvIpc("seek", -5)
                    }
                    GalleryChip {
                        label: "+5s"
                        onClicked: gallery.mpvIpc("seek", 5)
                    }
                }
                GallerySliderRow {
                    label: "vol"
                    from: 0
                    to: 100
                    syncedValue: gallery.liveVolume
                    valueText: String(gallery.liveVolume)
                    onMoved: gallery.liveSetVolume(Math.round(value))
                }
            }

            GalleryLabel { text: "filters" }
            Flow {
                width: parent.width
                spacing: 6
                GalleryChip {
                    label: "gray"
                    selected: gallery.filterGray
                    onClicked: gallery.filterGray = !gallery.filterGray
                }
                GalleryChip {
                    label: "bw"
                    selected: gallery.filterBw
                    onClicked: gallery.filterBw = !gallery.filterBw
                }
                GalleryChip {
                    label: "invert"
                    selected: gallery.filterInvert
                    onClicked: gallery.filterInvert = !gallery.filterInvert
                }
                GalleryChip {
                    label: "sepia"
                    selected: gallery.filterSepia
                    onClicked: gallery.filterSepia = !gallery.filterSepia
                }
                GalleryChip {
                    label: "dither"
                    selected: gallery.filterDither
                    onClicked: gallery.filterDither = !gallery.filterDither
                }
            }

            GallerySliderRow {
                label: "colors"
                from: 0
                to: gallery.colorStops.length - 1
                stepSize: 1
                snapMode: Slider.SnapAlways
                syncedValue: gallery.colorStopIndex
                valueText: gallery.filterColors > 0 ? String(gallery.filterColors) : "off"
                onMoved: gallery.colorStopIndex = Math.round(value)
            }
            GallerySliderRow {
                label: "sat"
                from: 0
                to: 200
                syncedValue: gallery.filterSat
                valueText: String(gallery.filterSat)
                onMoved: gallery.filterSat = Math.round(value)
            }
            GallerySliderRow {
                label: "bri"
                from: 0
                to: 200
                syncedValue: gallery.filterBri
                valueText: String(gallery.filterBri)
                onMoved: gallery.filterBri = Math.round(value)
            }
            GallerySliderRow {
                label: "con"
                from: 0
                to: 200
                syncedValue: gallery.filterCon
                valueText: String(gallery.filterCon)
                onMoved: gallery.filterCon = Math.round(value)
            }
            GallerySliderRow {
                label: "hue"
                from: 0
                to: 360
                syncedValue: gallery.filterHue
                valueText: String(gallery.filterHue)
                onMoved: gallery.filterHue = Math.round(value)
            }

            GalleryLabel { text: "tint" }
            GalleryChipRow {
                model: ["none", "red", "blue", "green", "amber", "pink"]
                selected: gallery.filterTint
                onPicked: gallery.filterTint = value
            }
            GallerySliderRow {
                visible: gallery.filterTint !== "none"
                label: "amount"
                from: 0
                to: 100
                syncedValue: gallery.filterTintAmount
                valueText: String(gallery.filterTintAmount)
                onMoved: gallery.filterTintAmount = Math.round(value)
            }

            Row {
                width: parent.width
                spacing: 8
                GalleryButton {
                    label: "reset"
                    width: (parent.width - 16) / 3
                    onClicked: gallery.resetFilters()
                }
                GalleryButton {
                    label: gallery.saving ? "saving..." : "save"
                    width: (parent.width - 16) / 3
                    enabled: !!panel.file && !gallery.saving
                    onClicked: gallery.saveSelected()
                }
                GalleryButton {
                    label: gallery.applying ? "applying..." : "apply"
                    width: (parent.width - 16) / 3
                    selected: true
                    enabled: !!panel.file && !gallery.applying
                    onClicked: gallery.applySelected()
                }
            }

            GalleryLabel {
                width: parent.width
                wrapMode: Text.Wrap
                visible: gallery.statusText !== ""
                text: gallery.statusText
            }
        }
    }
}
