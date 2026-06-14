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


    Component.onCompleted: Styler.apply(hwmenu, Styles.hwMenu)

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


    Timer {
        id: timer
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            fetch_cpu_temp.running = true
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
                    Component.onCompleted: Styler.apply(tempRow, Styles.hwMenu.temps.text)

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
                Component.onCompleted: Styler.apply(temps, Styles.hwMenu.temps)
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
                    Component.onCompleted: Styler.apply(diskText, Styles.hwMenu.bars.text)
                }
                HorizontalStatusBar {
                    id: diskBar
                    height: 30
                    width: 300
                    val: hwmenu.diskUsage
                    text: hwmenu.diskUsage
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    Component.onCompleted: Styler.apply(diskBar, Styles.hwMenu.bars.bar)
                }

                Component.onCompleted: Styler.apply(disk, Styles.hwMenu.bars)

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
                    Component.onCompleted: Styler.apply(gpuText, Styles.hwMenu.bars.text)
                }
                HorizontalStatusBar {
                    id: gpuBar
                    height: 30
                    width: 300
                    val: hwmenu.gpuUsage
                    text: hwmenu.gpuUsage
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    Component.onCompleted: Styler.apply(gpuBar, Styles.hwMenu.bars.bar)
                }
                Component.onCompleted: Styler.apply(gpu, Styles.hwMenu.bars)
            }
            Rectangle {
                id: cpu
                height: 60
                width: 350
                BetterText {
                    id: cpuText
                    text: "CPU Usage:"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    Component.onCompleted: Styler.apply(cpuText, Styles.hwMenu.bars.text)
                }
                HorizontalStatusBar {
                    id: cpuBar
                    height: 30
                    width: 300
                    val: hwmenu.cpuUsage
                    text: hwmenu.cpuUsage
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    Component.onCompleted: Styler.apply(cpuBar, Styles.hwMenu.bars.bar)
                }
                Component.onCompleted: Styler.apply(cpu, Styles.hwMenu.bars)
            }
            Rectangle {
                id: mem
                height: 60
                width: 350
                BetterText {
                    id: memText
                    text: "Memory Usage:"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    Component.onCompleted: Styler.apply(memText, Styles.hwMenu.bars.text)
                }
                HorizontalStatusBar {
                    id: memBar
                    height: 30
                    width: 300
                    val: hwmenu.memUsage
                    text: hwmenu.memUsage
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    Component.onCompleted: Styler.apply(memBar, Styles.hwMenu.bars.bar)
                }
                Component.onCompleted: Styler.apply(mem, Styles.hwMenu.bars)
            }
            Rectangle {
                id: powerProfiles
                height: 60
                width: 350
                Component.onCompleted: Styler.apply(powerProfiles, Styles.hwMenu.powerProfiles)
                BetterText {
                    id: powerLabel
                    text: "Power Mode:"
                    anchors.top: parent.top
                    anchors.left: parent.left

                    Component.onCompleted: Styler.apply(powerLabel, Styles.hwMenu.powerProfiles.text)
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
                    Component.onCompleted: Styler.apply(buttonRow, Styles.hwMenu.powerProfiles.buttonRow)
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
                                Component.onCompleted: Styler.apply(label, Styles.hwMenu.powerProfiles.buttonRow.button.text)
                            }
                            background: Rectangle {
                                id: icon
                                property color checkedColor: "black"
                                property color normalColor: "white"
                                color: checked ? checkedColor : normalColor
                                anchors.fill: parent
                                Component.onCompleted: Styler.apply(icon, Styles.hwMenu.powerProfiles.buttonRow.button.icon)
                            }
                        }
                    }
                }
            }
        }
    }
}