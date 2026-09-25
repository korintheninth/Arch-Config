// components/StyledToolTip.qml
import QtQuick
import Quickshell
import "../themes"

PopupWindow {
    id: tooltip

    property Item anchorTarget: null

    property bool show: false
    property var styleOverride: null

    property int delay: styleOverride?.delay ?? Styles.tooltip.delay
    property int timeout: styleOverride?.timeout ?? Styles.tooltip.timeout

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
    anchor.margins.top: styleOverride?.anchor?.margins?.top ?? Styles.tooltip.anchor.margins.top

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
        color: styleOverride?.background?.color ?? Styles.tooltip.background.color
        border.width: styleOverride?.background?.border?.width ?? Styles.tooltip.background.border.width
        border.color: styleOverride?.background?.border?.color ?? Styles.tooltip.background.border.color

        BetterText {
            id: label
            text: tooltip.text
            anchors.centerIn: parent
            color: styleOverride?.label?.color ?? Styles.tooltip.label.color
            font.family: styleOverride?.label?.font?.family ?? Styles.tooltip.label.font.family

            wrapMode: Text.Wrap
        }
    }

    Connections {
        target: label
        function onWidthChanged() { if (show) anchor.updateAnchor() }
        function onHeightChanged() { if (show) anchor.updateAnchor() }
    }
}
