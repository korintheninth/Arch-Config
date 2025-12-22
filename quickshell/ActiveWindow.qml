import QtQuick
import Quickshell.Wayland

Rectangle {
    id: activeWindow

    anchors.verticalCenter: parent.verticalCenter
    radius: 10
    color: "lightgray"
    
    Text {
        id: windowText

        anchors.centerIn: parent
        text: ToplevelManager.activeToplevel
           ? (function() {
               var appId = ToplevelManager.activeToplevel.appId.trim();
               return appId.charAt(0).toUpperCase() + appId.slice(1);
             })()
           : "null"
           }
    implicitWidth: windowText.paintedWidth + 10
}