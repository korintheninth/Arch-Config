import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../themes"
import "../../components"
import "../../services"

Item {
    id: bar

    readonly property var s: Styles.mpdClient.playerBar
    implicitHeight: s.height
    property bool queueOpen: false
    property bool lyricsOpen: false
    property var songMeta: ({})
    property string activeLyric: ""
    property var eePresets: []
    property string eeCurrent: ""
    property bool presetMenuOpen: false

    readonly property int pad: s.padding
    readonly property int gap: s.spacing

    readonly property string metaLine: {
        const m = songMeta || {}
        const maxChars = bar.s.meta?.maxChars ?? 18
        const clip = (value) => {
            const text = String(value ?? "")
            if (!maxChars || text.length <= maxChars)
                return text
            return text.slice(0, Math.max(maxChars - 1, 1)) + "…"
        }
        const parts = []
        if (m.track)
            parts.push(clip(m.track))
        if (m.genre)
            parts.push(clip(m.genre))
        if (m.sampleRate || m.bits) {
            let audio = ""
            if (m.sampleRate) {
                const sr = Number(m.sampleRate)
                audio = sr >= 1000 ? ((sr / 1000) + " kHz") : (sr + " Hz")
            }
            if (m.bits)
                audio += (audio ? " " : "") + String(m.bits) + "-bit"
            parts.push(clip(audio))
        }
        return parts.join(bar.s.meta?.spacing ?? " · ")
    }

    function refreshActiveLyric() {
        const key = LyricsService.trackKey
        const lines = key ? LyricsService.lyricsMap[key] : null
        if (!lines || lines.length <= 0) {
            activeLyric = ""
            return
        }
        const position = PlayerService.position
        let after = 0
        while (after < lines.length && lines[after].timestamp <= position + 0.15)
            after += 1
        for (let i = after - 1; i >= 0; i--) {
            const lyric = String(lines[i].lyric ?? "").trim()
            if (lyric) {
                activeLyric = lines[i].lyric
                return
            }
        }
        activeLyric = ""
    }

    function refreshSongMeta() {
        if (!PlayerService.active) {
            songMeta = ({})
            return
        }
        metaProc.exec(["currentsong"])
    }

    function parseEePresets(text) {
        const lines = String(text || "").split("\n")
        const out = []
        let section = ""
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line)
                continue
            const lower = line.toLowerCase()
            if (lower.startsWith("output presets")) {
                section = "output"
                continue
            }
            if (lower.startsWith("input presets") || lower.startsWith("no input"))
                break
            if (section !== "output")
                continue
            const match = line.match(/^\d+\s+(.+)$/)
            if (match && match[1])
                out.push(match[1].trim())
        }
        return out
    }

    function run(proc) {
        proc.running = false
        Qt.callLater(() => proc.running = true)
    }

    function eeIsRunning(text) {
        const lines = String(text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (line.includes("easyeffects") && !line.includes("grep"))
                return true
        }
        return false
    }

    function loadEePreset(name) {
        const preset = String(name || "").trim()
        if (!preset)
            return
        presetMenuOpen = false
        eeCurrent = preset
        loadOutputPreset.command = ["easyeffects", "-l", preset]
        run(checkEasyEffects)
        run(loadOutputPreset)
    }

    Connections {
        target: PlayerService
        function onTrackTitleChanged() {
            bar.refreshSongMeta()
            LyricsService.updateLyrics()
            bar.refreshActiveLyric()
        }
        function onTrackArtistChanged() {
            bar.refreshSongMeta()
            LyricsService.updateLyrics()
            bar.refreshActiveLyric()
        }
        function onTrackAlbumChanged() { bar.refreshSongMeta() }
        function onActiveChanged() {
            bar.refreshSongMeta()
            if (PlayerService.active)
                LyricsService.updateLyrics()
            bar.refreshActiveLyric()
        }
        function onIsPlayingChanged() {
            if (PlayerService.isPlaying)
                bar.refreshSongMeta()
        }
        function onTick() { bar.refreshActiveLyric() }
        function onPositionChanged() { bar.refreshActiveLyric() }
    }

    Connections {
        target: LyricsService
        function onLyricsMapChanged() { bar.refreshActiveLyric() }
        function onTrackKeyChanged() { bar.refreshActiveLyric() }
    }

    Component.onCompleted: {
        refreshSongMeta()
        LyricsService.updateLyrics()
        refreshActiveLyric()
        run(checkEasyEffects)
    }

    ToolProcess {
        id: metaProc
        tag: "mpd-currentsong"
        onResult: (data) => {
            if (!data || !data.ok) {
                bar.songMeta = ({})
                return
            }
            bar.songMeta = data
        }
    }

    Process {
        id: checkEasyEffects
        command: ["sh", "-c", "ps -e | grep easyeffects"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (bar.eeIsRunning(text)) {
                    bar.run(readActivePreset)
                    bar.run(listOutputPresets)
                } else
                    Quickshell.execDetached(["easyeffects"])
            }
        }
    }

    Process {
        id: readActivePreset
        command: ["easyeffects", "-a", "output"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim()
                if (name)
                    bar.eeCurrent = name
            }
        }
    }

    Process {
        id: listOutputPresets
        command: ["easyeffects", "-p"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: bar.eePresets = bar.parseEePresets(text)
        }
    }

    Process {
        id: loadOutputPreset
        running: false
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: bar.s.background.color
        radius: bar.s.background.radius
        border.width: bar.s.background.border.width
        border.color: bar.s.background.border.color
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: bar.pad
        spacing: bar.gap

        Item {
            id: coverFrame
            Layout.preferredWidth: bar.s.cover.width
            Layout.preferredHeight: bar.s.cover.height
            Layout.alignment: Qt.AlignVCenter
            property int coverRadius: bar.s.cover.radius
            property int coverBorderWidth: bar.s.cover.border.width
            property color coverBorderColor: bar.s.cover.border.color

            Rectangle {
                id: coverMask
                anchors.fill: parent
                radius: coverFrame.coverRadius
                color: bar.s.cover.mask.color
                visible: false
                layer.enabled: true
                layer.smooth: true
            }

            Rectangle {
                anchors.fill: parent
                radius: coverFrame.coverRadius
                color: bar.s.cover.placeholder.color
            }

            Image {
                id: cover
                anchors.fill: parent
                source: PlayerService.trackArtUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: status === Image.Ready
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: coverMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: coverFrame.coverRadius
                color: "transparent"
                border.width: coverFrame.coverBorderWidth
                border.color: coverFrame.coverBorderColor
            }
        }

        Slider {
            id: volumeSlider
            Layout.preferredWidth: bar.s.volumeSlider.implicitWidth
            Layout.preferredHeight: bar.s.cover.height
            Layout.alignment: Qt.AlignVCenter
            orientation: Qt.Vertical
            from: 0.0
            to: 1.0
            live: true
            enabled: PlayerService.active

            Binding {
                target: volumeSlider
                property: "value"
                value: PlayerService.volume
                when: !volumeSlider.pressed
            }

            onMoved: PlayerService.setVolume(value)

            background: Rectangle {
                x: volumeSlider.leftPadding + volumeSlider.availableWidth / 2 - width / 2
                y: volumeSlider.topPadding
                width: volumeSlider.implicitWidth
                height: volumeSlider.availableHeight
                radius: bar.s.slider.radius
                color: bar.s.slider.background.color

                SliderFill {
                    orientation: Qt.Vertical
                    position: volumeSlider.position
                    radius: bar.s.slider.radius
                    color: bar.s.slider.bar.color
                }
            }

            handle: Rectangle {
                implicitWidth: volumeSlider.width
                implicitHeight: 0
                color: bar.s.slider.handle.color
                x: 0
                y: volumeSlider.topPadding + volumeSlider.visualPosition * (volumeSlider.availableHeight - height)
            }
        }

        ColumnLayout {
            id: controlsGroup
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: bar.gap

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: bar.s.text.spacing

                    BetterText {
                        width: parent.width
                        color: bar.s.text.color
                        font.family: bar.s.text.font.family
                        font.pixelSize: bar.s.text.font.pixelSize
                        font.bold: bar.s.text.font.bold
                        elide: Text.ElideRight
                        text: PlayerService.trackTitle
                    }
                    BetterText {
                        width: parent.width
                        color: bar.s.text.color
                        font.family: bar.s.text.font.family
                        font.pixelSize: bar.s.text.font.pixelSize
                        font.bold: bar.s.text.font.bold
                        elide: Text.ElideRight
                        text: {
                            const artist = PlayerService.trackArtist
                            const album = PlayerService.trackAlbum
                            if (artist && album)
                                return artist + " - " + album
                            return artist || album || ""
                        }
                    }
                }
            }

            Item {
                id: seekBlock
                Layout.fillWidth: true
                Layout.preferredHeight: bar.s.seekSlider.implicitHeight

                Slider {
                    id: seekSlider
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: bar.s.seekSlider.implicitHeight
                    from: 0
                    to: Math.max(PlayerService.length, 0.001)
                    live: true
                    enabled: PlayerService.active && PlayerService.length > 0

                    Binding {
                        target: seekSlider
                        property: "value"
                        value: PlayerService.position
                        when: !seekSlider.pressed
                    }

                    onMoved: PlayerService.seek(value)

                    background: Rectangle {
                        x: seekSlider.leftPadding
                        y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                        width: seekSlider.availableWidth
                        height: seekSlider.implicitHeight
                        radius: bar.s.slider.radius
                        color: bar.s.slider.background.color

                        SliderFill {
                            position: seekSlider.visualPosition
                            radius: bar.s.slider.radius
                            color: bar.s.slider.bar.color
                        }
                    }

                    handle: Rectangle {
                        implicitWidth: 0
                        implicitHeight: seekSlider.height
                        color: bar.s.slider.handle.color
                        x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                        y: 0
                    }
                }

                BetterText {
                    id: timeLabel
                    anchors.right: seekSlider.right
                    anchors.top: seekSlider.bottom
                    anchors.topMargin: bar.s.text.bottomMargin
                    color: bar.s.time.color
                    font.family: bar.s.time.font.family
                    font.pixelSize: bar.s.time.font.pixelSize
                    font.bold: bar.s.time.font.bold
                    text: PlayerService.active
                        ? PlayerService.formatTime(PlayerService.position)
                            + " / " + PlayerService.formatTime(PlayerService.length)
                        : "0:00 / 0:00"
                }

                BetterText {
                    anchors.left: seekSlider.left
                    anchors.right: timeLabel.left
                    anchors.rightMargin: bar.s.meta?.rightMargin ?? 12
                    anchors.top: seekSlider.bottom
                    anchors.topMargin: bar.s.text.bottomMargin
                    color: bar.s.meta?.color ?? bar.s.time.color
                    font.family: bar.s.meta?.font?.family ?? bar.s.time.font.family
                    font.pixelSize: bar.s.meta?.font?.pixelSize ?? bar.s.time.font.pixelSize
                    font.bold: bar.s.meta?.font?.bold ?? false
                    elide: Text.ElideRight
                    visible: bar.metaLine.length > 0
                    text: bar.metaLine
                }

                Item {
                    id: queueToggle
                    anchors.right: seekSlider.right
                    anchors.bottom: seekSlider.top
                    anchors.bottomMargin: 6
                    width: bar.s.queueToggle.size
                    height: bar.s.queueToggle.size

                    Rectangle {
                        anchors.fill: parent
                        radius: bar.s.queueToggle.radius
                        color: queueMouse.containsMouse || bar.queueOpen
                            ? bar.s.queueToggle.hoverColor
                            : "transparent"
                    }

                    BetterText {
                        anchors.centerIn: parent
                        text: "›"
                        color: queueMouse.containsMouse || bar.queueOpen
                            ? bar.s.queueToggle.activeColor
                            : bar.s.queueToggle.color
                        font.family: bar.s.queueToggle.font.family
                        font.pixelSize: bar.s.queueToggle.font.pixelSize
                        font.bold: true
                        rotation: bar.queueOpen ? -90 : 0
                        Behavior on rotation {
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        id: queueMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.queueOpen = !bar.queueOpen
                    }
                }
            }

            // Reserve vertical space so seek stays above the bar-centered buttons.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: bar.s.button.size
            }
        }
    }

    Item {
        id: lyricButton
        anchors.horizontalCenter: mediaButtons.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: bar.s.lyrics?.topMargin ?? 4
        height: Math.max(bar.s.lyrics?.minHeight ?? 26, lyricLabel.implicitHeight)
        width: Math.max(bar.s.lyrics?.minWidth ?? 311, Math.min(lyricLabel.implicitWidth, Math.round(bar.width * 0.45)))
        z: 1

        Rectangle {
            anchors.fill: parent
            radius: bar.s.lyrics?.radius ?? 6
            color: lyricMouse.containsMouse || bar.lyricsOpen
                ? (bar.s.lyrics?.hoverColor ?? Qt.rgba(0, 0, 0, 0.1))
                : "transparent"
        }

        BetterText {
            id: lyricLabel
            anchors.centerIn: parent
            width: parent.width
            color: bar.s.lyrics?.color ?? bar.s.text.color
            font.family: bar.s.lyrics?.font?.family ?? bar.s.text.font.family
            font.pixelSize: bar.s.lyrics?.font?.pixelSize ?? bar.s.text.font.pixelSize
            font.bold: bar.s.lyrics?.font?.bold ?? false
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: bar.activeLyric.length > 0 ? bar.activeLyric : "..."
        }

        MouseArea {
            id: lyricMouse
            anchors.fill: parent
            enabled: lyricButton.visible
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bar.lyricsOpen = !bar.lyricsOpen
        }
    }

    Row {
        id: mediaButtons
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: bar.pad
        height: bar.s.button.size
        spacing: bar.s.toggle.spacing

        Item {
            width: bar.s.toggle.size
            height: parent.height
            Button {
                id: shuffleBtn
                anchors.centerIn: parent
                implicitWidth: bar.s.toggle.size
                implicitHeight: bar.s.toggle.size
                padding: 0
                hoverEnabled: true
                enabled: PlayerService.active && PlayerService.shuffleSupported && PlayerService.canControl
                display: AbstractButton.IconOnly
                icon.source: "../../icons/shuffle.svg"
                icon.width: bar.s.toggle.iconSize
                icon.height: bar.s.toggle.iconSize
                icon.color: {
                    if (pressed || hovered || PlayerService.shuffle)
                        return bar.s.toggle.onColor
                    return bar.s.toggle.offColor
                }
                background: Rectangle {
                    anchors.fill: parent
                    radius: bar.s.toggle.radius
                    color: shuffleBtn.pressed
                        ? bar.s.toggle.pressedColor
                        : shuffleBtn.hovered ? bar.s.toggle.hoverColor : bar.s.toggle.normalColor
                }
                onClicked: PlayerService.toggleShuffle()
            }
        }

        Row {
            spacing: bar.s.controls.spacing
            height: parent.height

            MediaMenuButton {
                anchors.verticalCenter: parent.verticalCenter
                iconType: "prev"
                size: bar.s.button.size
                radius: bar.s.button.radius
                normalColor: bar.s.button.normalColor
                hoverColor: bar.s.button.hoverColor
                pressedColor: bar.s.button.pressedColor
                iconSize: bar.s.button.iconSize
                iconColor: bar.s.button.iconColor
                iconHoverColor: bar.s.button.iconHoverColor
                iconPressedColor: bar.s.button.iconPressedColor
                shadow: bar.s.button.shadow
                enabled: PlayerService.active
                onClicked: PlayerService.previous()
            }
            MediaMenuButton {
                anchors.verticalCenter: parent.verticalCenter
                iconType: PlayerService.isPlaying ? "pause" : "play"
                size: bar.s.button.size
                radius: bar.s.button.radius
                normalColor: bar.s.button.normalColor
                hoverColor: bar.s.button.hoverColor
                pressedColor: bar.s.button.pressedColor
                iconSize: bar.s.button.iconSize
                iconColor: bar.s.button.iconColor
                iconHoverColor: bar.s.button.iconHoverColor
                iconPressedColor: bar.s.button.iconPressedColor
                shadow: bar.s.button.shadow
                enabled: PlayerService.active
                onClicked: PlayerService.togglePlayPause()
            }
            MediaMenuButton {
                anchors.verticalCenter: parent.verticalCenter
                iconType: "next"
                size: bar.s.button.size
                radius: bar.s.button.radius
                normalColor: bar.s.button.normalColor
                hoverColor: bar.s.button.hoverColor
                pressedColor: bar.s.button.pressedColor
                iconSize: bar.s.button.iconSize
                iconColor: bar.s.button.iconColor
                iconHoverColor: bar.s.button.iconHoverColor
                iconPressedColor: bar.s.button.iconPressedColor
                shadow: bar.s.button.shadow
                enabled: PlayerService.active
                onClicked: PlayerService.next()
            }
        }

        Item {
            width: bar.s.toggle.size
            height: parent.height
            Button {
                id: loopBtn
                anchors.centerIn: parent
                implicitWidth: bar.s.toggle.size
                implicitHeight: bar.s.toggle.size
                padding: 0
                hoverEnabled: true
                enabled: PlayerService.active && PlayerService.loopSupported && PlayerService.canControl
                display: AbstractButton.IconOnly
                icon.source: PlayerService.loopMode === "one"
                    ? "../../icons/repeat-once.svg"
                    : "../../icons/repeat.svg"
                icon.width: bar.s.toggle.iconSize
                icon.height: bar.s.toggle.iconSize
                icon.color: {
                    if (pressed || hovered || PlayerService.loopMode !== "off")
                        return bar.s.toggle.onColor
                    return bar.s.toggle.offColor
                }
                background: Rectangle {
                    anchors.fill: parent
                    radius: bar.s.toggle.radius
                    color: loopBtn.pressed
                        ? bar.s.toggle.pressedColor
                        : loopBtn.hovered ? bar.s.toggle.hoverColor : bar.s.toggle.normalColor
                }
                onClicked: PlayerService.cycleLoop()
            }
        }
    }

    Item {
        id: presetButton
        readonly property var ee: bar.s.easyeffects
        anchors.left: mediaButtons.right
        anchors.leftMargin: ee?.margin ?? 16
        anchors.verticalCenter: mediaButtons.verticalCenter
        height: ee?.height ?? 26
        width: Math.min(
            ee?.maxWidth ?? 120,
            Math.max(presetLabel.implicitWidth + (ee?.padding ?? 8) * 2, height)
        )
        z: 2

        Rectangle {
            anchors.fill: parent
            radius: presetButton.ee?.radius ?? 6
            color: presetButtonMouse.containsMouse || bar.presetMenuOpen
                ? (presetButton.ee?.hoverColor ?? "transparent")
                : "transparent"
        }

        BetterText {
            id: presetLabel
            anchors.centerIn: parent
            width: parent.width - (presetButton.ee?.padding ?? 8) * 2
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: bar.eeCurrent || "fx"
            color: presetButtonMouse.containsMouse || bar.presetMenuOpen
                ? (presetButton.ee?.activeColor ?? bar.s.text.color)
                : (presetButton.ee?.color ?? bar.s.text.color)
            font.family: presetButton.ee?.font?.family ?? bar.s.text.font.family
            font.pixelSize: presetButton.ee?.font?.pixelSize ?? bar.s.text.font.pixelSize
        }

        MouseArea {
            id: presetButtonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (bar.presetMenuOpen) {
                    bar.presetMenuOpen = false
                    return
                }
                bar.presetMenuOpen = true
            }
        }

        Rectangle {
            id: presetMenu
            visible: bar.presetMenuOpen
            anchors.left: parent.left
            anchors.bottom: parent.top
            anchors.bottomMargin: 6
            width: Math.max(parent.width, presetButton.ee?.menu?.width ?? 140)
            height: Math.min(
                (presetButton.ee?.menu?.itemHeight ?? 24) * Math.max(bar.eePresets.length, 1)
                    + (presetButton.ee?.menu?.padding ?? 4) * 2
                    + Math.max(bar.eePresets.length - 1, 0) * (presetButton.ee?.menu?.spacing ?? 2),
                (presetButton.ee?.menu?.itemHeight ?? 24) * 6
                    + (presetButton.ee?.menu?.padding ?? 4) * 2
                    + 5 * (presetButton.ee?.menu?.spacing ?? 2)
            )
            radius: presetButton.ee?.menu?.radius ?? 8
            color: presetButton.ee?.menu?.background ?? bar.s.background.color
            border.width: presetButton.ee?.menu?.border?.width ?? 1
            border.color: presetButton.ee?.menu?.border?.color ?? bar.s.background.border.color
            clip: true
            z: 3

            ListView {
                id: presetList
                anchors.fill: parent
                anchors.margins: presetButton.ee?.menu?.padding ?? 4
                spacing: presetButton.ee?.menu?.spacing ?? 2
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: bar.eePresets
                visible: bar.eePresets.length > 0

                delegate: Item {
                    width: presetList.width
                    height: presetButton.ee?.menu?.itemHeight ?? 24
                    readonly property bool selected: modelData === bar.eeCurrent

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: selected
                            ? (presetButton.ee?.menu?.itemActiveColor ?? "transparent")
                            : (presetItemMouse.containsMouse
                                ? (presetButton.ee?.menu?.itemHoverColor ?? "transparent")
                                : "transparent")
                    }

                    BetterText {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: modelData
                        color: selected || presetItemMouse.containsMouse
                            ? (presetButton.ee?.activeColor ?? bar.s.text.color)
                            : (presetButton.ee?.color ?? bar.s.text.color)
                        font.family: presetButton.ee?.font?.family ?? bar.s.text.font.family
                        font.pixelSize: presetButton.ee?.font?.pixelSize ?? bar.s.text.font.pixelSize
                    }

                    MouseArea {
                        id: presetItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.loadEePreset(modelData)
                    }
                }
            }

            BetterText {
                anchors.centerIn: parent
                visible: bar.eePresets.length === 0
                text: "no presets"
                color: presetButton.ee?.color ?? bar.s.text.color
                font.family: presetButton.ee?.font?.family ?? bar.s.text.font.family
                font.pixelSize: presetButton.ee?.font?.pixelSize ?? bar.s.text.font.pixelSize
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: bar.presetMenuOpen
        z: 1
        onClicked: bar.presetMenuOpen = false
    }

    Rectangle {
        anchors.fill: bg
        radius: bg.radius
        color: "transparent"
        border.width: bar.s.background.border.width
        border.color: bar.s.background.border.color
    }
}
