import QtQuick
import Quickshell
import "../themes"
import "../themes/StyleEngine.js" as Styler
import "../components"

Rectangle {
    id: clockWidget
    
    anchors.verticalCenter: parent.verticalCenter

    property alias text: clock_display
    
    Component.onCompleted: {
        Styler.apply(clockWidget, Styles.clock)
        Styler.apply(clock_display, Styles.clock.text)
    }
    
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    BetterText {
        id: clock_display
        text: Qt.formatDateTime(clock.date, "dddd MMMM dd  hh:mm")
        anchors.centerIn: parent
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