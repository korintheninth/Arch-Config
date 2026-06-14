import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../themes"
import "../themes/StyleEngine.js" as Styler
import "../components"

Row {
    id: systray

    property int barHeight: 0

    readonly property var style: Styles.systray
    readonly property int iconWidth: {
        const themed = style.iconWidth ?? style.iconSize ?? 20
        return barHeight > 0 ? Math.min(themed, barHeight) : themed
    }
    readonly property int iconHeight: {
        const themed = style.iconHeight ?? style.iconSize ?? 20
        return barHeight > 0 ? Math.min(themed, barHeight) : themed
    }
    height: barHeight > 0 ? barHeight : childrenRect.height

    Component.onCompleted: Styler.apply(systray, Styles.systray)

    StyledTrayMenu {
        id: trayMenu
    }

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayDelegate
            required property SystemTrayItem modelData

            readonly property string tooltipText: {
                const title = modelData.tooltipTitle || modelData.title
                return modelData.tooltipDescription ? title + "\n" + modelData.tooltipDescription : title
            }

            width: systray.iconWidth
            height: systray.height

            IconImage {
                id: trayIcon
                anchors.centerIn: parent
                source: trayDelegate.modelData.icon
                implicitSize: systray.iconWidth
            }

            MouseArea {
                id: mouseArea
                anchors.fill: trayIcon
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                
                function openTrayMenu() {
                    trayMenu.trayItem = trayDelegate.modelData
                    trayMenu.anchorTarget = trayIcon
                    trayMenu.open = true
                }
                
                onClicked: (mouse) => {
                    const item = trayDelegate.modelData
                    if (mouse.button === Qt.LeftButton) {
                        if (item.onlyMenu) {
                            if (item.hasMenu)
                                openTrayMenu()
                        } else {
                            item.activate()
                        }
                    } else if (mouse.button === Qt.MiddleButton) {
                        item.secondaryActivate()
                    } else if (mouse.button === Qt.RightButton && item.hasMenu) {
                        openTrayMenu()
                    }
                }

                onWheel: (wheel) => {
                    const steps = wheel.angleDelta.y / 120
                    trayDelegate.modelData.scroll(steps, false)
                }
            }

            StyledToolTip {
                anchorTarget: trayIcon
                styleOverride: systray.style.tooltip
                text: trayDelegate.tooltipText
                show: mouseArea.containsMouse && !mouseArea.pressed
            }
        }
    }
}
