import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../../components"
import "../../themes"

Item {
    id: panel

    readonly property var s: Styles.mpdClient.info
    property var info: ({ mode: "none" })

    readonly property string mode: info?.mode || "none"
    readonly property string coverPath: info?.cover ? ("file://" + info.cover) : ""

    function metaRows() {
        const rows = []
        const d = info || {}
        if (mode === "artist") {
            rows.push({ label: "artist", value: d.artist || "", name: true })
            rows.push({ label: "albums", value: String(d.albumCount ?? 0) })
            rows.push({ label: "songs", value: String(d.songCount ?? 0) })
            rows.push({ label: "duration", value: d.durationText || "0:00" })
        } else if (mode === "playlist") {
            rows.push({ label: "playlist", value: d.playlist || "", name: true })
            rows.push({ label: "songs", value: String(d.songCount ?? 0) })
            rows.push({ label: "duration", value: d.durationText || "0:00" })
        } else if (mode === "album") {
            rows.push({ label: "album", value: d.album || "", name: true })
            rows.push({ label: "artist", value: d.artist || "", name: true })
            if (d.originalDate || d.date)
                rows.push({ label: "date", value: d.originalDate || d.date })
            rows.push({ label: "tracks", value: String(d.trackCount ?? 0) })
            rows.push({ label: "duration", value: d.durationText || "0:00" })
            if (d.label)
                rows.push({ label: "label", value: d.label })
            if (d.genres && d.genres.length)
                rows.push({ label: "genre", value: d.genres.join(", ") })
            const extras = d.extras || {}
            for (const key of Object.keys(extras)) {
                const val = extras[key]
                if (val === undefined || val === null || val === "")
                    continue
                rows.push({ label: String(key).toLowerCase(), value: Array.isArray(val) ? val.join(", ") : String(val) })
            }
        } else if (mode === "song") {
            rows.push({ label: "title", value: d.title || "", name: true })
            rows.push({ label: "artist", value: d.artist || "", name: true })
            rows.push({ label: "album", value: d.album || "" })
            rows.push({ label: "duration", value: d.durationText || "0:00" })
            if (d.sampleRate)
                rows.push({
                    label: "sample rate",
                    value: (d.sampleRate >= 1000
                        ? (d.sampleRate / 1000) + " kHz"
                        : d.sampleRate + " Hz")
                })
            if (d.bits)
                rows.push({ label: "bit depth", value: d.bits + "-bit" })
            if (d.channels)
                rows.push({
                    label: "channels",
                    value: d.channels === 1 ? "mono" : d.channels === 2 ? "stereo" : String(d.channels)
                })
            if (d.originalDate || d.date)
                rows.push({ label: "date", value: d.originalDate || d.date })
            if (d.label)
                rows.push({ label: "label", value: d.label })
            if (d.genres && d.genres.length)
                rows.push({ label: "genre", value: d.genres.join(", ") })
            if (d.track)
                rows.push({ label: "track", value: String(d.track) })
            if (d.disc)
                rows.push({ label: "disc", value: String(d.disc) })
            const extras = d.extras || {}
            for (const key of Object.keys(extras)) {
                const val = extras[key]
                if (val === undefined || val === null || val === "")
                    continue
                rows.push({ label: String(key).toLowerCase(), value: Array.isArray(val) ? val.join(", ") : String(val) })
            }
        }
        return rows.filter(r => r.value !== "")
    }

    Rectangle {
        anchors.fill: parent
        color: panel.s.background.color
        radius: panel.s.background.radius
        border.width: panel.s.background.border.width
        border.color: panel.s.background.border.color
        clip: radius > 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: panel.s.padding
        spacing: panel.s.spacing
        visible: panel.mode !== "none"

        Item {
            id: coverFrame
            Layout.fillWidth: true
            Layout.preferredHeight: width
            visible: panel.coverPath.length > 0

            readonly property real coverRadius: panel.s.cover.radius

            Rectangle {
                id: coverMask
                anchors.fill: parent
                radius: coverFrame.coverRadius
                color: "white"
                visible: false
                layer.enabled: true
                layer.smooth: true
            }

            Rectangle {
                anchors.fill: parent
                radius: coverFrame.coverRadius
                color: panel.s.cover.placeholder
            }

            Image {
                id: cover
                anchors.fill: parent
                source: panel.coverPath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
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
                border.width: panel.s.cover.border.width
                border.color: panel.s.cover.border.color
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: metaColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: metaColumn
                width: parent.width
                spacing: panel.s.spacing

                Repeater {
                    model: panel.metaRows()

                    Column {
                        width: metaColumn.width
                        spacing: 1
                        required property var modelData

                        BetterText {
                            width: parent.width
                            text: modelData.label
                            color: panel.s.label.color
                            font.family: panel.s.label.font.family
                            font.pixelSize: panel.s.label.font.pixelSize
                            font.bold: panel.s.label.font.bold
                        }
                        BetterText {
                            width: parent.width
                            text: modelData.value
                            wrapMode: Text.Wrap
                            color: modelData.name ? panel.s.name.color : panel.s.value.color
                            font.family: modelData.name
                                ? panel.s.name.font.family
                                : panel.s.value.font.family
                            font.pixelSize: modelData.name
                                ? panel.s.name.font.pixelSize
                                : panel.s.value.font.pixelSize
                            font.bold: modelData.name
                                ? panel.s.name.font.bold
                                : panel.s.value.font.bold
                        }
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: parent.contentHeight > parent.height
                    ? ScrollBar.AsNeeded
                    : ScrollBar.AlwaysOff
                visible: parent.contentHeight > parent.height
                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: 3
                    color: Styles.fgBase
                }
            }
        }
    }

    BetterText {
        anchors.centerIn: parent
        visible: panel.mode === "none"
        text: "select something"
        color: panel.s.muted.color
        font.family: panel.s.muted.font.family
        font.pixelSize: panel.s.muted.font.pixelSize
    }
}
