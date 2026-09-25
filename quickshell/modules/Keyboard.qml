import QtQuick
import "../components"
import "../services"
import "../themes"

Item {
    id: keyboard

    readonly property var leftStagger: [0.5, 0.5, 0.25, 0, 0.25, 0.5]
    readonly property var rightStagger: [0.5, 0.25, 0, 0.25, 0.5, 0.5]
    readonly property var leftKeys: [
        { index: 0, col: 0, row: 0 }, { index: 1, col: 1, row: 0 },
        { index: 2, col: 2, row: 0 }, { index: 3, col: 3, row: 0 },
        { index: 4, col: 4, row: 0 }, { index: 5, col: 5, row: 0 },
        { index: 6, col: 0, row: 1 }, { index: 7, col: 1, row: 1 },
        { index: 8, col: 2, row: 1 }, { index: 9, col: 3, row: 1 },
        { index: 10, col: 4, row: 1 }, { index: 11, col: 5, row: 1 },
        { index: 12, col: 0, row: 2 }, { index: 13, col: 1, row: 2 },
        { index: 14, col: 2, row: 2 }, { index: 15, col: 3, row: 2 },
        { index: 16, col: 4, row: 2 }, { index: 17, col: 5, row: 2 },
        { index: 18, col: 0, row: 3 }, { index: 19, col: 1, row: 3 },
        { index: 20, col: 2, row: 3 }, { index: 21, col: 3, row: 3 },
        { index: 22, col: 4, row: 3 }, { index: 23, col: 5, row: 3 },
        { index: 24, col: 4, row: 4.2 }, { index: 25, col: 5, row: 4.45 }
    ]
    readonly property var rightKeys: [
        { index: 26, col: 0, row: 0 }, { index: 27, col: 1, row: 0 },
        { index: 28, col: 2, row: 0 }, { index: 29, col: 3, row: 0 },
        { index: 30, col: 4, row: 0 }, { index: 31, col: 5, row: 0 },
        { index: 32, col: 0, row: 1 }, { index: 33, col: 1, row: 1 },
        { index: 34, col: 2, row: 1 }, { index: 35, col: 3, row: 1 },
        { index: 36, col: 4, row: 1 }, { index: 37, col: 5, row: 1 },
        { index: 38, col: 0, row: 2 }, { index: 39, col: 1, row: 2 },
        { index: 40, col: 2, row: 2 }, { index: 41, col: 3, row: 2 },
        { index: 42, col: 4, row: 2 }, { index: 43, col: 5, row: 2 },
        { index: 44, col: 0, row: 3 }, { index: 45, col: 1, row: 3 },
        { index: 46, col: 2, row: 3 }, { index: 47, col: 3, row: 3 },
        { index: 48, col: 4, row: 3 }, { index: 49, col: 5, row: 3 },
        { index: 50, col: 0, row: 4.45 }, { index: 51, col: 1, row: 4.2 }
    ]

    readonly property real halfWidth: 6 * Styles.keyboard.keySize + 5 * Styles.keyboard.keyGap
    readonly property real halfHeight: 5.5 * (Styles.keyboard.keySize + Styles.keyboard.keyGap)
    readonly property real splay: Styles.keyboard.splay || 0
    readonly property real splayPad: Math.abs(Math.sin(splay * Math.PI / 180)) * halfHeight

    visible: KeyboardService.connected
    implicitWidth: halfWidth * 2 + Styles.keyboard.halfGap + splayPad * 2
    implicitHeight: halfHeight + splayPad

    function keyState(index) {
        KeyboardService.keyStatesVersion
        return KeyboardService.keyStates[index] || {
            index: index,
            pressed: false,
            tap: "",
            hold: "",
            label: ""
        }
    }

    component KeyCap: Rectangle {
        id: cap

        required property var modelData
        required property var stagger

        property var state: keyboard.keyState(modelData.index)
        property bool down: !!state.pressed
        property string tapLabel: state.label || ""
        property string holdLabel: (state.hold && state.hold !== state.label) ? state.hold : ""
        property string tapIcon: KeyboardService.iconFor(tapLabel) || KeyboardService.iconFor(state.tap)
        property string holdIcon: KeyboardService.iconFor(holdLabel)
        readonly property real unit: Styles.keyboard.keySize + Styles.keyboard.keyGap

        x: modelData.col * unit
        y: (modelData.row + stagger[modelData.col]) * unit
        width: Styles.keyboard.keySize
        height: Styles.keyboard.keySize
        radius: Styles.keyboard.key.radius
        color: down ? Styles.keyboard.key.pressedColor : Styles.keyboard.key.color
        border.width: Styles.keyboard.key.border.width
        border.color: Styles.keyboard.key.border.color

        BetterText {
            visible: cap.holdLabel.length > 0
            text: cap.holdIcon || cap.holdLabel
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 3
            width: parent.width - 4
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: cap.holdIcon ? Text.ElideNone : Text.ElideRight
            font.family: cap.holdIcon
                ? Styles.keyboard.key.icon.font.family
                : Styles.keyboard.key.hold.font.family
            font.pixelSize: cap.holdIcon
                ? Styles.keyboard.key.icon.holdPixelSize
                : Styles.keyboard.key.hold.font.pixelSize
            color: cap.down ? Styles.keyboard.key.hold.pressedColor : Styles.keyboard.key.hold.color
        }

        BetterText {
            text: cap.tapIcon || cap.tapLabel
            anchors.centerIn: parent
            anchors.verticalCenterOffset: cap.holdLabel.length > 0 ? 6 : 0
            width: parent.width - 4
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: cap.tapIcon ? Text.ElideNone : Text.ElideRight
            font.family: cap.tapIcon
                ? Styles.keyboard.key.icon.font.family
                : Styles.keyboard.key.text.font.family
            font.pixelSize: cap.tapIcon
                ? Styles.keyboard.key.icon.font.pixelSize
                : Styles.keyboard.key.text.font.pixelSize
            font.bold: cap.tapIcon
                ? Styles.keyboard.key.icon.font.bold
                : (cap.down
                    ? Styles.keyboard.key.text.pressedBold
                    : Styles.keyboard.key.text.font.bold)
            color: cap.down ? Styles.keyboard.key.text.pressedColor : Styles.keyboard.key.text.color
        }
    }

    Item {
        id: leftHalf
        anchors.left: parent.left
        anchors.leftMargin: keyboard.splayPad
        anchors.bottom: parent.bottom
        width: keyboard.halfWidth
        height: keyboard.halfHeight
        transform: Rotation {
            origin.x: leftHalf.width
            origin.y: leftHalf.height
            angle: keyboard.splay
        }

        Repeater {
            model: keyboard.leftKeys
            delegate: KeyCap {
                stagger: keyboard.leftStagger
            }
        }
    }

    Item {
        id: rightHalf
        anchors.right: parent.right
        anchors.rightMargin: keyboard.splayPad
        anchors.bottom: parent.bottom
        width: keyboard.halfWidth
        height: keyboard.halfHeight
        transform: Rotation {
            origin.x: 0
            origin.y: rightHalf.height
            angle: -keyboard.splay
        }

        Repeater {
            model: keyboard.rightKeys
            delegate: KeyCap {
                stagger: keyboard.rightStagger
            }
        }
    }
}
