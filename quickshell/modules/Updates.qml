import QtQuick
import Quickshell
import Quickshell.Io
import "../services"
import "../themes"
import "../themes/StyleEngine.js" as Styler
import "../components"

Rectangle {
    id: updates

    height: parent.height
    color: "transparent"
    visible: count > 0

    property int count: UpdateChecker.count
    property alias text: row.valueLabel

    readonly property color labelColor: count > 200 ? Styles.updates.criticalColor
        : count > 100 ? Styles.updates.warningColor
        : Styles.updates.baseColor

    Component.onCompleted: {
        Styler.apply(updates, Styles.updates)
        Styler.apply(row.iconLabel, Styles.updates.icon)
        Styler.apply(row.valueLabel, Styles.updates.text)
    }

    IconValueRow {
        id: row
        anchors.centerIn: parent

        iconLabel.text: Styles.updates.iconGlyph
        iconLabel.color: updates.labelColor

        valueLabel.text: String(updates.count)
        valueLabel.color: updates.labelColor
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
