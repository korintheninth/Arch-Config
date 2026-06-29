import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import "../themes"
import "../themes/StyleEngine.js" as Styler
import "../components"

Item {
    id: workspaces
    property int count: Hyprland.workspaces.values.length
    property int buttonWidth: 20
    property int spacing: 0
    property alias background: bg

    implicitWidth: count * buttonWidth + Math.max(0, count - 1) * spacing

    function applyWorkspaceButtonTextStyle(target) {
        if (Styles.workspaces.button.text)
            Styler.apply(target, Styles.workspaces.button.text)
    }

    Component.onCompleted: Styler.apply(workspaces, Styles.workspaces)

    Rectangle {
        id: bg
        anchors.fill: parent
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
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent

                    Component.onCompleted: workspaces.applyWorkspaceButtonTextStyle(this)
                }
            }
        }
    }
}
