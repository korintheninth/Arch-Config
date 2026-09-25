import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import "../themes"
import "../components"

Item {
    id: workspaces
    property int count: Hyprland.workspaces.values.length
    property int buttonWidth: Styles.workspaces.button.width
    property int spacing: Styles.workspaces.spacing
    property alias background: bg

    implicitWidth: count * buttonWidth + Math.max(0, count - 1) * spacing

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Styles.workspaces.background.color
        radius: Styles.workspaces.background.radius
    }

    Row {
        id: buttons
        anchors.centerIn: parent
        spacing: workspaces.spacing

        Repeater {
            model: Hyprland.workspaces
            delegate: Button {
                id: wsButton
                required property HyprlandWorkspace modelData

                readonly property var btnStyle: Styles.workspaces.button

                text: modelData.id.toString()
                checkable: true
                checked: modelData.focused
                implicitWidth: workspaces.buttonWidth
                implicitHeight: workspaces.implicitHeight > 0 ? workspaces.implicitHeight : implicitWidth

                onClicked: modelData.activate()

                background: Rectangle {
                    radius: wsButton.btnStyle.radius
                    color: wsButton.checked
                        ? wsButton.btnStyle.checked.fill
                        : wsButton.btnStyle.unchecked.fill
                }

                contentItem: BetterText {
                    text: wsButton.text
                    color: wsButton.checked
                        ? wsButton.btnStyle.checked.text
                        : wsButton.btnStyle.unchecked.text
                    font.family: wsButton.btnStyle.text.font.family
                    font.bold: wsButton.btnStyle.text.font.bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent
                }
            }
        }
    }
}
