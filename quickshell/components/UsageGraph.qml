import QtQuick
import Quickshell

Rectangle {
    id: graph

    property double max: 100.0
    property double min: 0.0
    property int maxSamples: 60
    property var samples: []
    property color lineColor: "black"
    property color fillColor: "black"
    property string text: ""
    property int leftMargin: 0
    property alias label: label

    clip: true

    function cssColor(c) {
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + ","
            + Math.round(c.b * 255) + "," + c.a + ")"
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = height
            ctx.reset()
            ctx.clearRect(0, 0, w, h)

            const r = Math.max(0, Math.min(graph.radius, w / 2, h / 2))
            if (r > 0) {
                ctx.beginPath()
                ctx.moveTo(r, 0)
                ctx.arcTo(w, 0, w, h, r)
                ctx.arcTo(w, h, 0, h, r)
                ctx.arcTo(0, h, 0, 0, r)
                ctx.arcTo(0, 0, w, 0, r)
                ctx.closePath()
                ctx.clip()
            }

            const pts = graph.samples
            if (!pts || pts.length === 0 || w <= 0 || h <= 0)
                return

            const range = graph.max - graph.min
            if (range <= 0)
                return

            const n = pts.length
            const dx = w / Math.max(graph.maxSamples - 1, 1)

            function xAt(i) {
                return w - (n - 1 - i) * dx
            }
            function yAt(v) {
                const t = (Math.max(graph.min, Math.min(graph.max, Number(v) || 0)) - graph.min) / range
                return h - t * h
            }

            ctx.beginPath()
            ctx.moveTo(xAt(0), h)
            for (let i = 0; i < n; i++)
                ctx.lineTo(xAt(i), yAt(pts[i]))
            ctx.lineTo(xAt(n - 1), h)
            ctx.closePath()
            ctx.fillStyle = graph.cssColor(graph.fillColor)
            ctx.fill()

            ctx.beginPath()
            ctx.moveTo(xAt(0), yAt(pts[0]))
            for (let i = 1; i < n; i++)
                ctx.lineTo(xAt(i), yAt(pts[i]))
            ctx.strokeStyle = graph.cssColor(graph.lineColor)
            ctx.lineWidth = 1.5
            ctx.lineJoin = "round"
            ctx.stroke()
        }
    }

    onSamplesChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onLineColorChanged: canvas.requestPaint()
    onFillColorChanged: canvas.requestPaint()
    onMaxChanged: canvas.requestPaint()
    onMinChanged: canvas.requestPaint()
    onMaxSamplesChanged: canvas.requestPaint()
    onRadiusChanged: canvas.requestPaint()

    BetterText {
        id: label
        text: graph.text
        color: "white"
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: graph.leftMargin
    }
}
