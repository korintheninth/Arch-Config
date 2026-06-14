// components/StyledToolTip.qml
import QtQuick
import Quickshell // Required for PopupWindow and Edges
import "../themes"
import "../themes/StyleEngine.js" as Styler

PopupWindow {
    id: tooltip

    property Item anchorTarget: null

    property bool show: false
    property var styleOverride: null

    property int delay: 400
    property int timeout: 5000
    
    property string text: ""

    property alias background: backgroundRect
    property alias label: label

    visible: revealed
    property bool revealed: false
    
    implicitWidth: backgroundRect.width
    implicitHeight: backgroundRect.height
    
    anchor.item: anchorTarget
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 15

    Timer {
        id: showTimer
        interval: tooltip.delay
        repeat: false
        onTriggered: {
            if (!tooltip.show)
                return
            tooltip.revealed = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: tooltip.timeout
        repeat: false
        onTriggered: tooltip.revealed = false
    }

    onShowChanged: {
        if (show) {
            showTimer.restart()
        } else {
            showTimer.stop()
            hideTimer.stop()
            revealed = false
        }
    }

    Rectangle {
        id: backgroundRect

        width: label.width + 20
        height: label.height + 12
        
        BetterText {
            id: label
            text: tooltip.text
            anchors.centerIn: parent
            
            wrapMode: Text.Wrap
        }
    }

    Component.onCompleted: {
        if (typeof Styles !== "undefined" && Styles.tooltip) {
            Styler.apply(tooltip, Styles.tooltip)
        }
        if (styleOverride) {
            Styler.apply(tooltip, styleOverride)
        }
    }

    Connections {
        target: label
        function onWidthChanged() { if (show) anchor.updateAnchor() }
        function onHeightChanged() { if (show) anchor.updateAnchor() }
    }
}