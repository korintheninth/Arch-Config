import Quickshell
import QtQuick
import "../themes"
import "../themes/StyleEngine.js" as Styler

Scope {
    Connections {
        target: Quickshell
        
        // Disables the default popup when a config reloads successfully
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup()
        }
        
        // Disables the red error popup when you have a syntax error
        function onReloadFailed(error) {
            Quickshell.inhibitReloadPopup()
            
            // Optional: Print the error to your terminal instead so you don't lose it entirely
            console.error("Config Error: " + error) 
        }
    }
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData

                id: topbar
                anchors.top: true
                anchors.left: true
                anchors.right: true
                property alias background: bg
                
                Component.onCompleted: Styler.apply(topbar, Styles.topbar)

                Rectangle {
                    id: bg
                    anchors.fill: parent
                }

                    //left row
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    Workspaces { implicitHeight: topbar.height }
                    Systray { barHeight: topbar.height }
                    Media {implicitHeight: topbar.height}
                    spacing:10
                }
                
                //center row
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Clock {implicitHeight: topbar.height}
                }
                
                //right row
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    Updates { height: topbar.height }
                    Sound { height: topbar.height }
                    Battery {height: topbar.height}
                    HWState {height: topbar.height - 4}
                }
            }
        }
    }
}