import QtQuick
import Quickshell.Services.Pipewire
import Quickshell
import "../themes"
import "../components"

Rectangle {
    id: sound

    height: parent.height
    color: Styles.sound.color
    radius: Styles.sound.radius

    property alias text: row.valueLabel

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int pct: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool isBluetooth: {
        if (!sink)
            return false
        const label = [sink.name, sink.description, sink.nickname].join(" ").toLowerCase()
        if (label.includes("bluez") || label.includes("bluetooth"))
            return true
        const bus = String(sink.properties?.["device.bus"] ?? "").toLowerCase()
        return bus === "bluetooth"
    }

    PwObjectTracker {
        objects: sound.sink ? [sound.sink] : []
    }

    function iconAt(level) {
        if (muted)
            return Styles.sound.icon.muted
        const icons = isBluetooth
            ? Styles.sound.icon.bluetooth
            : Styles.sound.icon.wired
        if (!icons || icons.length === 0)
            return ""
        const index = Math.min(
            Math.floor((level / 100) * icons.length),
            icons.length - 1
        )
        return icons[index]
    }

    IconValueRow {
        id: row
        anchors.centerIn: parent

        iconLabel.text: sound.iconAt(sound.pct)
        iconLabel.color: Styles.sound.icon.color
        iconLabel.font.family: Styles.sound.icon.font.family
        iconLabel.font.pixelSize: Styles.sound.icon.font.pixelSize
        iconLabel.font.bold: Styles.sound.icon.font.bold
        valueLabel.text: sound.pct + "%"
        valueLabel.color: Styles.sound.text.color
        valueLabel.font.family: Styles.sound.text.font.family
        valueLabel.font.bold: Styles.sound.text.font.bold
    }

    SoundMenu {
        id: menu
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: {
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["pavucontrol"])
            } else if (mouse.button === Qt.RightButton) {
                menu.anchorTarget = sound
                menu.open = true
            }
        }
        onWheel: (wheel) => {
            const audio = sound.sink?.audio
            if (!audio)
                return
            if (audio.muted)
                audio.muted = false
            const steps = wheel.angleDelta.y / 120
            const delta = 0.02 * steps
            audio.volume = Math.max(0, Math.min(1, audio.volume + delta))
        }
    }

    implicitWidth: row.implicitWidth + 10
}
