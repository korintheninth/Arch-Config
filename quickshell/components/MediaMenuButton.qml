import QtQuick
import QtQuick.Controls

Button {
    id: btn

    property string iconType: "play"
    property int buttonSize: 50
    property real buttonRadius: 25
    property color normalColor: "#1a1a1a"
    property color hoverColor: "#e5e0cc"
    property color pressedColor: "#599d8b"
    property color iconColor: "#e5e0cc"
    property color iconHoverColor: "#599d8b"
    property color iconPressedColor: "#e5e0cc"
    property int iconSize: 16

    readonly property color fillColor: btn.pressed
        ? btn.pressedColor
        : btn.hovered ? btn.hoverColor : btn.normalColor
    readonly property color glyphColor: btn.pressed
        ? btn.iconPressedColor
        : btn.hovered ? btn.iconHoverColor : btn.iconColor

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    padding: 0
    hoverEnabled: true

    background: Rectangle {
        anchors.fill: parent
        radius: btn.buttonRadius
        color: btn.fillColor
    }

    contentItem: MediaControlIcon {
        anchors.centerIn: parent
        size: btn.iconSize
        iconType: btn.iconType
        color: btn.glyphColor
    }
}
