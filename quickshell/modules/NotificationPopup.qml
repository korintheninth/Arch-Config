import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "../components"
import "../themes"
import "../themes/StyleEngine.js" as Styler
import "../services"

Scope {
    id: notificationPopup
    readonly property int toastWidth: 320
    readonly property var focusedScreen: Quickshell.screens.find(
        s => s.name === Hyprland.focusedMonitor?.name
    ) ?? Quickshell.screens[0]

    function truncate(str, max) {
        if (!str || max <= 0)
            return str ?? ""
        return str.length > max ? str.slice(0, max - 1) + "…" : str
    }

    function urgencyAccent(urgency) {
        const s = Styles.centerMenu.notifications.item.urgency
        if (urgency === NotificationUrgency.Critical)
            return s.critical
        return s.normal
    }

    function popupTimeoutMs(notification) {
        const t = notification.expireTimeout
        if (t === 0)
            return -1
        if (t < 0)
            return 5000
        return t * 1000
    }

    function applyNotificationItemStyles(item, dismissBtn, actionsRow, appName, summary, body) {
        Styler.apply(item, Styles.centerMenu.notifications.item)
        Styler.apply(dismissBtn, Styles.centerMenu.notifications.item.dismiss)
        Styler.apply(appName, Styles.centerMenu.notifications.item.appName)
        Styler.apply(summary, Styles.centerMenu.notifications.item.summary)
        Styler.apply(body, Styles.centerMenu.notifications.item.body)
        if (actionsRow)
            Styler.apply(actionsRow, Styles.centerMenu.notifications.item.actionsRow)
    }

    function applyNotificationActionStyles(action, actionLabel) {
        Styler.apply(action, Styles.centerMenu.notifications.item.action)
        Styler.apply(actionLabel, Styles.centerMenu.notifications.item.action.text)
    }

    PanelWindow {
        id: popupLayer

        screen: notificationPopup.focusedScreen
        anchors.top: true
        anchors.right: true
        margins.top: Styles.topbar.implicitHeight + 8
        margins.right: 8
        color: "transparent"
        implicitWidth: toastColumn.width
        implicitHeight: toastColumn.height

        Column {
            id: toastColumn
            spacing: 6

            Repeater {
                model: NotificationService.popups

                delegate: Rectangle {
                    id: toastItem
                    required property var modelData
                    width: notificationPopup.toastWidth
                    implicitHeight: toastBody.implicitHeight
                        + Styles.centerMenu.notifications.item.padding.top
                        + Styles.centerMenu.notifications.item.padding.bottom

                    Rectangle {
                        width: Styles.centerMenu.notifications.item.accentWidth
                        height: parent.height - 8
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: notificationPopup.urgencyAccent(modelData.urgency)
                    }

                    BetterText {
                        id: dismissBtn
                        text: "×"
                        z: 1
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 2
                        anchors.rightMargin: 4
                        property bool hovered: false
                        property color normalColor: "transparent"
                        property color hoverColor: "transparent"
                        color: hovered ? hoverColor : normalColor

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: dismissBtn.hovered = true
                            onExited: dismissBtn.hovered = false
                            onClicked: modelData.dismiss()
                        }
                    }

                    Column {
                        id: toastBody
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: Styles.centerMenu.notifications.item.padding.top
                        anchors.leftMargin: Styles.centerMenu.notifications.item.padding.left
                        anchors.rightMargin: Styles.centerMenu.notifications.item.padding.right
                        spacing: 2

                        BetterText {
                            id: toastAppName
                            width: parent.width
                            text: modelData.appName || "Unknown"
                            elide: Text.ElideRight
                        }
                        BetterText {
                            id: toastSummary
                            width: parent.width
                            text: modelData.summary
                            elide: Text.ElideRight
                        }
                        BetterText {
                            id: toastBodyText
                            width: parent.width
                            text: notificationPopup.truncate(modelData.body, 120)
                            elide: Text.ElideRight
                            visible: modelData.body.length > 0
                        }

                        Row {
                            id: actionsRow
                            width: parent.width
                            visible: modelData.actions.length > 0

                            Repeater {
                                model: modelData.actions

                                delegate: Rectangle {
                                    id: toastAction
                                    required property var modelData
                                    property bool hovered: false
                                    property color normalColor: "transparent"
                                    property color hoverColor: "transparent"
                                    property int horizontalPadding: 0
                                    color: hovered ? hoverColor : normalColor
                                    width: actionLabel.paintedWidth + 2 * horizontalPadding

                                    BetterText {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: parent.modelData.text
                                        property color normalColor: "transparent"
                                        property color hoverColor: "transparent"
                                        color: parent.hovered ? hoverColor : normalColor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: parent.hovered = true
                                        onExited: parent.hovered = false
                                        onClicked: parent.modelData.invoke()
                                    }

                                    Component.onCompleted: notificationPopup.applyNotificationActionStyles(
                                        toastAction, actionLabel)
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: modelData.dismiss()
                    }

                    Timer {
                        running: notificationPopup.popupTimeoutMs(modelData) > 0
                        interval: Math.max(notificationPopup.popupTimeoutMs(modelData), 1)
                        repeat: false
                        onTriggered: NotificationService.hidePopup(modelData)
                    }

                    Connections {
                        target: modelData
                        function onClosed() {
                            NotificationService.hidePopup(modelData)
                        }
                    }

                    Component.onCompleted: notificationPopup.applyNotificationItemStyles(
                        toastItem, dismissBtn, actionsRow,
                        toastAppName, toastSummary, toastBodyText)
                }
            }
        }
    }
}
