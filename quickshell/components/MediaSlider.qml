import QtQuick
import QtQuick.Controls
import "../services"

Slider {
    id: slider

    property alias bar: fillBar
    property color trackColor: "white"
    property color fillColor: "black"
    property color handleColor: "white"
    property real radius: 0

    signal tick()

    live: true
    from: 0
    to: PlayerService.length

    Binding {
        target: slider
        property: "value"
        value: PlayerService.position
        when: !slider.pressed
    }

    onMoved: {
        PlayerService.seek(value)
        tick()
    }

    Connections {
        target: PlayerService
        function onTick() {
            slider.tick()
        }
    }

    background: Rectangle {
        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2

        width: slider.availableWidth
        height: slider.implicitHeight
        radius: slider.radius
        color: slider.trackColor

        SliderFill {
            id: fillBar
            position: slider.visualPosition
            radius: slider.radius
            color: slider.fillColor
        }
    }

    handle: Rectangle {
        implicitWidth: 0
        implicitHeight: slider.height
        color: slider.handleColor
        x: slider.leftPadding
            + slider.visualPosition * (slider.availableWidth - width)
        y: 0
    }
}
