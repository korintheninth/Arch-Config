import QtQuick

Flow {
    id: row
    property var model: []
    property string selected: ""
    signal picked(string value)

    width: parent ? parent.width : implicitWidth
    spacing: 6

    Repeater {
        model: row.model
        GalleryChip {
            required property string modelData
            label: modelData
            selected: row.selected === modelData
            onClicked: row.picked(modelData)
        }
    }
}
