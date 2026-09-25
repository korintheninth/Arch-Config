import QtQuick
import "../../components"
import "../../themes"

Rectangle {
    id: btn

    property string label: ""
    property bool selected: false
    readonly property var s: Styles.wallpaperGallery.button
    signal clicked()

    implicitHeight: s.height
    implicitWidth: labelText.implicitWidth + 16
    radius: s.radius
    color: {
        if (mouse.pressed)
            return s.pressedColor
        if (selected)
            return Styles.wallpaperGallery.chip.selectedColor
        return mouse.containsMouse ? s.hoverColor : s.normalColor
    }
    border.width: s.border.width
    border.color: s.border.color

    BetterText {
        id: labelText
        anchors.centerIn: parent
        text: btn.label
        color: mouse.pressed || btn.selected ? btn.s.text.pressedColor : btn.s.text.color
        font.family: btn.s.text.font.family
        font.pixelSize: btn.s.text.font.pixelSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
