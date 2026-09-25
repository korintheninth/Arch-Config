import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../components"
import "../themes"

PopupWindow {
    id: soundMenu
    color: "transparent"
    readonly property int surfacePad: 2
    implicitHeight: streams.implicitHeight + 2 * Styles.soundMenu.padding + 2 * surfacePad
    implicitWidth: streams.width + 2 * Styles.soundMenu.padding + 2 * surfacePad
    
    property bool open: false

    HyprlandFocusGrab {
        active: soundMenu.open
        windows: [soundMenu]
        onCleared: soundMenu.open = false
    }

    onVisibleChanged: {
        if (!visible)
            open = false
    }

    property Item anchorTarget: null
    anchor.item: anchorTarget
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 20
    onOpenChanged: {
        if (open) {
            visible = true
            anchor.updateAnchor()
        }
    }

    readonly property var defaultSink: Pipewire.defaultAudioSink

    property var outputStreams: []
    property var inputStreams: []
    property int streamWidth: 200
    
    property int _nodeCount: Pipewire.nodes.values.length
    
    function nodeLabel(n) {
        return n.nickname || n.description || n.name || ""
    }

    function updateStreams() {
        const outs = []
        const ins = []

        for (var n of Pipewire.nodes.values) {
            if (!n.audio)
                continue
            if (n.isStream && n.isSink)
                outs.push(n)
            else if (!n.isSink && !n.isStream)
                ins.push(n)
        }

        outputStreams = outs
        inputStreams = ins
    }
    on_NodeCountChanged: updateStreams()

    PwObjectTracker {
        objects: outputStreams.concat(inputStreams)
    }

    Component.onCompleted: updateStreams()

    Rectangle {
        id: content
        x: soundMenu.surfacePad
        y: -height
        width: parent.width - 2 * soundMenu.surfacePad
        height: parent.height - 2 * soundMenu.surfacePad
        color: Styles.soundMenu.background.color
        radius: Styles.soundMenu.background.radius
        border.width: Styles.soundMenu.background.border.width
        border.color: Styles.soundMenu.background.border.color
        clip: radius > 0

        NumberAnimation {
            id: openAnim
            target: content
            property: "y"
            from: -content.height
            to: soundMenu.surfacePad
            duration: 300
            easing.type: Easing.OutQuart

            onFinished: {
                if (!soundMenu.open)
                    soundMenu.visible = false
            }
        }

        Connections {
            target: soundMenu
            function onOpenChanged() {
                if (soundMenu.open) {
                    content.y = -content.height
                    openAnim.from = -content.height
                    openAnim.to = soundMenu.surfacePad
                    openAnim.start()
                } else {
                    openAnim.from = content.y
                    openAnim.to = -content.height
                    openAnim.start()
                }
            }
        }

        Column {
            id: streams
            anchors.centerIn: parent
            width: soundMenu.streamWidth
            spacing: Styles.soundMenu.spacing

            Rectangle {
                id: mainVolume
                width: streams.width
                height: 45
                color: Styles.soundMenu.section.color
                radius: Styles.soundMenu.section.radius
                clip: radius > 0
                border.width: Styles.soundMenu.section.border.width
                border.color: Styles.soundMenu.section.border.color

                BetterText {
                    id: mainVolumeLabel
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: Styles.soundMenu.section.text.anchors.topMargin
                    anchors.leftMargin: Styles.soundMenu.section.text.anchors.leftMargin
                    color: Styles.soundMenu.section.text.color
                    text: "Main Volume: " + Math.round((soundMenu.defaultSink?.audio?.volume ?? 0) * 100)
                }

                Slider {
                    id: defaultVolumeSlider
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Styles.soundMenu.section.slider.anchors.bottomMargin
                    anchors.leftMargin: Styles.soundMenu.section.slider.anchors.leftMargin
                    width: Styles.soundMenu.section.slider.width
                    from: 0.0
                    to: 1.5
                    live: true
                    value: soundMenu.defaultSink?.audio?.volume ?? 0
                    onMoved: {
                        if (soundMenu.defaultSink?.audio)
                            soundMenu.defaultSink.audio.volume = value
                    }

                    property alias bar: defaultBar

                    background: Rectangle {
                        x: defaultVolumeSlider.leftPadding
                        y: defaultVolumeSlider.topPadding + defaultVolumeSlider.availableHeight / 2 - height / 2
                        implicitHeight: 6
                        width: defaultVolumeSlider.availableWidth
                        height: implicitHeight
                        radius: Styles.soundMenu.slider.radius
                        color: Styles.soundMenu.slider.background.color

                        SliderFill {
                            id: defaultBar
                            position: defaultVolumeSlider.visualPosition
                            radius: Styles.soundMenu.slider.radius
                            color: Styles.soundMenu.slider.bar.color
                        }
                    }

                    handle: Rectangle {
                        implicitWidth: 0
                        implicitHeight: defaultVolumeSlider.height
                        x: defaultVolumeSlider.leftPadding
                            + defaultVolumeSlider.visualPosition * (defaultVolumeSlider.availableWidth - width)
                        y: 0
                    }
                }
            }

            Rectangle {
                id: sourcesSection
                width: streams.width
                color: Styles.soundMenu.section.color
                radius: Styles.soundMenu.section.radius
                clip: radius > 0
                border.width: Styles.soundMenu.section.border.width
                border.color: Styles.soundMenu.section.border.color
                implicitHeight: sourcesColumn.implicitHeight
                    + Styles.soundMenu.section.content.anchors.topMargin
                    + Styles.soundMenu.section.content.anchors.bottomMargin

                Column {
                    id: sourcesColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: Styles.soundMenu.section.content.anchors.topMargin
                    anchors.leftMargin: Styles.soundMenu.section.content.anchors.leftMargin
                    anchors.rightMargin: Styles.soundMenu.section.content.anchors.rightMargin
                    anchors.bottomMargin: Styles.soundMenu.section.content.anchors.bottomMargin
                    spacing: Styles.soundMenu.section.content.spacing

                    BetterText {
                        id: sourcesHeader
                        width: parent.width
                        color: Styles.soundMenu.section.text.color
                        anchors.topMargin: Styles.soundMenu.section.text.anchors.topMargin
                        anchors.leftMargin: Styles.soundMenu.section.text.anchors.leftMargin
                        text: "Sources:"
                    }

                    Repeater {
                        model: soundMenu.inputStreams

                        delegate: Column {
                            required property PwNode modelData
                            spacing: 4
                            width: sourcesColumn.width

                            BetterText {
                                id: sourceLabel
                                width: parent.width
                                color: Styles.soundMenu.section.text.color
                                text: soundMenu.nodeLabel(modelData) + ": " + Math.round(parent.modelData.audio.volume * 100)
                                elide: Text.ElideRight
                            }

                            Slider {
                                id: sourceSlider
                                width: parent.width
                                from: 0.0
                                to: 1.5
                                live: true
                                value: modelData.audio.volume
                                onMoved: modelData.audio.volume = value

                                property alias bar: sourceBar

                                background: Rectangle {
                                    x: sourceSlider.leftPadding
                                    y: sourceSlider.topPadding + sourceSlider.availableHeight / 2 - height / 2
                                    implicitHeight: 6
                                    width: sourceSlider.availableWidth
                                    height: implicitHeight
                                    radius: Styles.soundMenu.slider.radius
                                    color: Styles.soundMenu.slider.background.color

                                    SliderFill {
                                        id: sourceBar
                                        position: sourceSlider.visualPosition
                                        radius: Styles.soundMenu.slider.radius
                                        color: Styles.soundMenu.slider.bar.color
                                    }
                                }

                                handle: Rectangle {
                                    implicitWidth: 0
                                    implicitHeight: sourceSlider.height
                                    x: sourceSlider.leftPadding
                                        + sourceSlider.visualPosition * (sourceSlider.availableWidth - width)
                                    y: 0
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: appsSection
                width: streams.width
                color: Styles.soundMenu.section.color
                radius: Styles.soundMenu.section.radius
                clip: radius > 0
                border.width: Styles.soundMenu.section.border.width
                border.color: Styles.soundMenu.section.border.color
                implicitHeight: appsColumn.implicitHeight
                    + Styles.soundMenu.section.content.anchors.topMargin
                    + Styles.soundMenu.section.content.anchors.bottomMargin

                Column {
                    id: appsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: Styles.soundMenu.section.content.anchors.topMargin
                    anchors.leftMargin: Styles.soundMenu.section.content.anchors.leftMargin
                    anchors.rightMargin: Styles.soundMenu.section.content.anchors.rightMargin
                    anchors.bottomMargin: Styles.soundMenu.section.content.anchors.bottomMargin
                    spacing: Styles.soundMenu.section.content.spacing

                    BetterText {
                        id: appsHeader
                        width: parent.width
                        color: Styles.soundMenu.section.text.color
                        text: "Apps:"
                    }

                    Repeater {
                        model: soundMenu.outputStreams

                        delegate: Column {
                            required property PwNode modelData
                            spacing: 4
                            width: appsColumn.width

                            BetterText {
                                id: nameLabel
                                width: parent.width
                                color: Styles.soundMenu.section.text.color
                                text: soundMenu.nodeLabel(modelData) + ": " + Math.round(parent.modelData.audio.volume * 100)
                                elide: Text.ElideRight
                            }

                            Slider {
                                id: volumeSlider
                                width: parent.width
                                from: 0.0
                                to: 1.5
                                live: true
                                value: modelData.audio.volume
                                onMoved: modelData.audio.volume = value

                                property alias bar: bar

                                background: Rectangle {
                                    x: volumeSlider.leftPadding
                                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                    implicitHeight: 6
                                    width: volumeSlider.availableWidth
                                    height: implicitHeight
                                    radius: Styles.soundMenu.slider.radius
                                    color: Styles.soundMenu.slider.background.color

                                    SliderFill {
                                        id: bar
                                        position: volumeSlider.visualPosition
                                        radius: Styles.soundMenu.slider.radius
                                        color: Styles.soundMenu.slider.bar.color
                                    }
                                }

                                handle: Rectangle {
                                    implicitWidth: 0
                                    implicitHeight: volumeSlider.height
                                    x: volumeSlider.leftPadding
                                        + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                    y: 0
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}