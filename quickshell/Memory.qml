import QtQuick
import Quickshell.Io

Rectangle {
    id: memory

    anchors.verticalCenter: parent.verticalCenter
    radius: 10
    color: "lightgray"
    
    property real memory_usage: 0
    
    Process {
        id: fetch_memory_usage

        running: true
        command: ["sh", "-c", "cat /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = text.split("\n")
                var totalMem = output[0].split(" ")[7]
                var freeMem = output[2].split(" ")[3]
                var usedMem = parseInt(totalMem) - parseInt(freeMem)
                memory.memory_usage = Math.round((usedMem / parseInt(totalMem)) * 100)
            }
        }
    }
    
    Timer {
        id: delay

        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            fetch_memory_usage.running = true
        }
    }

    Text {
        id: cpu_display

        font.family: root.defaultFontFamily
        font.pointSize: 12
        anchors.centerIn: parent
        color: "black"
    }
    implicitWidth: cpu_display.paintedWidth + 10
}