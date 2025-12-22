import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell

Item {
    id: workspaceSwitcher
    property int count: 6
    property int buttonWidth: 25
    property int spacing: 10
    implicitWidth: count * buttonWidth + (count - 1) * spacing + 20

    signal workspaceChanged(int newWorkspace)

    Rectangle {
        anchors.fill: parent
        radius: height/2
        color: root.widgetBG
    }

    Row {
        anchors.centerIn: parent
        spacing: workspaceSwitcher.spacing

        Repeater {
            model: workspaceSwitcher.count
            delegate: Button {
                id: btn
                text: (index + 1).toString()
                checkable: true
                checked: (index + 1) === Hyprland.focusedWorkspace.id

                implicitWidth: workspaceSwitcher.buttonWidth
                implicitHeight: workspaceSwitcher.buttonWidth
                
                onClicked: {
                    workspaceSwitcher.workspaceChanged(index + 1)
                }

                // Highlight the active workspace button
                background: Rectangle {
                    color: btn.checked ? root.primary : root.secondary
                    radius: height/2
                }

                contentItem: Text {
                    text: btn.text
                    color: btn.checked ? "white" : "lightgray"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent
                }
            }
        }
    }

    onWorkspaceChanged: {
        Hyprland.dispatch("workspace " + newWorkspace)
    }
}
