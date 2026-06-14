import QtQuick
import Quickshell.Wayland
import "../themes"
import "../themes/StyleEngine.js" as Styler

Rectangle {
    id: activeWindow

    anchors.verticalCenter: parent.verticalCenter

    Component.onCompleted: Styler.apply(activeWindow, Styles.activeWindow)
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