// components/StyledTrayMenu.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell
import Quickshell.Services.SystemTray
import "../themes"
import "../themes/StyleEngine.js" as Styler

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

    HoverHandler {
        onHoveredChanged: trayMenu.hovered = hovered
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

    implicitWidth: Math.max(panel.implicitWidth, 1)
    implicitHeight: Math.max(panel.implicitHeight, 1)

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
        return owner.subMenu
    }

    QsMenuOpener {
        id: menuOpener
        menu: trayMenu.menu
    }
    

    property alias background: panel

    property int menuPadding: 8
    color: "transparent"
    
    Rectangle {
        id: panel
        implicitWidth: itemsColumn.implicitWidth + menuPadding * 2
        implicitHeight: Math.min(itemsColumn.implicitHeight + menuPadding * 2, 400)
        anchors.fill: parent
        color: "transparent"

        transform: Translate {
            id: slideTransform
        }

        NumberAnimation {
            id: openAnim
            target: slideTransform
            property: trayMenu.isSubMenu ? "x" : "y"
            duration: 350
            easing.type: Easing.OutQuart

            onFinished: {
                if (!trayMenu.open) {
                    trayMenu.visible = false
                    if (trayMenu.isSubMenu)
                        trayMenu.destroy()
                }
            }
        }

        Timer {
            id: layoutDelay
            interval: 30
            onTriggered: {
                if (trayMenu.isSubMenu) {
                    slideTransform.x = -panel.width - 50
                    openAnim.from = -panel.width - 50
                } else {
                    slideTransform.y = -panel.height - 50
                    openAnim.from = -panel.height - 50
                }
                openAnim.to = 0
                openAnim.start()
            }
        }

        Connections {
            target: trayMenu
            function onOpenChanged() {
                if (trayMenu.open) {
                    if (trayMenu.isSubMenu)
                        slideTransform.x = -2000
                    else
                        slideTransform.y = -2000
                    layoutDelay.start()
                } else {
                    layoutDelay.stop()
                    if (trayMenu.isSubMenu) {
                        openAnim.from = slideTransform.x
                        openAnim.to = -panel.width - 50
                    } else {
                        openAnim.from = slideTransform.y
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

    Component.onCompleted: {
        if (typeof Styles !== "undefined" && Styles.trayMenu)
            Styler.apply(trayMenu, Styles.trayMenu)
        if (styleOverride)
            Styler.apply(trayMenu, styleOverride)
        if (isSubMenu) {
            anchor.margins.top = 0
            anchor.margins.bottom = 0
            anchor.margins.left = 0
            anchor.margins.right = 0
        }
    }
}