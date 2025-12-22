import QtQuick
import Quickshell.Io

Rectangle {
    id: disk

    anchors.verticalCenter: parent.verticalCenter
    radius: 10
    color: "lightgray"
    
    property string disk_usage
    
    Process {
        id: fetch_disk_usage

        running: true
        command: ["sh", "-c", "df -h /home | awk 'NR==2 {print $5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = text.trim()
                disk.disk_usage = output
            }
        }
    }
    
    Timer {
        id: delay

        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            fetch_disk_usage.running = true
        }
    }

    Text {
        id: disk_display

        font.family: root.defaultFontFamily
        font.pointSize: 12
        anchors.centerIn: parent
        color: "black"
    }
    implicitWidth: disk_display.paintedWidth + 10
}