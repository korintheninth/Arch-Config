import QtQuick
import QtQuick.Controls
import "../../components"
import "../../themes"

Item {
    id: sidebar

    required property var gallery
    readonly property var s: Styles.wallpaperGallery.folder

    Rectangle {
        anchors.fill: parent
        color: Styles.wallpaperGallery.sidebar.color
        radius: Styles.wallpaperGallery.sidebar.radius
        border.width: Styles.wallpaperGallery.sidebar.border.width
        border.color: Styles.wallpaperGallery.sidebar.border.color
        clip: radius > 0
    }

    BetterText {
        id: folderTitle
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 4
        anchors.leftMargin: 10
        height: Styles.wallpaperGallery.headerHeight
        verticalAlignment: Text.AlignVCenter
        text: "wallpapers"
        color: Styles.wallpaperGallery.title.text.color
        font.family: Styles.wallpaperGallery.title.text.font.family
        font.pixelSize: Styles.wallpaperGallery.title.text.font.pixelSize
        font.bold: Styles.wallpaperGallery.title.text.font.bold
    }

    ListView {
        id: list
        anchors.top: folderTitle.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: countBar.top
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.bottomMargin: 4
        rightMargin: 10
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: sidebar.gallery.visibleFolders

        delegate: Rectangle {
            id: row
            required property var modelData

            readonly property bool selected: sidebar.gallery.selectedFolder === modelData.id
            readonly property bool hasKids: sidebar.gallery.folderHasChildren(modelData.id)
            readonly property bool collapsed: sidebar.gallery.isCollapsed(modelData.id)
            readonly property int indent: 4 + modelData.depth * sidebar.s.indent

            width: Math.max(20, list.width - 10)
            height: sidebar.s.height
            radius: sidebar.s.radius
            color: selected
                ? sidebar.s.selectedColor
                : (hover.containsMouse ? sidebar.s.hoverColor : sidebar.s.normalColor)

            Row {
                anchors.fill: parent
                anchors.leftMargin: row.indent
                spacing: 4

                BetterText {
                    id: twisty
                    width: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.hasKids ? (row.collapsed ? "+" : "-") : " "
                    color: row.selected ? sidebar.s.text.selectedColor : sidebar.s.text.color
                    font.family: sidebar.s.text.font.family
                    font.pixelSize: sidebar.s.text.font.pixelSize
                }

                BetterText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(20, row.width - twisty.width - countLabel.implicitWidth - row.indent - 16)
                    elide: Text.ElideRight
                    text: row.modelData.name
                    color: row.selected ? sidebar.s.text.selectedColor : sidebar.s.text.color
                    font.family: sidebar.s.text.font.family
                    font.pixelSize: sidebar.s.text.font.pixelSize
                }

                BetterText {
                    id: countLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(row.modelData.count)
                    color: row.selected ? sidebar.s.count.selectedColor : sidebar.s.count.color
                    font.family: sidebar.s.count.font.family
                    font.pixelSize: sidebar.s.count.font.pixelSize
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (row.hasKids && mouse.x < row.indent + 14)
                        sidebar.gallery.toggleCollapsed(row.modelData.id)
                    else
                        sidebar.gallery.selectFolder(row.modelData.id)
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: Styles.fgBase
            }
        }
    }

    BetterText {
        id: countBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 22
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: sidebar.gallery.loadingIndex ? "indexing..." : sidebar.gallery.indexCount + " wallpapers"
        color: sidebar.s.count.color
        font.family: sidebar.s.count.font.family
        font.pixelSize: sidebar.s.count.font.pixelSize
    }
}
