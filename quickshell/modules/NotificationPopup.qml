import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "../components"
import "../themes"
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
        const s = Styles.notification.urgency
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
        return Math.min(t * 1000, 10000)
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
                    color: Styles.notification.color
                    radius: Styles.notification.radius
                    clip: radius > 0
                    border.width: Styles.notification.border.width
                    border.color: Styles.notification.border.color
                    implicitHeight: toastBody.implicitHeight
                        + Styles.notification.padding.top
                        + Styles.notification.padding.bottom

                    Rectangle {
                        width: Styles.notification.accentWidth
                        height: parent.height - 8
                        anchors.left: parent.left
                        anchors.leftMargin: Styles.notification.accentLeftMargin
                        anchors.verticalCenter: parent.verticalCenter
                        color: notificationPopup.urgencyAccent(modelData.urgency)
                    }

                    BetterText {
                        id: dismissBtn
                        text: "×"
                        z: 1
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: Styles.notification.dismiss.topMargin
                        anchors.rightMargin: Styles.notification.dismiss.rightMargin
                        property bool hovered: false
                        property color normalColor: Styles.notification.dismiss.normalColor
                        property color hoverColor: Styles.notification.dismiss.hoverColor
                        color: hovered ? hoverColor : normalColor
                        font.family: Styles.notification.dismiss.font.family
                        font.pixelSize: Styles.notification.dismiss.font.pixelSize

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
                        anchors.topMargin: Styles.notification.padding.top
                        anchors.leftMargin: Styles.notification.padding.left
                        anchors.rightMargin: Styles.notification.padding.right
                        spacing: 2

                        BetterText {
                            id: toastAppName
                            width: parent.width
                            text: modelData.appName || "Unknown"
                            elide: Text.ElideRight
                            color: Styles.notification.appName.color
                            font.family: Styles.notification.appName.font.family
                            font.pixelSize: Styles.notification.appName.font.pixelSize
                        }
                        BetterText {
                            id: toastSummary
                            width: parent.width
                            text: modelData.summary
                            elide: Text.ElideRight
                            color: Styles.notification.summary.color
                            font.family: Styles.notification.summary.font.family
                            font.bold: Styles.notification.summary.font.bold
                        }
                        BetterText {
                            id: toastBodyText
                            width: parent.width
                            text: notificationPopup.truncate(modelData.body, 120)
                            elide: Text.ElideRight
                            visible: modelData.body.length > 0
                            color: faded(Styles.notification.body.color, Styles.notification.body.opacity)
                            font.family: Styles.notification.body.font.family
                            font.pixelSize: Styles.pixelSize
                        }

                        Row {
                            id: actionsRow
                            width: parent.width
                            visible: modelData.actions.length > 0
                            spacing: Styles.notification.actionsRow.spacing

                            Repeater {
                                model: modelData.actions

                                delegate: Rectangle {
                                    id: toastAction
                                    required property var modelData
                                    property bool hovered: false
                                    property color normalColor: Styles.notification.action.normalColor
                                    property color hoverColor: Styles.notification.action.hoverColor
                                    property int horizontalPadding: Styles.notification.action.horizontalPadding
                                    color: hovered ? hoverColor : normalColor
                                    height: Styles.notification.action.height
                                    border.width: Styles.notification.action.border.width
                                    border.color: Styles.notification.action.border.color
                                    width: actionLabel.paintedWidth + 2 * horizontalPadding

                                    BetterText {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: parent.modelData.text
                                        property color normalColor: Styles.notification.action.text.normalColor
                                        property color hoverColor: Styles.notification.action.text.hoverColor
                                        color: parent.hovered ? hoverColor : normalColor
                                        font.family: Styles.notification.action.text.font.family
                                        font.pixelSize: Styles.notification.action.text.font.pixelSize
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: parent.hovered = true
                                        onExited: parent.hovered = false
                                        onClicked: parent.modelData.invoke()
                                    }
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
                }
            }
        }
    }
}
