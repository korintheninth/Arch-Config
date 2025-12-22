import QtQuick
import Quickshell

Rectangle {
    id: clockWidget
    
    anchors.verticalCenter: parent.verticalCenter
    radius: 10
    color: "lightgray"
    
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: clock_display
        font.family: root.defaultFontFamily
        font.pointSize: 12
        text: Qt.formatDateTime(clock.date, "MMMM dd hh:mm")
        anchors.centerIn: parent
        color: "black"
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            console.log("AAAAAAA")
        }
    }
    implicitWidth: clock_display.paintedWidth + 20
}