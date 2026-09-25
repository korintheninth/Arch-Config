import QtQuick
import "../../components"
import "../../themes"

Rectangle {
    id: chip
    property string label: ""
    property bool selected: false
    readonly property var s: Styles.wallpaperGallery.chip
    signal clicked()

    implicitHeight: s.height
    implicitWidth: labelText.implicitWidth + s.horizontalPadding * 2
    radius: s.radius
    color: selected
        ? s.selectedColor
        : (mouse.containsMouse ? s.hoverColor : s.normalColor)
    border.width: s.border.width
    border.color: s.border.color

    BetterText {
        id: labelText
        anchors.centerIn: parent
        text: chip.label
        color: chip.selected ? chip.s.text.selectedColor : chip.s.text.color
        font.family: chip.s.text.font.family
        font.pixelSize: chip.s.text.font.pixelSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
