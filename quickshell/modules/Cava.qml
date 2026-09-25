import QtQuick
import "../themes"
import "../services"

Rectangle {
    id: cava

    anchors.verticalCenter: parent.bottom
    color: "transparent"
    property alias bars: bars
    property double barWidth: Styles.cava.barWidth
    property color barColor: Styles.cava.barColor
    property int barCount: 0
    property var cavaBars: []
    property bool running: true
    property bool _held: false
    anchors.leftMargin: Styles.cava.anchors.leftMargin

    function resample(src, count) {
        if (!src || src.length === 0 || count <= 0)
            return []
        const n = src.length
        if (count === n)
            return src
        const out = new Array(count)
        if (count < n) {
            for (let i = 0; i < count; i++) {
                const start = Math.floor(i * n / count)
                const end = Math.max(start + 1, Math.floor((i + 1) * n / count))
                let sum = 0
                for (let j = start; j < end; j++)
                    sum += src[j]
                out[i] = sum / (end - start)
            }
            return out
        }
        if (n === 1) {
            out.fill(src[0])
            return out
        }
        const last = count - 1
        for (let i = 0; i < count; i++) {
            const x = i * (n - 1) / last
            const i0 = Math.floor(x)
            const i1 = Math.min(n - 1, i0 + 1)
            const t = x - i0
            out[i] = src[i0] * (1 - t) + src[i1] * t
        }
        return out
    }

    function syncHold() {
        const want = running && visible
        if (want === _held)
            return
        if (want)
            CavaService.retain()
        else
            CavaService.release()
        _held = want
    }

    function rebuild() {
        if (!visible) {
            cavaBars = []
            return
        }
        const src = CavaService.bars
        const n = barCount > 0 ? barCount : src.length
        cavaBars = resample(src, n)
    }

    onRunningChanged: syncHold()
    onVisibleChanged: {
        syncHold()
        rebuild()
    }
    onBarCountChanged: rebuild()
    Component.onCompleted: {
        syncHold()
        rebuild()
    }
    Component.onDestruction: {
        if (_held)
            CavaService.release()
    }

    Connections {
        target: CavaService
        function onBarsChanged() {
            cava.rebuild()
        }
    }

    Row {
        id: bars
        anchors.fill: parent
        anchors.bottomMargin: Styles.cava.bars.anchors.bottomMargin
        spacing: Styles.cava.bars.spacing
        Repeater {
            model: cava.cavaBars.length

            Rectangle {
                width: cava.barWidth
                height: Math.max(0.0001, cava.cavaBars[index] * cava.height)
                color: cava.barColor
                anchors.bottom: parent.bottom
                Behavior on height {
                    NumberAnimation {
                        duration: 35
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
}
