import QtQuick
import Quickshell
import Quickshell.Io
import "../themes"
import "../themes/StyleEngine.js" as Styler


Item {
    id: hwState

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: bars.implicitWidth

    Component.onCompleted: Styler.apply(bars, Styles.hwState)
    
    Row {
        id: bars
        height: parent.height

        property int barWidth: 5
        property int cpuUsage: 0
        property int memUsage: 0
        property int diskUsage: 0
        property int gpuUsage: 0
        property int gpuTemp: 0

        function barColor(usage) {
            const s = Styles.hwState
            if (usage >= s.criticalThreshold)
                return s.criticalColor
            if (usage >= s.warningThreshold)
                return s.warningColor
            return s.baseColor
        }

        anchors.verticalCenter: parent.verticalCenter

        
        Rectangle {
            id: disk
            width: bars.barWidth
            radius: Styles.hwState.radius
            color: bars.barColor(bars.diskUsage)
            height: bars.height * (Math.max(1, Math.min(bars.diskUsage, 100)) / 100)
            anchors.bottom: parent.bottom
        }
        Rectangle {
            id: gpu
            width: bars.barWidth
            radius: Styles.hwState.radius
            color: bars.barColor(bars.gpuUsage)
            height: bars.height * (Math.max(1, Math.min(bars.gpuUsage, 100)) / 100)
            anchors.bottom: parent.bottom
        }
        Rectangle {
            id: cpu
            width: bars.barWidth
            radius: Styles.hwState.radius
            color: bars.barColor(bars.cpuUsage)
            height: bars.height * (Math.max(1, Math.min(bars.cpuUsage, 100)) / 100)
            anchors.bottom: parent.bottom
        }
        Rectangle {
            id: memory
            width: bars.barWidth
            radius: Styles.hwState.radius
            color: bars.barColor(bars.memUsage)
            height: bars.height * (Math.max(1, Math.min(bars.memUsage, 100)) / 100)
            anchors.bottom: parent.bottom
        }
        
        function meminfoKiB(lines, key) {
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i]
                if (!line.startsWith(key))
                    continue
                var parts = line.trim().split(/\s+/)
                return parseInt(parts[1], 10)
            }
            return 0
        }
        
        Process {
            id: fetch_memory_usage

            running: true
            command: ["cat", "/proc/meminfo"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var output = text.split("\n")
                    var totalMem = bars.meminfoKiB(output, "MemTotal:")
                    var freeMem = bars.meminfoKiB(output, "MemAvailable:")
                    var usedMem = parseInt(totalMem) - parseInt(freeMem)
                    bars.memUsage = totalMem > 0
                        ? Math.round((usedMem / totalMem) * 100)
                        : 0
                }
            }
        }

        property real prevIdle : 0
        property real prevTotal: 0

        Process {
            id: fetch_cpu_usage

            running: true
            command: ["grep", "cpu", "/proc/stat"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var output = text.trim().split("\n")[0].split(" ")
                    var idle = parseInt(output[5]) + parseInt(output[6])
                    var nonIdle = parseInt(output[2]) + parseInt(output[3]) + parseInt(output[4]) + parseInt(output[7]) + parseInt(output[8]) + parseInt(output[9])
                    if (bars.prevIdle != 0 && bars.prevTotal != 0) {
                        var totald = idle + nonIdle - bars.prevTotal
                        var idled = idle - bars.prevIdle
                        var cpu_percent = (totald - idled) * 100 / totald
                        bars.cpuUsage = Math.round(cpu_percent)
                    }
                    bars.prevIdle = idle
                    bars.prevTotal = idle + nonIdle
                }
            }
        }

        Process {
            id: fetch_disk_usage

            running: true
            command: ["sh", "-c", "df -h /home | awk 'NR==2 {print $5}'"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var output = text.trim("%")
                    bars.diskUsage = parseInt(output)
                }
            }
        }

        Process {
            id: fetch_gpu_usage

            running: true
            command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var output = text.trim().split(", ")
                    bars.gpuUsage = parseInt(output[0]) || 0
                    bars.gpuTemp = parseInt(output[1]) || 0
                }
            }
        }
        
        Timer {
            id: delay

            running: true
            repeat: true
            interval: 2000
            onTriggered: {
                fetch_memory_usage.running = true
                fetch_cpu_usage.running = true
                fetch_gpu_usage.running = true
            }
        }
        
        Timer {
            id: diskDelay

            running: true
            repeat: true
            interval: 60000
            onTriggered: {
                fetch_disk_usage.running = true
            }
        }
    }
    
    HWMenu {
        id: menu
        cpuUsage: bars.cpuUsage
        gpuUsage: bars.gpuUsage
        gpuTemp: bars.gpuTemp
        memUsage: bars.memUsage
        diskUsage: bars.diskUsage
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: {
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["missioncenter"])
            } else if (mouse.button === Qt.RightButton) {
                menu.anchorTarget = hwState
                menu.open = true
            }
        }
    }
}