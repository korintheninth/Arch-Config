import QtQuick
import QtQuick.Controls
import "../../themes"
import "../../components"

Slider {
    id: slider
    property real syncedValue: 0
    property alias bar: fillBar
    live: true
    implicitHeight: 16
    padding: 0

    background: Rectangle {
        id: track
        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        implicitWidth: 120
        implicitHeight: 6
        width: slider.availableWidth
        height: 6
        radius: Styles.wallpaperGallery.slider.radius
        color: Styles.wallpaperGallery.slider.background.color

        SliderFill {
            id: fillBar
            position: slider.visualPosition
            radius: Styles.wallpaperGallery.slider.radius
            color: Styles.wallpaperGallery.slider.bar.color
        }
    }

    handle: Rectangle {
        implicitWidth: 0
        implicitHeight: slider.height
        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
        y: 0
        color: Styles.wallpaperGallery.slider.handle.color
    }

    onSyncedValueChanged: {
        if (!pressed)
            value = syncedValue
    }

    onPressedChanged: {
        let p = parent
        while (p) {
            if (p.contentHeight !== undefined && p.interactive !== undefined) {
                p.interactive = !pressed
                break
            }
            p = p.parent
        }
        if (!pressed)
            value = syncedValue
    }

    Component.onCompleted: value = syncedValue
}
