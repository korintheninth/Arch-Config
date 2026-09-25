import QtQuick
import QtQuick.Layouts
import "../themes"

// In-window context menu. Parent should be a full-area host (e.g. app window root).
//
// entries: [
//   { text: "Play", action: (payload) => { ... } },
//   { separator: true },
//   { text: "Add to playlist", submenu: [
//       { text: "Favorites", action: (payload) => { ... } },
//       { separator: true },
//       { text: "create new", action: (payload) => { ... } },
//   ]},
// ]
Item {
    id: menu

    anchors.fill: parent
    visible: open
    z: 10000
    focus: open

    property bool open: false
    property var items: []
    property var payload: null
    property var styleOverride: null
    property real menuX: 0
    property real menuY: 0

    property var subItems: []
    property bool subOpen: false
    property real subX: 0
    property real subY: 0
    property var subOwner: null

    readonly property var style: styleOverride ?? Styles.contextMenu
    readonly property int menuPadding: style.menuPadding ?? 0
    readonly property bool subHovered: subHover.hovered

    signal closed()
    signal itemActivated(var entry)

    function estimateHeight(entries) {
        const rowH = style.item?.rowHeight ?? 26
        const sepH = style.separator?.rowHeight ?? 9
        const gap = style.spacing ?? 2
        const list = entries || []
        let h = menuPadding * 2
        for (let i = 0; i < list.length; ++i) {
            const e = list[i]
            if (i > 0)
                h += gap
            if (e && (e.separator || e.isSeparator))
                h += sepH
            else
                h += rowH
        }
        return Math.max(h, rowH)
    }

    function clampPos(x, y, mw, mh) {
        let nx = x
        let ny = y
        if (width > 0 && nx + mw > width)
            nx = Math.max(0, width - mw)
        if (height > 0 && ny + mh > height)
            ny = Math.max(0, height - mh)
        return { x: Math.max(0, nx), y: Math.max(0, ny) }
    }

    function openAt(x, y, entries, data) {
        closeSubmenu()
        items = Array.isArray(entries) ? entries : []
        payload = data !== undefined ? data : null
        if (!items.length) {
            close()
            return
        }
        menuX = x
        menuY = y
        // Place immediately using predicted size so we never flash then jump.
        const mw = 168
        const mh = estimateHeight(items)
        const p = clampPos(menuX, menuY, mw, mh)
        panel.x = p.x
        panel.y = p.y
        open = true
        forceActiveFocus()
    }

    function close() {
        if (!open && !subOpen)
            return
        closeSubmenu()
        open = false
        items = []
        payload = null
        closed()
    }

    function openSubmenuFor(ownerItem, entries) {
        subCloseTimer.stop()
        if (subOwner && subOwner !== ownerItem)
            subOwner.subOpen = false
        subOwner = ownerItem
        if (ownerItem)
            ownerItem.subOpen = true

        const list = []
        const n = entries ? (entries.length || 0) : 0
        for (let i = 0; i < n; ++i)
            list.push(entries[i])
        subItems = list
        if (!subItems.length) {
            closeSubmenu()
            return
        }

        const p = ownerItem.mapToItem(menu, ownerItem.width, 0)
        subX = p.x
        subY = p.y
        const mw = 168
        const mh = estimateHeight(subItems)
        let x = subX
        let y = subY
        if (width > 0 && x + mw > width)
            x = Math.max(0, panel.x - mw)
        if (height > 0 && y + mh > height)
            y = Math.max(0, height - mh)
        subPanel.x = Math.max(0, x)
        subPanel.y = Math.max(0, y)
        subOpen = true
    }

    function closeSubmenu() {
        subCloseTimer.stop()
        if (subOwner) {
            subOwner.subOpen = false
            subOwner = null
        }
        subOpen = false
        subItems = []
    }

    function scheduleCloseSubmenu() {
        subCloseTimer.restart()
    }

    function entryHasSubmenu(entry) {
        if (!entry)
            return false
        const kids = entry.submenu !== undefined ? entry.submenu : entry["children"]
        return !!(kids && kids.length)
    }

    function activateEntry(entry) {
        if (!entry || entry.separator || entry.isSeparator)
            return
        if (entry.enabled === false)
            return
        if (entryHasSubmenu(entry))
            return
        if (typeof entry.action === "function")
            entry.action(menu.payload)
        menu.itemActivated(entry)
        menu.close()
    }

    Timer {
        id: subCloseTimer
        interval: 220
        onTriggered: {
            if (menu.subHovered)
                return
            if (subOwner && subOwner.itemHovered)
                return
            menu.closeSubmenu()
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            if (subOpen)
                closeSubmenu()
            else
                close()
            event.accepted = true
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: menu.close()
    }

    Rectangle {
        id: panel
        z: 1
        implicitWidth: itemsColumn.implicitWidth + menu.menuPadding * 2
        implicitHeight: itemsColumn.implicitHeight + menu.menuPadding * 2
        width: implicitWidth
        height: implicitHeight
        color: menu.style.background?.color ?? Styles.bgBase
        border.width: menu.style.background?.border?.width ?? 1
        border.color: menu.style.background?.border?.color ?? Styles.fgBase
        radius: menu.style.background?.radius ?? 0

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.AllButtons
            hoverEnabled: false
            onPressed: (mouse) => { mouse.accepted = true }
        }

        ColumnLayout {
            id: itemsColumn
            x: menu.menuPadding
            y: menu.menuPadding
            spacing: menu.style.spacing ?? 2

            Repeater {
                model: menu.items

                delegate: StyledContextMenuItem {
                    required property var modelData
                    required property int index

                    entry: modelData
                    itemStyle: menu.style.item
                    separatorStyle: menu.style.separator
                    menuHost: menu
                    Layout.fillWidth: true
                    onActivated: menu.activateEntry(modelData)
                }
            }
        }
    }

    Rectangle {
        id: subPanel
        z: 2
        visible: menu.subOpen
        implicitWidth: Math.max(subColumn.implicitWidth + menu.menuPadding * 2, 120)
        implicitHeight: subColumn.implicitHeight + menu.menuPadding * 2
        width: implicitWidth
        height: implicitHeight
        color: menu.style.background?.color ?? Styles.bgBase
        border.width: menu.style.background?.border?.width ?? 1
        border.color: menu.style.background?.border?.color ?? Styles.fgBase
        radius: menu.style.background?.radius ?? 0

        HoverHandler {
            id: subHover
            onHoveredChanged: {
                if (hovered)
                    menu.subCloseTimer.stop()
                else
                    menu.scheduleCloseSubmenu()
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.AllButtons
            hoverEnabled: false
            onPressed: (mouse) => { mouse.accepted = true }
        }

        ColumnLayout {
            id: subColumn
            x: menu.menuPadding
            y: menu.menuPadding
            spacing: menu.style.spacing ?? 2

            Repeater {
                model: menu.subItems

                delegate: StyledContextMenuItem {
                    required property var modelData
                    required property int index

                    entry: modelData
                    itemStyle: menu.style.item
                    separatorStyle: menu.style.separator
                    menuHost: null
                    Layout.fillWidth: true
                    onActivated: menu.activateEntry(modelData)
                }
            }
        }
    }
}
