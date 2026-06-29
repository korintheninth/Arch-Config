import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../components"
import "../themes"
import "../themes/StyleEngine.js" as Styler

PopupWindow {
    id: soundMenu
    color: "transparent"
    implicitHeight: content.height + 10
    implicitWidth: content.width + 10
    
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

    function applyStreamSliderStyles(slider) {
        Styler.apply(slider, Styles.soundMenu.slider)
    }

    function applyStreamLabelStyle(label) {
        Styler.apply(label, Styles.soundMenu.section.text)
    }

    Component.onCompleted: {
        Styler.apply(soundMenu, Styles.soundMenu)
        Styler.apply(mainVolumeLabel, Styles.soundMenu.section.text)
        Styler.apply(defaultVolumeSlider, Styles.soundMenu.slider)
        Styler.apply(defaultVolumeSlider, Styles.soundMenu.section.slider)
        Styler.apply(mainVolume, Styles.soundMenu.section)
        Styler.apply(sourcesColumn, Styles.soundMenu.section.content)
        Styler.apply(sourcesHeader, Styles.soundMenu.section.text)
        Styler.apply(sourcesSection, Styles.soundMenu.section)
        Styler.apply(appsColumn, Styles.soundMenu.section.content)
        Styler.apply(appsHeader, Styles.soundMenu.section.text)
        Styler.apply(appsSection, Styles.soundMenu.section)
        updateStreams()
    }

    Rectangle {
        id: content
        width: soundMenu.streamWidth + 24
        height: streams.implicitHeight + 24


        transform: Rotation {
            id: xAxisRotation
            origin.x: content.width / 2
            axis { x: 1; y: 0; z: 0 } 
            angle: -90 
        }
        
        color: "transparent"

        NumberAnimation {
            id: openAnim
            target: xAxisRotation
            property: "angle"
            from: -90
            to: 0
            duration: 300
            
            easing.type: Easing.OutBack

            onFinished: {
                if (!soundMenu.open)
                    soundMenu.visible = false
            }
        }

        Connections {
            target: soundMenu
            function onOpenChanged() {
                if (soundMenu.open) {
                    xAxisRotation.angle = -90
                    openAnim.from = -90
                    openAnim.to = 0
                    openAnim.start()
                } else {
                    openAnim.from = xAxisRotation.angle
                    openAnim.to = -90
                    openAnim.start()
                }
            }
        }

        Column {
            id: streams
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: soundMenu.streamWidth
            spacing: 0

            Rectangle {
                id: mainVolume
                width: streams.width
                height: 45

                BetterText {
                    id: mainVolumeLabel
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "Main Volume: " + Math.round(soundMenu.defaultSink.audio.volume * 100)
                }

                Slider {
                    id: defaultVolumeSlider
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    from: 0.0
                    to: 1.5
                    live: true
                    value: soundMenu.defaultSink.audio.volume
                    onMoved: soundMenu.defaultSink.audio.volume = value

                    property alias bar: defaultBar

                    background: Rectangle {
                        x: defaultVolumeSlider.leftPadding
                        y: defaultVolumeSlider.topPadding + defaultVolumeSlider.availableHeight / 2 - height / 2
                        implicitHeight: 6
                        width: defaultVolumeSlider.availableWidth
                        height: implicitHeight
                        radius: 0

                        Rectangle {
                            id: defaultBar
                            width: parent.width * defaultVolumeSlider.visualPosition
                            height: parent.height
                            radius: 0
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
                implicitHeight: sourcesColumn.implicitHeight
                    + Styles.soundMenu.section.content.anchors.topMargin
                    + Styles.soundMenu.section.content.anchors.bottomMargin

                Column {
                    id: sourcesColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    spacing: Styles.soundMenu.section.content.spacing

                    BetterText {
                        id: sourcesHeader
                        width: parent.width
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
                                text: soundMenu.nodeLabel(modelData) + ": " + Math.round(parent.modelData.audio.volume * 100)
                                elide: Text.ElideRight
                                Component.onCompleted: soundMenu.applyStreamLabelStyle(this)
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

                                Component.onCompleted: soundMenu.applyStreamSliderStyles(this)

                                background: Rectangle {
                                    x: sourceSlider.leftPadding
                                    y: sourceSlider.topPadding + sourceSlider.availableHeight / 2 - height / 2
                                    implicitHeight: 6
                                    width: sourceSlider.availableWidth
                                    height: implicitHeight
                                    radius: 0

                                    Rectangle {
                                        id: sourceBar
                                        width: parent.width * sourceSlider.visualPosition
                                        height: parent.height
                                        radius: 0
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
                implicitHeight: appsColumn.implicitHeight
                    + Styles.soundMenu.section.content.anchors.topMargin
                    + Styles.soundMenu.section.content.anchors.bottomMargin

                Column {
                    id: appsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    BetterText {
                        id: appsHeader
                        width: parent.width
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
                                text: soundMenu.nodeLabel(modelData) + ": " + Math.round(parent.modelData.audio.volume * 100)
                                elide: Text.ElideRight
                                Component.onCompleted: soundMenu.applyStreamLabelStyle(this)
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

                                Component.onCompleted: soundMenu.applyStreamSliderStyles(this)

                                background: Rectangle {
                                    x: volumeSlider.leftPadding
                                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                    implicitHeight: 6
                                    width: volumeSlider.availableWidth
                                    height: implicitHeight
                                    radius: 0

                                    Rectangle {
                                        id: bar
                                        width: parent.width * volumeSlider.visualPosition
                                        height: parent.height
                                        radius: 0
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