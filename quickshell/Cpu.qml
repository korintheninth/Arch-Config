import QtQuick
import Quickshell.Io

Rectangle {
    id: cpu

    anchors.verticalCenter: parent.verticalCenter
    radius: 10
    color: "lightgray"
    
    property real cpu_usage: 0
    property real cpu_temp: 0

    property real prevIdle : 0
    property real prevTotal: 0

    Process {
        id: fetch_cpu_usage

        running: true
        command: ["sh", "-c", "grep 'cpu' /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = text.trim().split("\n")[0].split(" ")
                var idle = parseInt(output[5]) + parseInt(output[6])
                var nonIdle = parseInt(output[2]) + parseInt(output[3]) + parseInt(output[4]) + parseInt(output[7]) + parseInt(output[8]) + parseInt(output[9])
                if (cpu.prevIdle != 0 && cpu.prevTotal != 0) {
                    var totald = idle + nonIdle - cpu.prevTotal
                    var idled = idle - cpu.prevIdle
                    var cpu_percent = (totald - idled) * 100 / totald
                    cpu.cpu_usage = Math.round(cpu_percent)
                }
                cpu.prevIdle = idle
                cpu.prevTotal = idle + nonIdle
            }
        }
    }
    
    Process {
        id: fetch_cpu_temp

        running: true
        command: ["sh", "-c", "cat '/sys/class/hwmon/hwmon5/temp1_input'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = text.trim()
                cpu.cpu_temp = Math.round(parseInt(output) / 1000)
            }
        }
    }

    Timer {
        id: delay

        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            fetch_cpu_usage.running = true
            fetch_cpu_temp.running = true
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