import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../components"
import "../../themes"

Item {
    id: dialog

    anchors.fill: parent
    visible: open
    z: 10001
    focus: open

    property bool open: false
    property string title: "new playlist"
    property string placeholder: "playlist name"
    property string text: ""
    property var styleOverride: null

    readonly property var s: styleOverride ?? Styles.mpdClient.prompt

    signal accepted(string value)
    signal cancelled()

    function openPrompt(opts) {
        const o = opts || {}
        title = o.title || "new playlist"
        placeholder = o.placeholder || "playlist name"
        text = o.text || ""
        open = true
        forceActiveFocus()
        Qt.callLater(() => {
            input.forceActiveFocus()
            input.selectAll()
        })
    }

    function close() {
        if (!open)
            return
        open = false
        text = ""
    }

    function submit() {
        const value = (input.text || "").trim()
        if (!value)
            return
        accepted(value)
        close()
    }

    function cancel() {
        cancelled()
        close()
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            cancel()
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            submit()
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        color: s.scrim?.color ?? Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: dialog.cancel()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(s.width ?? 360, parent.width - 40)
        implicitHeight: col.implicitHeight + (s.padding ?? 16) * 2
        height: implicitHeight
        color: s.background?.color ?? Styles.bgBase
        radius: s.background?.radius ?? 10
        border.width: s.background?.border?.width ?? 1
        border.color: s.background?.border?.color ?? Styles.fgBase

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: (mouse) => { mouse.accepted = true }
        }

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: s.padding ?? 16
            spacing: s.spacing ?? 10

            BetterText {
                Layout.fillWidth: true
                text: dialog.title
                color: s.title?.color ?? Styles.fgBase
                font.family: s.title?.font?.family ?? "Silkscreen"
                font.pixelSize: s.title?.font?.pixelSize ?? 12
            }

            TextField {
                id: input
                Layout.fillWidth: true
                text: dialog.text
                placeholderText: dialog.placeholder
                color: s.input?.color ?? Styles.fgBase
                placeholderTextColor: s.input?.placeholderColor
                    ?? Qt.rgba(Styles.fgBase.r, Styles.fgBase.g, Styles.fgBase.b, 0.45)
                font.family: s.input?.font?.family ?? Styles.fontFamily
                font.pixelSize: s.input?.font?.pixelSize ?? Styles.pixelSize
                background: Rectangle {
                    color: s.input?.background?.color
                        ?? Qt.rgba(Styles.fgBase.r, Styles.fgBase.g, Styles.fgBase.b, 0.06)
                    radius: s.input?.background?.radius ?? 5
                    border.width: s.input?.background?.border?.width ?? 1
                    border.color: s.input?.background?.border?.color ?? Styles.fgBase
                }
                onAccepted: dialog.submit()
                onTextChanged: dialog.text = text
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredHeight: s.button?.height ?? 28
                    Layout.preferredWidth: Math.max(cancelLabel.implicitWidth + 20, 72)
                    radius: s.button?.radius ?? 5
                    color: cancelMa.containsMouse
                        ? (s.button?.hoverColor ?? Qt.rgba(Styles.fgBase.r, Styles.fgBase.g, Styles.fgBase.b, 0.12))
                        : (s.button?.normalColor ?? "transparent")
                    border.width: s.button?.border?.width ?? 1
                    border.color: s.button?.border?.color ?? Styles.fgBase

                    BetterText {
                        id: cancelLabel
                        anchors.centerIn: parent
                        text: "cancel"
                        color: s.button?.textColor ?? Styles.fgBase
                        font.family: s.button?.font?.family ?? Styles.fontFamily
                        font.pixelSize: s.button?.font?.pixelSize ?? Styles.pixelSize
                    }

                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.cancel()
                    }
                }

                Rectangle {
                    Layout.preferredHeight: s.button?.height ?? 28
                    Layout.preferredWidth: Math.max(okLabel.implicitWidth + 20, 72)
                    radius: s.button?.radius ?? 5
                    readonly property real fade: (input.text || "").trim().length ? 1 : 0.4
                    color: {
                        const base = okMa.containsMouse
                            ? (s.button?.hoverColor ?? Styles.fgBase)
                            : (s.button?.activeColor ?? Styles.fgBase)
                        return Qt.rgba(base.r, base.g, base.b, base.a * fade)
                    }
                    border.width: s.button?.border?.width ?? 0
                    border.color: s.button?.border?.color ?? "transparent"

                    BetterText {
                        id: okLabel
                        anchors.centerIn: parent
                        text: "create"
                        color: faded(s.button?.activeTextColor ?? Styles.bgBase, parent.fade)
                        font.family: s.button?.font?.family ?? Styles.fontFamily
                        font.pixelSize: s.button?.font?.pixelSize ?? Styles.pixelSize
                    }

                    MouseArea {
                        id: okMa
                        anchors.fill: parent
                        enabled: (input.text || "").trim().length > 0
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: dialog.submit()
                    }
                }
            }
        }
    }
}
