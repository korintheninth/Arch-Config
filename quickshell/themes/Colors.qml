pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: colors

    property color color8: "#050505"
    property color color9: "#ACACAC"
    property color color0: "#313131"
    property color color1: "#484848"
    property color color2: "#666666"
    property color color3: "#7B7B7B"
    property color color4: "#7B7B7B"
    property color color5: "#8E8E8E"
    property color color6: "#ACACAC"
    property color color7: "#808080"

    readonly property string cachePath: `${Quickshell.env("HOME")}/.cache/quickshell/colors.qml`

    function apply(data) {
        const keys = [
            "color0", "color1", "color2", "color3", "color4",
            "color5", "color6", "color7", "color8", "color9"
        ]
        for (let i = 0; i < keys.length; i++) {
            const key = keys[i]
            if (data[key] !== undefined && data[key] !== null && data[key] !== "")
                colors[key] = data[key]
        }
    }

    function reload() {
        cacheFile.reload()
    }

    function loadFromCache(text) {
        const matches = text.match(/property color (color\d+):\s*"([^"]+)"/g)
        if (!matches)
            return
        const data = {}
        for (let i = 0; i < matches.length; i++) {
            const parts = matches[i].match(/property color (color\d+):\s*"([^"]+)"/)
            if (parts)
                data[parts[1]] = parts[2]
        }
        apply(data)
    }

    FileView {
        id: cacheFile
        path: colors.cachePath
        printErrors: false
        onLoaded: colors.loadFromCache(text())
    }

    IpcHandler {
        target: "colors"

        function reload(): void {
            colors.reload()
        }

        function apply(json: string): void {
            try {
                colors.apply(JSON.parse(json))
            } catch (e) {
                console.error("colors.apply:", e)
            }
        }

        function set(name: string, value: string): void {
            const keys = [
                "color0", "color1", "color2", "color3", "color4",
                "color5", "color6", "color7", "color8", "color9"
            ]
            if (keys.indexOf(name) !== -1)
                colors[name] = value
        }
    }
}
