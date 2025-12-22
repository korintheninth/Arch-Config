import Quickshell
import QtQuick

Scope {
    PanelWindow {
        id: topbar
        anchors.top: true
        anchors.left: true
        anchors.right: true
        color: "transparent"
        margins.top: 5
        margins.right: 5
        margins.left: 5
        implicitHeight: 30
        
            //left row
        Row {
            anchors.left: parent.left
        }
        
        //center row
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            Clock {implicitHeight: topbar.height}
        }
        
        //right row
        Row {
            anchors.right: parent.right
            Workspaces {implicitHeight: topbar.height; count: 3}
        }
    }
}