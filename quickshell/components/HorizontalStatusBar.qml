import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: statusBar
    property double max: 100.0
    property double min: 0.0
    property double val: 50.0
    property color barColor: "black"
    property string text: ""
    property int leftMargin: 0
    property alias label: label
    color: "white"

    Rectangle {
        id: bar
        height: statusBar.height
        width: parent.width * (statusBar.val - statusBar.min) / (statusBar.max - statusBar.min)
        color: statusBar.barColor
    }
    BetterText {
        id: label
        text: statusBar.text
        color: "white"
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: statusBar.leftMargin
    }
}