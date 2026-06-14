import QtQuick

Item {
    id: root

    property string iconType: "play"
    property color color: "#ffffff"
    property int size: 16
    // Corner rounding in px; scales down on very small icons
    property real cornerRadius: 10

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = root.color

            const w = width
            const h = height
            if (w <= 0 || h <= 0)
                return

            const r = Math.min(root.cornerRadius, w * 0.12, h * 0.12)

            if (root.iconType === "play") {
                drawRoundedTriangle(ctx, w * 0.3, h * 0.18, w * 0.78, h * 0.5, w * 0.3, h * 0.82, r)
            } else if (root.iconType === "pause") {
                const barW = w * 0.16
                const gap = w * 0.14
                const left = (w - barW * 2 - gap) / 2
                const barR = Math.min(barW * 0.35, r)
                drawRoundedRect(ctx, left, h * 0.2, barW, h * 0.6, barR)
                drawRoundedRect(ctx, left + barW + gap, h * 0.2, barW, h * 0.6, barR)
            } else if (root.iconType === "prev") {
                drawRoundedTriangle(ctx, w * 0.75, h * 0.18, w * 0.45, h * 0.5, w * 0.75, h * 0.82, r)
                drawRoundedTriangle(ctx, w * 0.45, h * 0.18, w * 0.15, h * 0.5, w * 0.45, h * 0.82, r)
            } else if (root.iconType === "next") {
                drawRoundedTriangle(ctx, w * 0.25, h * 0.18, w * 0.55, h * 0.5, w * 0.25, h * 0.82, r)
                drawRoundedTriangle(ctx, w * 0.55, h * 0.18, w * 0.85, h * 0.5, w * 0.55, h * 0.82, r)
            }
        }

        function drawRoundedTriangle(ctx, x1, y1, x2, y2, x3, y3, radius) {
            const pts = [
                [x1, y1], [x2, y2], [x3, y3]
            ]
            ctx.beginPath()
            for (let i = 0; i < 3; ++i) {
                const [cx, cy] = pts[i]
                const [px, py] = pts[(i + 2) % 3]
                const [nx, ny] = pts[(i + 1) % 3]
                const v1x = cx - px, v1y = cy - py
                const v2x = nx - cx, v2y = ny - cy
                const len1 = Math.hypot(v1x, v1y)
                const len2 = Math.hypot(v2x, v2y)
                const rad = Math.min(radius, len1 * 0.45, len2 * 0.45)
                const sx = cx - v1x / len1 * rad
                const sy = cy - v1y / len1 * rad
                const ex = cx + v2x / len2 * rad
                const ey = cy + v2y / len2 * rad
                if (i === 0)
                    ctx.moveTo(sx, sy)
                else
                    ctx.lineTo(sx, sy)
                ctx.quadraticCurveTo(cx, cy, ex, ey)
            }
            ctx.closePath()
            ctx.fill()
        }

        function drawRoundedRect(ctx, x, y, w, h, radius) {
            const r = Math.min(radius, w / 2, h / 2)
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + w - r, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + r)
            ctx.lineTo(x + w, y + h - r)
            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
            ctx.lineTo(x + r, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - r)
            ctx.lineTo(x, y + r)
            ctx.quadraticCurveTo(x, y, x + r, y)
            ctx.closePath()
            ctx.fill()
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: root
            function onColorChanged() { canvas.requestPaint() }
            function onIconTypeChanged() { canvas.requestPaint() }
            function onCornerRadiusChanged() { canvas.requestPaint() }
        }
    }
}
