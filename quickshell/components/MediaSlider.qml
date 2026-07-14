import QtQuick
import QtQuick.Controls

Slider {
    id: slider

    property var player: null
    property alias bar: fillBar
    property var lastPos: 0
    property var lastTime: 0

    signal tick()

    live: true
    from: 0
    to: player ? player.length : 0

    onMoved: {
        if (player) {
            player.position = value
            lastPos = value
            lastTime = Date.now()
        }
    }

    Timer {
        interval: 100
        running: slider.player && slider.player.isPlaying
        repeat: true
        onTriggered: {
            if (!slider.player)
                return

            var pos = slider.player.position
            var deltaTime = (Date.now() - slider.lastTime) / 1000
            if (pos > slider.lastPos + deltaTime || Math.abs(pos - (slider.lastPos + deltaTime)) > 1) {
                slider.value = slider.player.position
                slider.lastPos = slider.player.position
                slider.lastTime = Date.now()
            } else if (slider.player.isPlaying) {
                slider.value = slider.lastPos + deltaTime
            }
            slider.tick()
        }
    }

    background: Rectangle {
        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2

        width: slider.availableWidth
        height: slider.implicitHeight
        radius: 0

        Rectangle {
            id: fillBar
            width: parent.width * slider.visualPosition
            height: parent.height
            radius: 0
        }
    }

    handle: Rectangle {
        implicitWidth: 0
        implicitHeight: slider.height
        x: slider.leftPadding
            + slider.visualPosition * (slider.availableWidth - width)
        y: 0
    }
}
