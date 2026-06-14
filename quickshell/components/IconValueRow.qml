import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property alias iconLabel: iconLabel
    property alias valueLabel: valueLabel
    property int spacing: 4

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: root.spacing

        BetterText {
            id: iconLabel
            Layout.alignment: Qt.AlignVCenter
        }

        BetterText {
            id: valueLabel
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
