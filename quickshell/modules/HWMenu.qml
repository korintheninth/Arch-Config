import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Controls
import Quickshell.Services.UPower
import "../components"
import "../themes"

PopupWindow {
    id: hwmenu
    color: "transparent"
    readonly property int surfacePad: 2
    implicitHeight: column.height + 2 * Styles.hwMenu.padding + 2 * surfacePad
    implicitWidth: column.width + 2 * Styles.hwMenu.padding + 2 * surfacePad
    
    property bool open: false

    HyprlandFocusGrab {
        active: hwmenu.open
        windows: [hwmenu]
        onCleared: hwmenu.open = false
    }

    onVisibleChanged: {
        if (!visible)
            open = false
    }

    property Item anchorTarget: null
    anchor.item: anchorTarget
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 18
    onOpenChanged: {
        if (open) {
            visible = true
            anchor.updateAnchor()
        }
    }

    property double cpuUsage: 0
    property double gpuUsage: 0
    property double memUsage: 0
    property double diskUsage: 0
    property double cpuTemp: 0
    property double gpuTemp: 0
    property var cpuHistory: []
    property var gpuHistory: []
    property var memHistory: []
    property int selectedMode: PowerProfiles.profile
    property var cpuProcesses: []
    property var memProcesses: []
    property string fanMode: "auto"

    function tempColor(temp) {
        const s = Styles.hwMenu.temps
        if (temp >= s.criticalThreshold)
            return s.criticalColor
        if (temp >= s.warningThreshold)
            return s.warningColor
        return s.baseColor
    }

    function setFanMode(mode) {
        fanMode = mode
        if (mode === "auto")
            Quickshell.execDetached(["nbfc", "set", "-a"])
        else
            Quickshell.execDetached(["nbfc", "set", "-s", mode])
    }

    function checkFanSafety() {
        if (fanMode !== "0")
            return
        const limit = Styles.hwMenu.fanControl.autoSwitchThreshold
        if (cpuTemp >= limit || gpuTemp >= limit)
            setFanMode("auto")
    }

    onCpuTempChanged: checkFanSafety()
    onGpuTempChanged: checkFanSafety()

    Process {
        id: fetch_nbfc_status

        running: true
        command: ["nbfc", "status", "-a"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (/Auto Control Enabled\s*:\s*(true|yes)/i.test(text)) {
                    hwmenu.fanMode = "auto"
                    return
                }
                var speedMatch = text.match(/Target Fan Speed\s*:\s*([0-9.]+)/i)
                if (!speedMatch)
                    return
                var speed = parseFloat(speedMatch[1])
                if (speed <= 0.5)
                    hwmenu.fanMode = "0"
                else if (speed >= 99.5)
                    hwmenu.fanMode = "100"
                hwmenu.checkFanSafety()
            }
        }
    }

    Process {
        id: fetch_cpu_temp

        running: true
        command: ["cat","/sys/class/hwmon/hwmon5/temp1_input"]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = text.trim()
                hwmenu.cpuTemp = Math.round(parseInt(output) / 1000)
            }
        }
    }

    Process {
        id: fetch_top_processes

        running: true
        command: [
            "python",
            Quickshell.shellPath("Scripts/systemusage.py")
        ]
        
        function parseLine(line) {
            var parts = line.split(" ")
            return {
                name: parts[0],
                usage: parseFloat(parts[1])
            }
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                hwmenu.cpuProcesses = lines.slice(0, 3).map(fetch_top_processes.parseLine)
                hwmenu.memProcesses = lines.slice(3, 6).map(fetch_top_processes.parseLine)
            }
        }
    }

    Timer {
        id: timer
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            fetch_cpu_temp.running = true
            fetch_top_processes.running = true
        }
    }

    Rectangle {
        id: content
        x: hwmenu.surfacePad
        y: -height
        width: parent.width - 2 * hwmenu.surfacePad
        height: parent.height - 2 * hwmenu.surfacePad
        color: Styles.hwMenu.background.color
        radius: Styles.hwMenu.background.radius
        border.width: Styles.hwMenu.background.border.width
        border.color: Styles.hwMenu.background.border.color
        clip: radius > 0

        NumberAnimation {
            id: openAnim
            target: content
            property: "y"
            from: -content.height
            to: hwmenu.surfacePad
            duration: 300
            easing.type: Easing.OutQuart

            onFinished: {
                if (!hwmenu.open)
                    hwmenu.visible = false
            }
        }

        Connections {
            target: hwmenu
            function onOpenChanged() {
                if (hwmenu.open) {
                    content.y = -content.height
                    openAnim.from = -content.height
                    openAnim.to = hwmenu.surfacePad
                    openAnim.start()
                } else {
                    openAnim.from = content.y
                    openAnim.to = -content.height
                    openAnim.start()
                }
            }
        }


        Column {
            id: column
            anchors.centerIn: parent
            spacing: Styles.hwMenu.spacing
            Rectangle {
                id: disk
                height: Styles.hwMenu.disk.height
                width: Styles.hwMenu.section.width
                color: Styles.hwMenu.section.color
                radius: Styles.hwMenu.disk.radius
                clip: radius > 0
                border.width: Styles.hwMenu.section.border.width
                border.color: Styles.hwMenu.section.border.color
                BetterText {
                    id: diskText
                    text: "Disk"
                    color: Styles.hwMenu.section.header.color
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: Styles.hwMenu.section.header.anchors.topMargin
                    anchors.leftMargin: Styles.hwMenu.section.header.anchors.leftMargin
                }
                HorizontalStatusBar {
                    id: diskBar
                    height: Styles.hwMenu.bar.height
                    width: Styles.hwMenu.bar.width
                    leftMargin: Styles.hwMenu.bar.leftMargin
                    radius: Styles.hwMenu.bar.radius
                    color: Styles.hwMenu.bar.color
                    barColor: Styles.hwMenu.bar.barColor
                    label.color: Styles.hwMenu.bar.label.color
                    val: hwmenu.diskUsage
                    text: hwmenu.diskUsage
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.bottomMargin: Styles.hwMenu.bar.anchors.bottomMargin
                    anchors.leftMargin: Styles.hwMenu.bar.anchors.leftMargin
                    anchors.topMargin: Styles.hwMenu.bar.anchors.topMargin
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onEntered: {
                    }
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            Quickshell.execDetached(["baobab"])
                    }
                }
            }
            Rectangle {
                id: gpu
                height: Styles.hwMenu.gpu.height
                width: Styles.hwMenu.section.width
                color: Styles.hwMenu.section.color
                radius: Styles.hwMenu.gpu.radius
                clip: radius > 0
                border.width: Styles.hwMenu.section.border.width
                border.color: Styles.hwMenu.section.border.color
                Row {
                    id: gpuHeader
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: Styles.hwMenu.section.header.anchors.topMargin
                    anchors.leftMargin: Styles.hwMenu.section.header.anchors.leftMargin
                    spacing: Styles.hwMenu.section.header.spacing

                    BetterText {
                        id: gpuText
                        text: "GPU"
                        color: Styles.hwMenu.section.header.color
                    }
                    BetterText {
                        id: gpuTempText
                        text: hwmenu.gpuTemp + "°"
                        color: hwmenu.tempColor(hwmenu.gpuTemp)
                    }
                }
                UsageGraph {
                    id: gpuGraph
                    height: Styles.hwMenu.graph.height
                    width: Styles.hwMenu.graph.width
                    leftMargin: Styles.hwMenu.graph.leftMargin
                    radius: Styles.hwMenu.graph.radius
                    color: Styles.hwMenu.graph.color
                    lineColor: Styles.hwMenu.graph.lineColor
                    fillColor: Styles.hwMenu.graph.fillColor
                    maxSamples: Styles.hwMenu.graph.maxSamples
                    label.color: Styles.hwMenu.graph.label.color
                    samples: hwmenu.gpuHistory
                    text: hwmenu.gpuUsage
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.bottomMargin: Styles.hwMenu.graph.anchors.bottomMargin
                    anchors.leftMargin: Styles.hwMenu.graph.anchors.leftMargin
                    anchors.topMargin: Styles.hwMenu.graph.anchors.topMargin
                }
            }
            Rectangle {
                id: cpu
                height: Styles.hwMenu.cpu.height
                width: Styles.hwMenu.section.width
                color: Styles.hwMenu.section.color
                radius: Styles.hwMenu.cpu.radius
                clip: radius > 0
                border.width: Styles.hwMenu.section.border.width
                border.color: Styles.hwMenu.section.border.color
                Row {
                    id: cpuHeader
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: Styles.hwMenu.section.header.anchors.topMargin
                    anchors.leftMargin: Styles.hwMenu.section.header.anchors.leftMargin
                    spacing: Styles.hwMenu.section.header.spacing

                    BetterText {
                        id: cpuText
                        text: "CPU"
                        color: Styles.hwMenu.section.header.color
                    }
                    BetterText {
                        id: cpuTempText
                        text: hwmenu.cpuTemp + "°"
                        color: hwmenu.tempColor(hwmenu.cpuTemp)
                    }
                }
                UsageGraph {
                    id: cpuGraph
                    height: Styles.hwMenu.graph.height
                    width: Styles.hwMenu.graph.width
                    leftMargin: Styles.hwMenu.graph.leftMargin
                    radius: Styles.hwMenu.graph.radius
                    color: Styles.hwMenu.graph.color
                    lineColor: Styles.hwMenu.graph.lineColor
                    fillColor: Styles.hwMenu.graph.fillColor
                    maxSamples: Styles.hwMenu.graph.maxSamples
                    label.color: Styles.hwMenu.graph.label.color
                    samples: hwmenu.cpuHistory
                    text: hwmenu.cpuUsage
                    anchors.top: cpuHeader.bottom
                    anchors.left: parent.left
                    anchors.bottomMargin: Styles.hwMenu.graph.anchors.bottomMargin
                    anchors.leftMargin: Styles.hwMenu.graph.anchors.leftMargin
                    anchors.topMargin: Styles.hwMenu.graph.anchors.topMargin
                }
                Column {
                    id: cpuProcessList
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: cpuGraph.bottom
                    anchors.bottom: parent.bottom
                    anchors.topMargin: Styles.hwMenu.processes.anchors.topMargin
                    anchors.leftMargin: Styles.hwMenu.processes.anchors.leftMargin
                    anchors.rightMargin: Styles.hwMenu.processes.anchors.rightMargin
                    anchors.bottomMargin: Styles.hwMenu.processes.anchors.bottomMargin
                    width: parent.width
                    Repeater {
                        model: hwmenu.cpuProcesses
                        delegate: Item {
                            id: cpuProcessRow
                            width: cpuProcessList.width
                            height: Styles.hwMenu.processes.row.height
                            BetterText {
                                id: cpuProcessName
                                text: modelData.name
                                color: Styles.hwMenu.processes.row.name.color
                                elide: Text.ElideRight
                                anchors.left: parent.left
                                anchors.right: cpuProcessUsage.left
                                anchors.rightMargin: Styles.hwMenu.processes.row.spacing
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            BetterText {
                                id: cpuProcessUsage
                                text: modelData.usage + "%"
                                color: Styles.hwMenu.processes.row.usage.color
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
            Rectangle {
                id: mem
                height: Styles.hwMenu.mem.height
                width: Styles.hwMenu.section.width
                color: Styles.hwMenu.section.color
                radius: Styles.hwMenu.mem.radius
                clip: radius > 0
                border.width: Styles.hwMenu.section.border.width
                border.color: Styles.hwMenu.section.border.color
                BetterText {
                    id: memText
                    text: "Memory"
                    color: Styles.hwMenu.section.header.color
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: Styles.hwMenu.section.header.anchors.topMargin
                    anchors.leftMargin: Styles.hwMenu.section.header.anchors.leftMargin
                }
                UsageGraph {
                    id: memGraph
                    height: Styles.hwMenu.graph.height
                    width: Styles.hwMenu.graph.width
                    leftMargin: Styles.hwMenu.graph.leftMargin
                    radius: Styles.hwMenu.graph.radius
                    color: Styles.hwMenu.graph.color
                    lineColor: Styles.hwMenu.graph.lineColor
                    fillColor: Styles.hwMenu.graph.fillColor
                    maxSamples: Styles.hwMenu.graph.maxSamples
                    label.color: Styles.hwMenu.graph.label.color
                    samples: hwmenu.memHistory
                    text: hwmenu.memUsage
                    anchors.top: memText.bottom
                    anchors.left: parent.left
                    anchors.bottomMargin: Styles.hwMenu.graph.anchors.bottomMargin
                    anchors.leftMargin: Styles.hwMenu.graph.anchors.leftMargin
                    anchors.topMargin: Styles.hwMenu.graph.anchors.topMargin
                }
                Column {
                    id: memProcessList
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: memGraph.bottom
                    anchors.bottom: parent.bottom
                    anchors.topMargin: Styles.hwMenu.processes.anchors.topMargin
                    anchors.leftMargin: Styles.hwMenu.processes.anchors.leftMargin
                    anchors.rightMargin: Styles.hwMenu.processes.anchors.rightMargin
                    anchors.bottomMargin: Styles.hwMenu.processes.anchors.bottomMargin
                    width: parent.width
                    Repeater {
                        model: hwmenu.memProcesses
                        delegate: Item {
                            id: memProcessRow
                            width: memProcessList.width
                            height: Styles.hwMenu.processes.row.height
                            BetterText {
                                id: memProcessName
                                text: modelData.name
                                color: Styles.hwMenu.processes.row.name.color
                                elide: Text.ElideRight
                                anchors.left: parent.left
                                anchors.right: memProcessUsage.left
                                anchors.rightMargin: Styles.hwMenu.processes.row.spacing
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            BetterText {
                                id: memProcessUsage
                                text: Math.round(modelData.usage) + " MB"
                                color: Styles.hwMenu.processes.row.usage.color
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
            Rectangle {
                id: powerProfiles
                height: Styles.hwMenu.powerProfiles.height
                width: Styles.hwMenu.section.width
                color: Styles.hwMenu.section.color
                radius: Styles.hwMenu.powerProfiles.radius
                clip: radius > 0
                border.width: Styles.hwMenu.section.border.width
                border.color: Styles.hwMenu.section.border.color
                Row {
                    id: buttonRow
                    property var icons: ["", "", ""]
                    property int buttonWidth: Styles.hwMenu.toggleButton.width
                    property int buttonHeight: Styles.hwMenu.toggleButton.height
                    height: buttonHeight
                    width: parent.width
                    anchors.centerIn: parent
                    property real gap: (powerProfiles.width - 3 * buttonWidth)/4
                    spacing: gap
                    leftPadding: gap
                    rightPadding: gap
                    Repeater {
                        model: ["Eco", "Balanced", "Power"]
                        delegate: Button {
                            implicitHeight: buttonRow.buttonHeight
                            implicitWidth: buttonRow.buttonWidth
                            padding: 0
                            checkable: true
                            checked: index === hwmenu.selectedMode
                            onClicked: PowerProfiles.profile = index
                            BetterText {
                                id: label
                                text: buttonRow.icons[index]
                                color: parent.checked
                                    ? Styles.hwMenu.powerProfiles.text.checkedColor
                                    : Styles.hwMenu.powerProfiles.text.normalColor
                                font.family: Styles.hwMenu.powerProfiles.text.font.family
                                font.pixelSize: Styles.hwMenu.powerProfiles.text.font.pixelSize
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            background: Rectangle {
                                color: checked
                                    ? Styles.hwMenu.toggleButton.background.checkedColor
                                    : Styles.hwMenu.toggleButton.background.normalColor
                                radius: Styles.hwMenu.toggleButton.background.radius
                                border.color: Styles.hwMenu.toggleButton.background.border.color
                                border.width: Styles.hwMenu.toggleButton.background.border.width
                                anchors.fill: parent
                            }
                        }
                    }
                }
            }
            Rectangle {
                id: fanControl
                height: Styles.hwMenu.fanControl.height
                width: Styles.hwMenu.section.width
                color: Styles.hwMenu.section.color
                radius: Styles.hwMenu.fanControl.radius
                clip: radius > 0
                border.width: Styles.hwMenu.section.border.width
                border.color: Styles.hwMenu.section.border.color
                Row {
                    id: fanButtonRow
                    property var labels: ["Auto", "0", "100"]
                    property var modes: ["auto", "0", "100"]
                    property int buttonWidth: Styles.hwMenu.toggleButton.width
                    property int buttonHeight: Styles.hwMenu.toggleButton.height
                    height: buttonHeight
                    width: parent.width
                    anchors.centerIn: parent
                    property real gap: (fanControl.width - 3 * buttonWidth)/4
                    spacing: gap
                    leftPadding: gap
                    rightPadding: gap
                    Repeater {
                        model: fanButtonRow.labels
                        delegate: Button {
                            implicitHeight: fanButtonRow.buttonHeight
                            implicitWidth: fanButtonRow.buttonWidth
                            padding: 0
                            checkable: true
                            checked: hwmenu.fanMode === fanButtonRow.modes[index]
                            onClicked: hwmenu.setFanMode(fanButtonRow.modes[index])
                            BetterText {
                                text: modelData
                                color: parent.checked
                                    ? Styles.hwMenu.fanControl.text.checkedColor
                                    : Styles.hwMenu.fanControl.text.normalColor
                                font.family: Styles.hwMenu.fanControl.text.font.family
                                font.pixelSize: Styles.hwMenu.fanControl.text.font.pixelSize
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            background: Rectangle {
                                color: checked
                                    ? Styles.hwMenu.toggleButton.background.checkedColor
                                    : Styles.hwMenu.toggleButton.background.normalColor
                                radius: Styles.hwMenu.toggleButton.background.radius
                                border.color: Styles.hwMenu.toggleButton.background.border.color
                                border.width: Styles.hwMenu.toggleButton.background.border.width
                                anchors.fill: parent
                            }
                        }
                    }
                }
            }
        }
    }
}