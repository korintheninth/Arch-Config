import QtQuick
import Quickshell
import Quickshell.Io
import "../services"
import "../themes"
import "../components"

Rectangle {
    id: updates

    height: parent.height
    color: Styles.updates.color
    radius: Styles.updates.radius
    visible: count > 0

    property int count: UpdateChecker.count
    property alias text: row.valueLabel

    readonly property color labelColor: count > 200 ? Styles.updates.criticalColor
        : count > 100 ? Styles.updates.warningColor
        : Styles.updates.baseColor

    IconValueRow {
        id: row
        anchors.centerIn: parent

        iconLabel.text: Styles.updates.icon.glyph
        iconLabel.color: updates.labelColor
        iconLabel.font.family: Styles.updates.icon.font.family
        iconLabel.font.bold: Styles.updates.icon.font.bold

        valueLabel.text: String(updates.count)
        valueLabel.color: updates.labelColor
        valueLabel.font.family: Styles.updates.text.font.family
        valueLabel.font.bold: Styles.updates.text.font.bold
    }
    
    Process {
        id: installUpdates
        command: [
            "kitty",
            "--class", "dotfiles-floating",
            "-e",
            Quickshell.shellPath("Scripts/installupdates.sh")
        ]
        onRunningChanged: {
            if (!running) {
                UpdateChecker.refresh()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                installUpdates.running = true
            }
        }
    }

    implicitWidth: visible ? row.implicitWidth + 10 : 0
}
