import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../themes"

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

    readonly property bool itemHovered: rowMa.containsMouse || !!(subMenu?.treeHovered)
    readonly property real contentFade: entry.enabled ? enabledOpacity : disabledOpacity
    readonly property color textColor: {
        const base = itemHovered ? hoverTextColor : normalTextColor
        return Qt.rgba(base.r, base.g, base.b, base.a * contentFade)
    }

    property int rowHeight: _itemStyle.rowHeight ?? 26
    property int horizontalPadding: _itemStyle.horizontalPadding ?? 8
    property int spacing: _itemStyle.spacing ?? 6
    property int iconSize: _itemStyle.iconSize ?? 14
    property real enabledOpacity: _itemStyle.enabledOpacity ?? 1
    property real disabledOpacity: _itemStyle.disabledOpacity ?? 0.4
    property color normalTextColor: _itemStyle.normalTextColor ?? "#e5e0cc"
    property color hoverColor: _itemStyle.hoverColor ?? "transparent"
    property color hoverTextColor: _itemStyle.hoverTextColor ?? "#599d8b"

    property alias label: labelItem
    property alias chevron: chevronItem

    implicitWidth: labelItem.paintedWidth + horizontalPadding * 2
    implicitHeight: entry.isSeparator ? separatorRow.rowHeight : rowHeight

    Item {
        id: separatorRow
        visible: entry.isSeparator
        anchors.fill: parent
        property int rowHeight: _separatorStyle.rowHeight ?? 9
        property int horizontalMargin: _separatorStyle.horizontalMargin ?? 8
        property alias line: separatorLine

        Rectangle {
            id: separatorLine
            anchors.centerIn: parent
            width: parent.width - separatorRow.horizontalMargin * 2
            height: _separatorStyle.line?.height ?? 1
            color: _separatorStyle.line?.color ?? "#e5e0cc"
        }
    }

    Rectangle {
        id: hoverBg
        visible: !entry.isSeparator
        anchors.fill: parent
        color: itemHovered ? hoverColor : "transparent"
    }

    property var subMenu: null

    Timer {
        id: subMenuCloseTimer
        interval: 150
        onTriggered: {
            if (!rowMa.containsMouse && !(subMenu?.treeHovered))
                closeSubMenu()
        }
    }

    Connections {
        target: subMenu
        function onTreeHoveredChanged() {
            if (subMenu?.treeHovered)
                subMenuCloseTimer.stop()
            else if (!rowMa.containsMouse)
                subMenuCloseTimer.restart()
            menuHost?.updateChildTreeHovered()
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
        menuHost?.updateChildTreeHovered()
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
            opacity: trayMenuItem.contentFade
        }

        BetterText {
            id: labelItem
            text: trayMenuItem.displayLabel
            color: trayMenuItem.textColor
            elide: Text.ElideRight
            font.family: _itemStyle.label?.font?.family ?? Styles.fontFamily
        }

        BetterText {
            id: chevronItem
            visible: entry.hasChildren
            text: "›"
            color: trayMenuItem.textColor
            font.family: _itemStyle.chevron?.font?.family ?? Styles.fontFamily
        }
    }

    Component.onDestruction: closeSubMenu()
}
