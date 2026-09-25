// components/StyledTrayMenu.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell
import Quickshell.Services.SystemTray
import "../themes"

PopupWindow {
    id: trayMenu

    property Item anchorTarget: null
    property SystemTrayItem trayItem: null
    property var styleOverride: null
    property bool open: false

    property QsMenuHandle subMenuEntry: null
    property QsMenuHandle menu: isSubMenu ? subMenuEntry : (trayItem ? trayItem.menu : null)
    property bool isSubMenu: false
    property var rootMenu: null

    property bool hovered: false
    property bool childTreeHovered: false
    readonly property bool treeHovered: hovered || childTreeHovered

    HoverHandler {
        onHoveredChanged: trayMenu.hovered = hovered
    }

    function updateChildTreeHovered() {
        let any = false
        for (let i = 0; i < itemsColumn.children.length; ++i) {
            const child = itemsColumn.children[i]
            if (child?.subMenu?.treeHovered) {
                any = true
                break
            }
        }
        childTreeHovered = any
    }

    property var allowedWindows: isSubMenu ? [] : [trayMenu]

    HyprlandFocusGrab {
        active: trayMenu.open && !isSubMenu
        windows: trayMenu.allowedWindows
        onCleared: trayMenu.open = false
    }

    property alias openAnim: openAnim
    visible: open || openAnim.running

    onVisibleChanged: {
        if (!visible)
            open = false
    }

    anchor.item: anchorTarget
    anchor.edges: isSubMenu ? Edges.Right : Edges.Bottom
    anchor.gravity: isSubMenu ? Edges.Right : Edges.Bottom

    implicitWidth: Math.max(panel.implicitWidth + 2 * surfacePad, 1)
    implicitHeight: Math.max(panel.implicitHeight + 2 * surfacePad, 1)
    readonly property int surfacePad: 2
    anchor.margins.top: isSubMenu ? 0 : (styleOverride?.anchor?.margins?.top ?? Styles.trayMenu.anchor.margins.top)
    anchor.margins.bottom: isSubMenu ? 0 : 0
    anchor.margins.left: isSubMenu ? 0 : 0
    anchor.margins.right: isSubMenu ? 0 : 0

    onOpenChanged: {
        if (!open)
            return
        if (!isSubMenu && !trayItem?.hasMenu) {
            open = false
            return
        }
        anchor.updateAnchor()
        visible = true
    }

    function closeMenu() {
        closeAllSubMenus()
        if (!isSubMenu)
            allowedWindows = [trayMenu]
        open = false
    }

    function closeAllSubMenus() {
        for (let i = 0; i < itemsColumn.children.length; ++i) {
            const child = itemsColumn.children[i]
            if (child?.closeSubMenu)
                child.closeSubMenu()
        }
    }

    function releaseMenu() {
        closeAllSubMenus()
        if (isSubMenu)
            return
        allowedWindows = [trayMenu]
        trayItem = null
    }

    readonly property Component subMenuComponent: Qt.createComponent(
        Qt.resolvedUrl("StyledTrayMenu.qml"))

    function openSubMenuFor(entry, anchor, owner) {
        closeAllSubMenus()
        if (subMenuComponent.status !== Component.Ready)
            return
        const root = trayMenu.isSubMenu ? trayMenu.rootMenu : trayMenu
        owner.subMenu = subMenuComponent.createObject(trayMenu, {
            subMenuEntry: entry,
            isSubMenu: true,
            anchorTarget: anchor,
            styleOverride: trayMenu.styleOverride,
            rootMenu: root,
        })
        owner.subMenu.open = true
        const sm = owner.subMenu
        root.allowedWindows = root.allowedWindows.concat([sm])
        trayMenu.updateChildTreeHovered()
        return owner.subMenu
    }

    QsMenuOpener {
        id: menuOpener
        menu: trayMenu.menu
    }

    property alias background: panel

    property int menuPadding: styleOverride?.menuPadding ?? Styles.trayMenu.menuPadding
    color: "transparent"

    Rectangle {
        id: panel
        implicitWidth: itemsColumn.implicitWidth + menuPadding * 2
        implicitHeight: itemsColumn.implicitHeight + menuPadding * 2
        x: trayMenu.surfacePad
        y: trayMenu.surfacePad
        width: implicitWidth
        height: implicitHeight
        color: styleOverride?.background?.color ?? Styles.trayMenu.background.color
        border.width: styleOverride?.background?.border?.width ?? Styles.trayMenu.background.border.width
        border.color: styleOverride?.background?.border?.color ?? Styles.trayMenu.background.border.color

        NumberAnimation {
            id: openAnim
            target: panel
            property: trayMenu.isSubMenu ? "x" : "y"
            duration: 350
            easing.type: Easing.OutQuart

            onFinished: {
                if (!trayMenu.open) {
                    trayMenu.visible = false
                    if (trayMenu.isSubMenu) {
                        const root = trayMenu.rootMenu
                        if (root)
                            root.allowedWindows = root.allowedWindows.filter(w => w && w !== trayMenu)
                        trayMenu.destroy()
                    } else {
                        trayMenu.releaseMenu()
                    }
                }
            }
        }

        Timer {
            id: layoutDelay
            interval: 30
            onTriggered: {
                if (trayMenu.isSubMenu) {
                    panel.x = -panel.width - 50
                    panel.y = trayMenu.surfacePad
                    openAnim.from = -panel.width - 50
                } else {
                    panel.y = -panel.height - 50
                    panel.x = trayMenu.surfacePad
                    openAnim.from = -panel.height - 50
                }
                openAnim.to = trayMenu.surfacePad
                openAnim.start()
            }
        }

        Connections {
            target: trayMenu
            function onOpenChanged() {
                if (trayMenu.open) {
                    if (trayMenu.isSubMenu)
                        panel.x = -2000
                    else
                        panel.y = -2000
                    layoutDelay.start()
                } else {
                    layoutDelay.stop()
                    if (trayMenu.isSubMenu) {
                        openAnim.from = panel.x
                        openAnim.to = -panel.width - 50
                    } else {
                        openAnim.from = panel.y
                        openAnim.to = -panel.height - 50
                    }
                    openAnim.start()
                }
            }
        }

        ColumnLayout {
            id: itemsColumn
            anchors.centerIn: parent
            anchors.margins: menuPadding
            spacing: 2

            Repeater {
                model: menuOpener.children?.values ?? []
                delegate: StyledTrayMenuItem {
                    required property var modelData
                    entry: modelData
                    itemStyle: trayMenu.styleOverride?.item
                    separatorStyle: trayMenu.styleOverride?.separator
                    styleOverride: trayMenu.styleOverride
                    menuHost: trayMenu
                    Layout.fillWidth: true
                    onActivated: trayMenu.closeMenu()
                }
            }
        }
    }

}
