import QtQuick
import Quickshell
import "../themes"
import "../components"
import "../services"

Rectangle {
    id: clockWidget

    anchors.verticalCenter: parent.verticalCenter
    color: Styles.clock.color
    radius: Styles.clock.radius

    property alias text: clock_display
    readonly property bool hasNotifications: NotificationService.list.values.length > 0
    readonly property int indicatorSize: Styles.clock.indicator.size
    readonly property int indicatorSpacing: Styles.clock.indicator.spacing

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    BetterText {
        id: clock_display
        text: Qt.formatDateTime(clock.date, "dddd MMMM dd  hh:mm")
        anchors.centerIn: parent
        color: Styles.clock.text.color
        font.family: Styles.clock.text.font.family
        font.bold: Styles.clock.text.font.bold
    }

    Rectangle {
        id: notifDot
        visible: clockWidget.hasNotifications
        width: clockWidget.indicatorSize
        height: clockWidget.indicatorSize
        implicitWidth: width
        implicitHeight: height
        radius: width / 2
        color: Styles.clock.indicator.color
        anchors.left: clock_display.right
        anchors.leftMargin: clockWidget.indicatorSpacing
        anchors.verticalCenter: clock_display.verticalCenter
    }

    implicitWidth: clock_display.paintedWidth + 20

    CenterMenu {
        id: menu
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: {
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                menu.anchorTarget = clockWidget
                menu.open = true
            }
        }
    }
}
