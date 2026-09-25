import QtQuick
import QtQuick.Effects
import "../../components"
import "../../themes"

Item {
    id: cell

    required property var gallery
    property var file: ({})
    property bool selected: false
    readonly property var s: Styles.wallpaperGallery.thumb
    readonly property string kind: file && file.kind ? file.kind : "image"

    function ensureThumb() {
        if (file && file.path)
            gallery.requestThumb(file.path)
    }

    onFileChanged: ensureThumb()
    Component.onCompleted: ensureThumb()

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 4
        color: cell.s.color
        radius: cell.s.radius

        Rectangle {
            id: cardMask
            anchors.fill: parent
            radius: card.radius
            color: "#000000"
            visible: false
            layer.enabled: true
            layer.smooth: true
        }

        Item {
            id: cardContents
            anchors.fill: parent
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: cardMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            Image {
                id: img
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: nameLabel.top
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize.width: 320
                sourceSize.height: 180
                visible: status === Image.Ready
                source: {
                    const thumb = cell.file && cell.file.path ? cell.gallery.thumbFor(cell.file.path) : ""
                    return thumb ? cell.gallery.fileUrl(thumb) : ""
                }
            }

            Rectangle {
                anchors.fill: img
                visible: img.status !== Image.Ready
                color: cell.s.color
                BetterText {
                    anchors.centerIn: parent
                    text: cell.kind === "video" ? "VID" : (cell.kind === "gif" ? "GIF" : "...")
                    color: cell.s.text.color
                    font.family: cell.s.badge.text.font.family
                    font.pixelSize: cell.s.badge.text.font.pixelSize
                }
            }

            Rectangle {
                visible: cell.kind !== "image"
                anchors.top: img.top
                anchors.left: img.left
                anchors.margins: 4
                width: badgeLabel.implicitWidth + 8
                height: badgeLabel.implicitHeight + 4
                radius: cell.s.badge.radius
                color: cell.s.badge.color
                BetterText {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: cell.kind === "gif" ? "GIF" : "VID"
                    color: cell.s.badge.text.color
                    font.family: cell.s.badge.text.font.family
                    font.pixelSize: cell.s.badge.text.font.pixelSize
                }
            }

            BetterText {
                id: nameLabel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 4
                height: implicitHeight
                elide: Text.ElideMiddle
                text: cell.file && cell.file.name ? cell.file.name : ""
                color: cell.s.text.color
                font.family: cell.s.text.font.family
                font.pixelSize: cell.s.text.font.pixelSize
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: "transparent"
            border.width: cell.selected ? cell.s.selectedBorder.width : cell.s.border.width
            border.color: cell.selected ? cell.s.selectedBorder.color : cell.s.border.color
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: cell.gallery.selectFile(cell.file)
        onDoubleClicked: {
            cell.gallery.selectFile(cell.file)
            cell.gallery.applySelected()
        }
    }
}
