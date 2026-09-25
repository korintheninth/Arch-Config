import QtQuick
import QtQuick.Controls

Row {
    id: row
    property string label: ""
    property string valueText: ""
    property real from: 0
    property real to: 100
    property real syncedValue: 0
    property real stepSize: 0
    property int snapMode: Slider.NoSnap
    signal moved(real value)

    width: parent ? parent.width : implicitWidth
    spacing: 8

    GalleryLabel {
        width: 72
        anchors.verticalCenter: parent.verticalCenter
        role: "text"
        text: row.label
    }

    GallerySlider {
        width: Math.max(40, row.width - 120)
        from: row.from
        to: row.to
        stepSize: row.stepSize
        snapMode: row.snapMode
        syncedValue: row.syncedValue
        onMoved: row.moved(value)
    }

    GalleryLabel {
        anchors.verticalCenter: parent.verticalCenter
        text: row.valueText
    }
}
