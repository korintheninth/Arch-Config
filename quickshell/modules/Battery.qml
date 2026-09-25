import QtQuick
import Quickshell.Services.UPower
import "../themes"
import "../components"

Rectangle {
    id: battery

    height: parent.height
    color: Styles.battery.color
    radius: Styles.battery.radius

    property alias text: row.valueLabel
    readonly property int pct: Math.round(UPower.displayDevice.percentage * 100)
    readonly property bool isCharging: {
        const state = UPower.displayDevice.state
        return state === UPowerDeviceState.Charging
            || state === UPowerDeviceState.PendingCharge
    }

    readonly property color labelColor: battery.pct <= 20 ? Styles.battery.criticalColor
        : battery.pct <= 40 ? Styles.battery.warningColor
        : Styles.battery.baseColor

    function iconAt(level) {
        const icons = isCharging
            ? Styles.battery.icon.charging
            : Styles.battery.icon.discharging
        if (!icons || icons.length === 0)
            return ""
        const index = Math.min(
            Math.floor((level / 100) * icons.length),
            icons.length - 1
        )
        return icons[index]
    }

    function formatDuration(seconds) {
        const s = Math.round(seconds)
        if (s <= 0)
            return ""
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        if (h > 0 && m > 0)
            return h + "h " + m + "m"
        if (h > 0)
            return h + "h"
        if (m > 0)
            return m + "m"
        return "<1m"
    }

    readonly property string tooltipText: {
        const dev = UPower.displayDevice
        if (isCharging || !UPower.onBattery) {
            if (pct >= 100 || dev.timeToFull <= 0)
                return "Full"
            const t = formatDuration(dev.timeToFull)
            return t ? t + " to full" : "Full"
        }
        const t = formatDuration(dev.timeToEmpty)
        return t ? t + " remaining" : "—"
    }

    IconValueRow {
        id: row
        anchors.centerIn: parent

        iconLabel.text: battery.iconAt(battery.pct)
        iconLabel.color: battery.labelColor
        iconLabel.font.family: Styles.battery.icon.font.family
        iconLabel.font.bold: Styles.battery.icon.font.bold

        valueLabel.text: battery.pct + "%"
        valueLabel.color: battery.labelColor
        valueLabel.font.family: Styles.battery.text.font.family
        valueLabel.font.bold: Styles.battery.text.font.bold
    }

    implicitWidth: row.implicitWidth + 10

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    StyledToolTip {
        anchorTarget: battery
        styleOverride: { "anchor": { "margins": { "top": 18 } } }
        text: battery.tooltipText
        show: mouseArea.containsMouse
    }
}
