import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../themes"
import "../themes/StyleEngine.js" as Styler

Item {
    id: trayMenuItem

    required property var entry

    property var itemStyle: null
    property var separatorStyle: null
    property var styleOverride: null
    property var menuHost: null

    signal activated()

    readonly property var _itemStyle: itemStyle
        ?? ((typeof Styles !== "undefined" && Styles.trayMenu) ? Styles.trayMenu.item : ({}))
    readonly property var _separatorStyle: separatorStyle
        ?? ((typeof Styles !== "undefined" && Styles.trayMenu) ? Styles.trayMenu.separator : ({}))

    readonly property string displayLabel: {
        let t = entry.text ?? ""
        t = t.replace(/&./g, "")
        if (t.startsWith(":/// "))
            t = t.substring(5)
        return t.trim()
    }

    readonly property color textColor: rowMa.containsMouse ? hoverTextColor : normalTextColor

    property int rowHeight: 26
    property int horizontalPadding: 8
    property int spacing: 6
    property int iconSize: 14
    property real enabledOpacity: 1
    property real disabledOpacity: 0.4
    property color normalTextColor: "#e5e0cc"
    property color hoverColor: "transparent"
    property color hoverTextColor: "#599d8b"

    property alias label: labelItem
    property alias chevron: chevronItem

    implicitWidth: labelItem.paintedWidth + horizontalPadding * 2
    implicitHeight: entry.isSeparator ? separatorRow.rowHeight : rowHeight
    opacity: entry.enabled ? enabledOpacity : disabledOpacity

    Item {
        id: separatorRow
        visible: entry.isSeparator
        anchors.fill: parent
        property int rowHeight: 9
        property int horizontalMargin: 8
        property alias line: separatorLine

        Rectangle {
            id: separatorLine
            anchors.centerIn: parent
            width: parent.width - separatorRow.horizontalMargin * 2
            height: 1
            color: "#e5e0cc"
        }
    }

    Rectangle {
        id: hoverBg
        visible: !entry.isSeparator
        anchors.fill: parent
        color: rowMa.containsMouse ? hoverColor : "transparent"
    }

    property var subMenu: null

    Timer {
        id: subMenuCloseTimer
        interval: 150
        onTriggered: {
            if (!rowMa.containsMouse && !(subMenu?.hovered))
                closeSubMenu()
        }
    }

    Connections {
        target: subMenu
        function onHoveredChanged() {
            if (subMenu?.hovered)
                subMenuCloseTimer.stop()
            else if (!rowMa.containsMouse)
                subMenuCloseTimer.restart()
        }
    }

    function openSubMenu() {
        if (subMenu || !menuHost?.openSubMenuFor)
            return
        menuHost.openSubMenuFor(entry, trayMenuItem, trayMenuItem)
    }
    function closeSubMenu() {
        subMenuCloseTimer.stop()
        if (!subMenu)
            return
        const sm = subMenu
        subMenu = null
        sm.open = false
    }

    MouseArea {
        id: rowMa
        anchors.fill: parent
        enabled: entry.enabled && !entry.isSeparator
        hoverEnabled: true
        onContainsMouseChanged: {
            if (containsMouse && entry.hasChildren) {
                subMenuCloseTimer.stop()
                openSubMenu()
            } else if (!containsMouse && subMenu) {
                subMenuCloseTimer.restart()
            }
        }
        onClicked: {
            if (entry.hasChildren) {
                if (subMenu)
                    closeSubMenu()
                else
                    openSubMenu()
                return
            }
            entry.triggered()
            trayMenuItem.activated()
        }
    }

    RowLayout {
        id: row
        visible: !entry.isSeparator
        anchors.fill: parent
        anchors.leftMargin: trayMenuItem.horizontalPadding
        anchors.rightMargin: trayMenuItem.horizontalPadding
        spacing: trayMenuItem.spacing

        IconImage {
            visible: entry.icon !== ""
            implicitSize: trayMenuItem.iconSize
            source: entry.icon
        }

        BetterText {
            id: labelItem
            text: trayMenuItem.displayLabel
            color: trayMenuItem.textColor
            elide: Text.ElideRight
        }

        BetterText {
            id: chevronItem
            visible: entry.hasChildren
            text: "›"
            color: trayMenuItem.textColor
        }
    }

    Component.onCompleted: {
        Styler.apply(trayMenuItem, trayMenuItem._itemStyle)
        Styler.apply(separatorRow, trayMenuItem._separatorStyle)
    }

    Component.onDestruction: closeSubMenu()
}
