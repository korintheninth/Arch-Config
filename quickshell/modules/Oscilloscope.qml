import QtQuick
import QtQuick.Shapes
import "../themes"
import "../services"

Item {
    id: scope

    property int displayWidth: Styles.oscilloscope.displayWidth
    property int displayHeight: Styles.oscilloscope.displayHeight
    implicitWidth: displayWidth
    implicitHeight: displayHeight
    clip: true

    property color traceColor: Styles.oscilloscope.color
    property color backgroundColor: Styles.oscilloscope.background
    property real lineWidth: Styles.oscilloscope.lineWidth
    property bool running: true
    property bool _held: false
    property var points: []

    function syncHold() {
        const want = running && visible
        if (want === _held)
            return
        if (want)
            OscilloscopeService.retain()
        else
            OscilloscopeService.release()
        _held = want
    }

    function rebuild() {
        const ys = OscilloscopeService.samples
        const n = ys.length
        const w = width
        const h = height
        if (n < 2 || w <= 1 || h <= 1) {
            points = []
            return
        }
        const count = Math.min(n, Math.max(2, Math.round(w)))
        const pts = new Array(count)
        const dx = (w - 1) / (count - 1)
        const hm = h - 1
        const last = count - 1
        for (let i = 0; i < count; i++) {
            const src = Math.round(i * (n - 1) / last)
            pts[i] = Qt.point(i * dx, ys[src] * hm)
        }
        points = pts
    }

    onRunningChanged: syncHold()
    onVisibleChanged: syncHold()
    onWidthChanged: rebuild()
    onHeightChanged: rebuild()
    Component.onCompleted: {
        syncHold()
        rebuild()
    }
    Component.onDestruction: {
        if (_held)
            OscilloscopeService.release()
    }

    Connections {
        target: OscilloscopeService
        function onSamplesChanged() {
            scope.rebuild()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: scope.backgroundColor
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true

        ShapePath {
            strokeWidth: Math.max(scope.lineWidth, 1)
            strokeColor: Qt.rgba(scope.traceColor.r, scope.traceColor.g, scope.traceColor.b, scope.traceColor.a * Styles.oscilloscope.intensity / 255)
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: scope.points
            }
        }
    }
}
