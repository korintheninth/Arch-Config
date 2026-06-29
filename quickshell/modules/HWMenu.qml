import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Controls
import Quickshell.Services.UPower
import "../components"
import "../themes"
import "../themes/StyleEngine.js" as Styler

PopupWindow {
    id: hwmenu
    color: "transparent"
    implicitHeight: column.height + 10
    implicitWidth: column.width + 10
    
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
    property int selectedMode: PowerProfiles.profile
    property var cpuProcesses: []
    property var memProcesses: []

    function applyProcessRowStyles(row, nameText, pidText, usageText) {
        Styler.apply(row, Styles.hwMenu.bars.processes.row)
        Styler.apply(nameText, Styles.hwMenu.bars.processes.row.name)
        Styler.apply(pidText, Styles.hwMenu.bars.processes.row.pid)
        Styler.apply(usageText, Styles.hwMenu.bars.processes.row.usage)
    }

    function applyPowerButtonStyles(label, icon) {
        Styler.apply(label, Styles.hwMenu.powerProfiles.buttonRow.button.text)
        Styler.apply(icon, Styles.hwMenu.powerProfiles.buttonRow.button.icon)
    }

    Component.onCompleted: {
        Styler.apply(hwmenu, Styles.hwMenu)
        Styler.apply(tempRow, Styles.hwMenu.temps.text)
        Styler.apply(temps, Styles.hwMenu.temps)
        Styler.apply(diskText, Styles.hwMenu.bars.text)
        Styler.apply(diskBar, Styles.hwMenu.bars.bar)
        Styler.apply(disk, Styles.hwMenu.bars)
        Styler.apply(gpuText, Styles.hwMenu.bars.text)
        Styler.apply(gpuBar, Styles.hwMenu.bars.bar)
        Styler.apply(gpu, Styles.hwMenu.bars)
        Styler.apply(cpuText, Styles.hwMenu.bars.text)
        Styler.apply(cpuBar, Styles.hwMenu.bars.bar)
        Styler.apply(cpuProcessList, Styles.hwMenu.bars.processes.list)
        Styler.apply(cpu, Styles.hwMenu.bars)
        cpu.height = Styles.hwMenu.bars.withProcessesHeight
        Styler.apply(memText, Styles.hwMenu.bars.text)
        Styler.apply(memBar, Styles.hwMenu.bars.bar)
        Styler.apply(memProcessList, Styles.hwMenu.bars.processes.list)
        Styler.apply(mem, Styles.hwMenu.bars)
        mem.height = Styles.hwMenu.bars.withProcessesHeight
        Styler.apply(powerProfiles, Styles.hwMenu.powerProfiles)
        Styler.apply(powerLabel, Styles.hwMenu.powerProfiles.text)
        Styler.apply(buttonRow, Styles.hwMenu.powerProfiles.buttonRow)
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
                pid: parseInt(parts[1]),
                usage: parseFloat(parts[2])
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
        color: "transparent"
        anchors.fill: parent

        transform: Rotation {
            id: xAxisRotation
            origin.x: content.width / 2
            axis { x: 1; y: 0; z: 0 } 
            angle: -90 
        }

        NumberAnimation {
            id: openAnim
            target: xAxisRotation
            property: "angle"
            from: -90
            to: 0
            duration: 300
            
            easing.type: Easing.OutBack

            onFinished: {
                if (!hwmenu.open)
                    hwmenu.visible = false
            }
        }

        Connections {
            target: hwmenu
            function onOpenChanged() {
                if (hwmenu.open) {
                    xAxisRotation.angle = -90
                    openAnim.from = -90
                    openAnim.to = 0
                    openAnim.start()
                } else {
                    openAnim.from = xAxisRotation.angle
                    openAnim.to = -90
                    openAnim.start()
                }
            }
        }


        Column {
            id: column
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -5
            anchors.horizontalCenterOffset: 5
            Rectangle {
                id: temps

                function tempColor(temp) {
                    const s = Styles.hwMenu.temps
                    if (temp >= s.criticalThreshold)
                        return s.criticalColor
                    if (temp >= s.warningThreshold)
                        return s.warningColor
                    return s.baseColor
                }

                Row {
                    id: tempRow
                    anchors.top: parent.top
                    anchors.left: parent.left
                    spacing: 0

                    BetterText {
                        text: "Temps: CPU: "
                        color: Styles.hwMenu.temps.baseColor
                    }
                    BetterText {
                        text: hwmenu.cpuTemp + "°"
                        color: temps.tempColor(hwmenu.cpuTemp)
                    }
                    BetterText {
                        text: "  GPU: "
                        color: Styles.hwMenu.temps.baseColor
                    }
                    BetterText {
                        text: hwmenu.gpuTemp + "°"
                        color: temps.tempColor(hwmenu.gpuTemp)
                    }
                }
            }
            Rectangle {
                id: disk
                height: 60
                width: 350
                BetterText {
                    id: diskText
                    text: "Disk Usage:"
                    anchors.left: parent.left
                    anchors.top: parent.top
                }
                HorizontalStatusBar {
                    id: diskBar
                    height: 30
                    width: 300
                    val: hwmenu.diskUsage
                    text: hwmenu.diskUsage
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
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
                height: 60
                width: 350
                BetterText {
                    id: gpuText
                    text: "GPU Usage:"
                    anchors.left: parent.left
                    anchors.top: parent.top
                }
                HorizontalStatusBar {
                    id: gpuBar
                    height: 30
                    width: 300
                    val: hwmenu.gpuUsage
                    text: hwmenu.gpuUsage
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                }
            }
            Rectangle {
                id: cpu
                height: Styles.hwMenu.bars.withProcessesHeight

                width: 350
                BetterText {
                    id: cpuText
                    text: "CPU Usage:"
                    anchors.left: parent.left
                    anchors.top: parent.top
                }
                HorizontalStatusBar {
                    id: cpuBar
                    height: 30
                    width: 300
                    val: hwmenu.cpuUsage
                    text: hwmenu.cpuUsage
                    anchors.top: cpuText.bottom
                    anchors.left: parent.left
                }
                Column {
                    id: cpuProcessList
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: cpuBar.bottom
                    anchors.bottom: parent.bottom
                    width: parent.width
                    Repeater {
                        model: hwmenu.cpuProcesses
                        delegate: Item {
                            id: cpuProcessRow
                            width: cpuProcessList.width
                            BetterText {
                                id: cpuProcessName
                                text: modelData.name
                                width: parent.width * 0.4
                                elide: Text.ElideRight
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            BetterText {
                                id: cpuProcessPid
                                text: modelData.pid
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            BetterText {
                                id: cpuProcessUsage
                                text: modelData.usage + "%"
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Component.onCompleted: hwmenu.applyProcessRowStyles(
                                cpuProcessRow, cpuProcessName, cpuProcessPid, cpuProcessUsage)
                        }
                    }
                }
            }
            Rectangle {
                id: mem
                height: Styles.hwMenu.bars.withProcessesHeight
                width: 350
                BetterText {
                    id: memText
                    text: "Memory Usage:"
                    anchors.left: parent.left
                    anchors.top: parent.top
                }
                HorizontalStatusBar {
                    id: memBar
                    height: 30
                    width: 300
                    val: hwmenu.memUsage
                    text: hwmenu.memUsage
                    anchors.top: memText.bottom
                    anchors.left: parent.left
                }
                Column {
                    id: memProcessList
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: memBar.bottom
                    anchors.bottom: parent.bottom
                    width: parent.width
                    Repeater {
                        model: hwmenu.memProcesses
                        delegate: Item {
                            id: memProcessRow
                            width: memProcessList.width
                            BetterText {
                                id: memProcessName
                                text: modelData.name
                                width: parent.width * 0.4
                                elide: Text.ElideRight
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            BetterText {
                                id: memProcessPid
                                text: modelData.pid
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            BetterText {
                                id: memProcessUsage
                                text: Math.round(modelData.usage) + " MB"
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Component.onCompleted: hwmenu.applyProcessRowStyles(
                                memProcessRow, memProcessName, memProcessPid, memProcessUsage)
                        }
                    }
                }
            }
            Rectangle {
                id: powerProfiles
                height: 60
                width: 350
                BetterText {
                    id: powerLabel
                    text: "Power Mode:"
                    anchors.top: parent.top
                    anchors.left: parent.left
                }
                Row {
                    id: buttonRow
                    property var icons: ["", "", ""]
                    property int buttonWidth: 100
                    property int buttonHeight: 30
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
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
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            background: Rectangle {
                                id: icon
                                property color checkedColor: "black"
                                property color normalColor: "white"
                                color: checked ? checkedColor : normalColor
                                anchors.fill: parent
                            }

                            Component.onCompleted: hwmenu.applyPowerButtonStyles(label, icon)
                        }
                    }
                }
            }
        }
    }
}