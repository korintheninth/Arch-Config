import QtQuick
import Quickshell.Io

Rectangle {
    id: gpu

    anchors.verticalCenter: parent.verticalCenter
    radius: 10
    color: "lightgray"
    
    property real gpu_temp: 0
    property real gpu_usage: 0
    
    Process {
        id: fetch_gpu_temp

        running: true
        command: ["sh", "-c", "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = text.trim()
                gpu.gpu_temp = parseInt(output)
            }
        }
    }
    
    Process {
        id: fetch_gpu_usage

        running: true
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = text.trim()
                gpu.gpu_temp = parseInt(output)
            }
        }
    }

    Timer {
        id: delay

        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            fetch_gpu_temp.running = true
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