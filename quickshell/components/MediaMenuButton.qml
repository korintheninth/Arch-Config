import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../themes"

Button {
    id: btn

    property string iconType: "play"
    property int size: Styles.mediaMenu.button.size
    property real radius: Styles.mediaMenu.button.radius
    property color normalColor: Styles.mediaMenu.button.normalColor
    property color hoverColor: Styles.mediaMenu.button.hoverColor
    property color pressedColor: Styles.mediaMenu.button.pressedColor
    property color iconColor: Styles.mediaMenu.button.iconColor
    property color iconHoverColor: Styles.mediaMenu.button.iconHoverColor
    property color iconPressedColor: Styles.mediaMenu.button.iconPressedColor
    property int iconSize: Styles.mediaMenu.button.iconSize
    property var shadow: Styles.mediaMenu.button.shadow

    readonly property color fillColor: btn.pressed
        ? btn.pressedColor
        : btn.hovered ? btn.hoverColor : btn.normalColor
    readonly property color glyphColor: btn.pressed
        ? btn.iconPressedColor
        : btn.hovered ? btn.iconHoverColor : btn.iconColor

    implicitWidth: size
    implicitHeight: size
    padding: 0
    hoverEnabled: true

    layer.enabled: true
    layer.smooth: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: btn.shadow.color
        shadowOpacity: btn.shadow.opacity
        shadowBlur: btn.shadow.blur
        shadowHorizontalOffset: btn.shadow.horizontalOffset
        shadowVerticalOffset: btn.pressed
            ? btn.shadow.pressedVerticalOffset
            : btn.shadow.verticalOffset
    }

    background: Rectangle {
        anchors.fill: parent
        radius: btn.radius
        color: btn.fillColor
    }

    contentItem: MediaControlIcon {
        anchors.centerIn: parent
        size: btn.iconSize
        iconType: btn.iconType
        color: btn.glyphColor
    }
}
