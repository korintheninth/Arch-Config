import QtQuick
import QtQuick.Layouts
import "../themes"

Item {
    id: menuItem

    property var entry: ({})
    property var itemStyle: null
    property var separatorStyle: null
    property var menuHost: null
    property bool subOpen: false

    signal activated()

    readonly property var _itemStyle: itemStyle
        ?? ((typeof Styles !== "undefined" && Styles.contextMenu)
            ? Styles.contextMenu.item
            : (Styles.trayMenu?.item ?? ({})))
    readonly property var _separatorStyle: separatorStyle
        ?? ((typeof Styles !== "undefined" && Styles.contextMenu)
            ? Styles.contextMenu.separator
            : (Styles.trayMenu?.separator ?? ({})))

    readonly property bool isSeparator: !!(entry?.separator || entry?.isSeparator)
    readonly property bool isEnabled: entry?.enabled !== false

    // Prefer "submenu" — "children" collides with Item.children in some QML paths.
    readonly property var submenuEntries: {
        if (!entry)
            return []
        const kids = entry.submenu !== undefined ? entry.submenu : entry["children"]
        if (!kids)
            return []
        // QVariantList is not always a JS Array — don't use Array.isArray.
        const out = []
        const n = kids.length || 0
        for (let i = 0; i < n; ++i)
            out.push(kids[i])
        return out
    }
    readonly property bool hasSubmenu: submenuEntries.length > 0

    readonly property string displayLabel: {
        let t = entry?.text ?? entry?.label ?? ""
        t = String(t).replace(/&./g, "")
        return t.trim()
    }
    readonly property bool rowHovered: hover.hovered
    readonly property bool itemHovered: rowHovered
        || (subOpen && !!(menuHost && menuHost.subHovered))
    readonly property bool showHover: rowHovered || subOpen
    readonly property real contentFade: isSeparator || isEnabled ? enabledOpacity : disabledOpacity
    readonly property color textColor: {
        const base = showHover ? hoverTextColor : normalTextColor
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

    implicitWidth: isSeparator
        ? 80
        : Math.max(labelItem.implicitWidth + horizontalPadding * 2
            + (entry?.icon ? iconSize + spacing : 0)
            + (hasSubmenu ? chevronItem.implicitWidth + spacing : 0), 120)
    implicitHeight: isSeparator ? (_separatorStyle.rowHeight ?? 9) : rowHeight

    function requestSubmenu() {
        if (!hasSubmenu || !menuHost || typeof menuHost.openSubmenuFor !== "function")
            return
        menuHost.openSubmenuFor(menuItem, submenuEntries)
    }

    function handleHover(entered) {
        if (!menuHost)
            return
        if (entered) {
            if (hasSubmenu)
                requestSubmenu()
            else
                menuHost.closeSubmenu()
        } else if (hasSubmenu) {
            menuHost.scheduleCloseSubmenu()
        }
    }

    Item {
        visible: menuItem.isSeparator
        anchors.fill: parent

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - (_separatorStyle.horizontalMargin ?? 8) * 2
            height: _separatorStyle.line?.height ?? 1
            color: _separatorStyle.line?.color ?? "#e5e0cc"
        }
    }

    Rectangle {
        visible: !menuItem.isSeparator
        anchors.fill: parent
        color: menuItem.showHover && menuItem.isEnabled ? menuItem.hoverColor : "transparent"
    }

    HoverHandler {
        id: hover
        enabled: menuItem.isEnabled && !menuItem.isSeparator
        onHoveredChanged: menuItem.handleHover(hovered)
    }

    MouseArea {
        anchors.fill: parent
        enabled: menuItem.isEnabled && !menuItem.isSeparator
        hoverEnabled: false
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (menuItem.hasSubmenu) {
                menuItem.requestSubmenu()
                return
            }
            menuItem.activated()
        }
    }

    RowLayout {
        visible: !menuItem.isSeparator
        anchors.fill: parent
        anchors.leftMargin: menuItem.horizontalPadding
        anchors.rightMargin: menuItem.horizontalPadding
        spacing: menuItem.spacing

        Item {
            visible: !!(entry?.icon)
            Layout.preferredWidth: menuItem.iconSize
            Layout.preferredHeight: menuItem.iconSize

            Image {
                anchors.fill: parent
                source: entry?.icon || ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: menuItem.contentFade
            }
        }

        BetterText {
            id: labelItem
            Layout.fillWidth: true
            text: menuItem.displayLabel
            color: menuItem.textColor
            elide: Text.ElideRight
            font.family: _itemStyle.label?.font?.family ?? Styles.fontFamily
            font.pixelSize: _itemStyle.label?.font?.pixelSize ?? Styles.pixelSize
        }

        BetterText {
            id: chevronItem
            visible: menuItem.hasSubmenu
            text: "›"
            color: menuItem.textColor
            font.family: _itemStyle.chevron?.font?.family
                ?? _itemStyle.label?.font?.family
                ?? Styles.fontFamily
        }
    }
}
