import QtQuick
import Quickshell.Io
import Quickshell
import "../themes"
import "../themes/StyleEngine.js" as Styler

Rectangle {
    id: cava

    anchors.verticalCenter: parent.bottom
    color: "transparent"
    property bool override: false
    property alias bars: bars
    property double barWidth: 2
    property color barColor: "white"
    property string confPath: "bar.conf"
    property var cavaBars: []
    property alias cavaProcess: cavaProcess
    Process {
        id: cavaProcess
        command: ["cava", "-p" , Quickshell.shellPath(cava.confPath)]
        running: true
        
        stdout: SplitParser {
            splitMarker: "\n"
            
            onRead: chunk => {
                let parts = chunk.split(";")
                
                cava.cavaBars = parts.map(v => parseInt(v) / 1000.0)
            }
        }
    }
    onVisibleChanged: cavaBars = []
    Row {
        id: bars
        anchors.fill: parent
        anchors.bottomMargin: 0
        spacing: 2
        Repeater {
            model: cava.cavaBars.length

            Rectangle {
                width: cava.barWidth
                height: Math.max(0.0001, cava.cavaBars[index] * cava.height)
                color: cava.barColor
                anchors.bottom: parent.bottom 
                Behavior on height {
                    NumberAnimation { 
                        duration: 35 
                        easing.type: Easing.OutQuad 
                    }
                }
            }
        }
    }

    Component.onCompleted: if (!override) Styler.apply(cava, Styles.cava)
}
