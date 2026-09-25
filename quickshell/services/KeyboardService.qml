pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../components"

Singleton {
    id: keyboardService

    readonly property int keyCount: 52
    readonly property string geometry: "voyager"
    readonly property string cacheDir: Quickshell.shellPath("cache/voyager")
    property string layoutPath: ""

    property string layoutId: ""
    property string revisionId: ""
    property string serial: ""
    property string title: ""
    property var layers: []
    property int currentLayer: 0
    property var keyStates: []
    property int keyStatesVersion: 0
    property bool loading: false
    property string error: ""
    property bool connected: false

    onConnectedChanged: {
        if (connected)
            Quickshell.execDetached(["/home/korin/.config/hypr/scripts/keyboard.sh"])
    }

    // Oryx Voyager keys[] is left half (26) then right half (26), row-major.
    readonly property var matrixToIndex: ({
        "0,1": 0, "0,2": 1, "0,3": 2, "0,4": 3, "0,5": 4, "0,6": 5,
        "1,1": 6, "1,2": 7, "1,3": 8, "1,4": 9, "1,5": 10, "1,6": 11,
        "2,1": 12, "2,2": 13, "2,3": 14, "2,4": 15, "2,5": 16, "2,6": 17,
        "3,1": 18, "3,2": 19, "3,3": 20, "3,4": 21, "3,5": 22, "4,4": 23,
        "5,0": 24, "5,1": 25,
        "6,0": 26, "6,1": 27, "6,2": 28, "6,3": 29, "6,4": 30, "6,5": 31,
        "7,0": 32, "7,1": 33, "7,2": 34, "7,3": 35, "7,4": 36, "7,5": 37,
        "8,0": 38, "8,1": 39, "8,2": 40, "8,3": 41, "8,4": 42, "8,5": 43,
        "10,2": 44, "9,1": 45, "9,2": 46, "9,3": 47, "9,4": 48, "9,5": 49,
        "11,5": 50, "11,6": 51
    })

    readonly property var codeLabels: ({
        "KC_ESCAPE": "Esc", "KC_ENTER": "Ent", "KC_BSPC": "Bksp", "KC_BACKSPACE": "Bksp",
        "KC_TAB": "Tab", "KC_SPACE": "Spc", "KC_CAPS_LOCK": "Caps", "KC_DELETE": "Del",
        "KC_INSERT": "Ins", "KC_HOME": "Home", "KC_END": "End",
        "KC_PAGE_UP": "PgUp", "KC_PAGE_DOWN": "PgDn",
        "KC_LEFT": "←", "KC_RIGHT": "→", "KC_UP": "↑", "KC_DOWN": "↓",
        "KC_LEFT_SHIFT": "Shift", "KC_RIGHT_SHIFT": "Shift",
        "KC_LEFT_CTRL": "Ctrl", "KC_RIGHT_CTRL": "Ctrl",
        "KC_LEFT_ALT": "Alt", "KC_RIGHT_ALT": "Alt",
        "KC_LEFT_GUI": "SPR", "KC_RIGHT_GUI": "SPR",
        "KC_APPLICATION": "Menu", "KC_PRINT_SCREEN": "PrtSc",
        "KC_SCROLL_LOCK": "ScLk", "KC_PAUSE": "Pause",
        "KC_GRAVE": "`", "KC_MINUS": "-", "KC_EQUAL": "=",
        "KC_LEFT_BRACKET": "[", "KC_RIGHT_BRACKET": "]",
        "KC_BACKSLASH": "\\", "KC_SEMICOLON": ";", "KC_QUOTE": "'",
        "KC_COMMA": ",", "KC_DOT": ".", "KC_SLASH": "/",
        "KC_DQUO": "\"", "KC_COLN": ":", "KC_SCLN": ";",
        "KC_UNDS": "_", "KC_PLUS": "+", "KC_PIPE": "|",
        "KC_TILD": "~", "KC_EXLM": "!", "KC_AT": "@", "KC_HASH": "#",
        "KC_DLR": "$", "KC_PERC": "%", "KC_CIRC": "^", "KC_AMPR": "&",
        "KC_ASTR": "*", "KC_LPRN": "(", "KC_RPRN": ")",
        "KC_LCBR": "{", "KC_RCBR": "}", "KC_LBRC": "[", "KC_RBRC": "]",
        "KC_LABK": "<", "KC_RABK": ">", "KC_QUES": "?", "KC_BSLS": "\\",
        "KC_TRANSPARENT": "", "KC_TRNS": "", "KC_NO": "", "KC_NOOP": "",
        "RGB_TOG": "RGB", "RGB_MODE_FORWARD": "RGB+", "RGB_SLD": "RGB-",
        "RGB_VAD": "V-", "RGB_VAI": "V+", "RGB_HUD": "H-", "RGB_HUI": "H+",
        "RGB_SPD": "Spd-", "RGB_SPI": "Spd+",
        "TOGGLE_LAYER_COLOR": "TLC", "QK_BOOT": "Boot",
        "KC_AUDIO_MUTE": "Mute", "KC_AUDIO_VOL_UP": "Vol+", "KC_AUDIO_VOL_DOWN": "Vol-",
        "KC_MEDIA_PLAY_PAUSE": "Play", "KC_MEDIA_STOP": "Stop",
        "KC_MEDIA_NEXT_TRACK": "Next", "KC_MEDIA_PREV_TRACK": "Prev",
        "KC_MEDIA_EJECT": "Eject",
        "KC_BRIGHTNESS_UP": "Bri+", "KC_BRIGHTNESS_DOWN": "Bri-",
        "KC_SYSTEM_POWER": "Pwr", "KC_SYSTEM_SLEEP": "Sleep", "KC_SYSTEM_WAKE": "Wake",
        "KC_PGDN": "PgDn", "KC_PGUP": "PgUp", "KC_PSCR": "PrtSc"
    })

    readonly property var labelIcons: ({
        "Shift": "󰘶",
        "Tab": "󰌒", "Ent": "󰌑", "Enter": "󰌑",
        "Bksp": "⌫", "Spc": "󱁐", "Del": "󰗨",
        "Home": "󰍜", "End": "󰍛", "PgUp": "󰁝", "PgDn": "󰁅",
        "Play": "󰐊", "Stop": "󰓛", "Next": "󰒭", "Prev": "󰒮",
        "Mute": "󰝟", "Vol+": "󰝝", "Vol-": "󰝞", "Eject": "󰗮",
        "Pwr": "󰐥", "Sleep": "󰒲", "Wake": "󰛨", "Boot": "󰚥",
        "PrtSc": "󰹑", "Bri+": "󰃠", "Bri-": "󰃞",
        "RGB": "󰌁", "RGB+": "󰃠", "RGB-": "󰃞",
        "TLC": "󰌁", "V+": "󰃠", "V-": "󰃞",
        "Prev Tab": "󰒮", "Next Tab": "󰒭",
        "alt tab": "󰌒", "s alt tab": "󰘶"
    })

    function iconFor(text) {
        if (!text)
            return ""
        return labelIcons[text] || ""
    }

    property bool _fetching: false
    property string _loadedPath: ""

    CurlRequest {
        id: oryxReq
        name: "Oryx"
    }

    function emptyKeyState(index) {
        return {
            index: index,
            pressed: false,
            tap: "",
            hold: "",
            doubleTap: "",
            tapHold: "",
            label: "",
            glowColor: "",
            widget: null
        }
    }

    function resetKeyStates() {
        const next = []
        for (let i = 0; i < keyCount; i++)
            next.push(emptyKeyState(i))
        keyStates = next
        keyStatesVersion++
    }

    function indexFromMatrix(col, row) {
        const idx = matrixToIndex[row + "," + col]
        return idx === undefined ? -1 : idx
    }

    function currentLayerKeys() {
        const layer = layers[currentLayer]
        return (layer && layer.keys) ? layer.keys : []
    }

    function setCurrentLayer(index) {
        if (index < 0)
            return
        currentLayer = index
    }

    function setKeyState(index, state) {
        if (index < 0 || index >= keyCount || !state)
            return
        const next = keyStates.slice()
        const prev = next[index] || emptyKeyState(index)
        const merged = Object.assign({}, prev, state, { index: index })
        next[index] = merged
        keyStates = next
        keyStatesVersion++
    }

    function setKeyWidget(index, widgetState) {
        setKeyState(index, { widget: widgetState })
    }

    function setKeyPressed(index, pressed) {
        setKeyState(index, { pressed: !!pressed })
    }

    function applyWidgetStates(states) {
        if (!states)
            return
        const next = keyStates.slice()
        const count = Math.min(keyCount, states.length)
        for (let i = 0; i < count; i++) {
            if (states[i] === undefined || states[i] === null)
                continue
            const prev = next[i] || emptyKeyState(i)
            if (typeof states[i] === "object")
                next[i] = Object.assign({}, prev, states[i], { index: i })
            else
                next[i] = Object.assign({}, prev, { widget: states[i], index: i })
        }
        keyStates = next
        keyStatesVersion++
    }

    function keyState(index) {
        return keyStates[index] || emptyKeyState(index)
    }

    function formatModifiers(modifiers) {
        if (!modifiers)
            return ""
        let out = ""
        if (modifiers.leftCtrl || modifiers.rightCtrl)
            out += "C"
        if (modifiers.leftAlt || modifiers.rightAlt)
            out += "A"
        if (modifiers.leftGui || modifiers.rightGui)
            out += "G"
        if (modifiers.leftShift || modifiers.rightShift)
            out += "S"
        return out ? out + "-" : ""
    }

    function codeToLabel(code) {
        if (!code)
            return ""
        if (codeLabels[code] !== undefined)
            return codeLabels[code]
        let s = String(code)
        if (s.indexOf("KC_") === 0)
            s = s.slice(3)
        s = s.replace(/^LEFT_/, "").replace(/^RIGHT_/, "")
        if (s.indexOf("F") === 0 && s.length <= 3)
            return s
        if (s.length === 1)
            return s
        return s.replace(/_/g, " ")
    }

    function formatAction(action) {
        if (!action || !action.code)
            return ""
        const code = action.code
        if (code === "MO" || code === "TO" || code === "TG" || code === "TT"
            || code === "OSL" || code === "LT" || code === "LM")
            return code + "(" + action.layer + ")"
        return formatModifiers(action.modifiers) + codeToLabel(code)
    }

    function simplifyKey(key) {
        if (!key)
            return { tap: "", hold: "", doubleTap: "", tapHold: "", label: "", glowColor: "" }
        const tap = formatAction(key.tap)
        const hold = formatAction(key.hold)
        const doubleTap = formatAction(key.doubleTap)
        const tapHold = formatAction(key.tapHold)
        return {
            tap: tap,
            hold: hold,
            doubleTap: doubleTap,
            tapHold: tapHold,
            label: key.customLabel || key.emoji || tap || hold || doubleTap || tapHold,
            glowColor: key.glowColor || ""
        }
    }

    function simplifyLayout(data) {
        const layout = data && data.data && data.data.layout
        if (!layout || !layout.revision)
            throw new Error("Oryx response missing layout")
        const rev = layout.revision
        const rawLayers = rev.layers || []
        const simpleLayers = []
        for (let i = 0; i < rawLayers.length; i++) {
            const layer = rawLayers[i]
            const rawKeys = layer.keys || []
            const keys = []
            for (let k = 0; k < keyCount; k++)
                keys.push(simplifyKey(rawKeys[k]))
            simpleLayers.push({
                index: layer.position !== undefined && layer.position !== null ? layer.position : i,
                name: layer.title || ("Layer " + i),
                keys: keys
            })
        }
        return {
            layoutId: layout.hashId || layoutId,
            revisionId: rev.hashId || revisionId,
            title: layout.title || "",
            geometry: layout.geometry || geometry,
            layers: simpleLayers
        }
    }

    function applySimpleLayout(simple) {
        if (!simple)
            return
        title = simple.title || ""
        if (simple.layoutId)
            layoutId = simple.layoutId
        if (simple.revisionId)
            revisionId = simple.revisionId
        layers = simple.layers || []
        if (currentLayer >= layers.length)
            currentLayer = 0
        refreshKeyLabels()
    }

    function refreshKeyLabels() {
        const keys = currentLayerKeys()
        const next = []
        for (let i = 0; i < keyCount; i++) {
            const prev = keyStates[i] || emptyKeyState(i)
            const k = keys[i] || {}
            next.push(Object.assign({}, prev, {
                index: i,
                tap: k.tap || "",
                hold: k.hold || "",
                doubleTap: k.doubleTap || "",
                tapHold: k.tapHold || "",
                label: k.label || "",
                glowColor: k.glowColor || ""
            }))
        }
        keyStates = next
        keyStatesVersion++
    }

    function applySerial(value) {
        const sn = String(value || "").trim()
        if (!sn || sn.indexOf("/") < 0) {
            error = "Unexpected Voyager serial: " + sn
            loading = false
            return
        }
        serial = sn
        const parts = sn.split("/")
        const nextLayout = parts[0]
        const nextRevision = parts[1]
        if (nextLayout === layoutId && nextRevision === revisionId && layers.length) {
            loading = false
            return
        }
        layoutId = nextLayout
        revisionId = nextRevision
        layoutPath = cacheDir + "/" + nextLayout + "-" + nextRevision + ".json"
        error = ""
        loading = true
    }

    function fetchOryxLayout() {
        if (_fetching || !layoutId || !revisionId)
            return

        _fetching = true
        loading = true
        error = ""

        oryxReq.request({
            method: "POST",
            url: "https://oryx.zsa.io/graphql",
            headers: { "Content-Type": "application/json" },
            body: {
                operationName: "getLayout",
                variables: {
                    hashId: layoutId,
                    revisionId: revisionId,
                    geometry: geometry
                },
                query: "query getLayout($hashId: String!, $geometry: String, $revisionId: String!) { layout(hashId: $hashId, geometry: $geometry, revisionId: $revisionId) { title geometry hashId revision { hashId title layers { hashId title position keys } } } }"
            },
            callback: function(data, status, err) {
                _fetching = false
                if (status !== 200) {
                    error = err || ("Oryx HTTP " + status)
                    loading = false
                    return
                }
                try {
                    if (data && data.errors && data.errors.length) {
                        error = data.errors[0].message || "Oryx GraphQL error"
                        loading = false
                        return
                    }
                    const simple = simplifyLayout(data)
                    applySimpleLayout(simple)
                    layoutFile.setText(JSON.stringify(simple, null, 2))
                    _loadedPath = layoutPath
                    error = ""
                } catch (e) {
                    error = "Failed to parse Oryx layout: " + (e.message || e)
                }
                loading = false
            }
        })
    }

    function loadCachedOrFetch() {
        if (!layoutPath)
            return
        if (_loadedPath === layoutPath && layers.length)
            return
        layoutFile.reload()
    }

    function handleVoyagerLine(line) {
        const text = String(line || "").trim()
        if (!text)
            return

        if (text.indexOf("Connected to Voyager") === 0 || text.indexOf("Paired") === 0) {
            connected = true
            return
        }

        if (text.indexOf("error telemetry_not_found") === 0
            || text.indexOf("Connection lost") === 0
            || text === "Disconnected.") {
            connected = false
            return
        }

        if (text.indexOf("serial ") === 0) {
            applySerial(text.slice(7))
            return
        }

        if (text.indexOf("layer ") === 0) {
            const layer = parseInt(text.slice(6), 10)
            if (!isNaN(layer)) {
                connected = true
                setCurrentLayer(layer)
            }
            return
        }

        const down = text.match(/^down\s+col=(\d+)\s+row=(\d+)$/)
        if (down) {
            connected = true
            setKeyPressed(indexFromMatrix(parseInt(down[1], 10), parseInt(down[2], 10)), true)
            return
        }

        const up = text.match(/^up\s+col=(\d+)\s+row=(\d+)$/)
        if (up) {
            connected = true
            setKeyPressed(indexFromMatrix(parseInt(up[1], 10), parseInt(up[2], 10)), false)
        }
    }

    function refresh() {
        _loadedPath = ""
        layers = []
        loading = true
        error = ""
        if (voyager.running)
            voyager.running = false
        voyager.running = true
    }

    onLayoutPathChanged: {
        if (layoutPath)
            loadCachedOrFetch()
    }

    onCurrentLayerChanged: refreshKeyLabels()

    FileView {
        id: layoutFile
        path: keyboardService.layoutPath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (!keyboardService.layoutPath)
                return
            const raw = text().trim()
            if (!raw) {
                keyboardService.fetchOryxLayout()
                return
            }
            try {
                const simple = JSON.parse(raw)
                keyboardService.applySimpleLayout(simple)
                keyboardService._loadedPath = keyboardService.layoutPath
                keyboardService.error = ""
                keyboardService.loading = false
            } catch (e) {
                keyboardService.fetchOryxLayout()
            }
        }
        onLoadFailed: (fileError) => {
            if (!keyboardService.layoutPath)
                return
            if (fileError === FileViewError.FileNotFound)
                keyboardService.fetchOryxLayout()
            else {
                keyboardService.error = "Failed to read layout cache"
                keyboardService.loading = false
            }
        }
        onSaveFailed: {
            console.log("[KeyboardService] Could not write layout cache")
        }
    }

    Process {
        id: voyager
        running: true
        command: [
            Quickshell.shellPath("Scripts/venv/bin/python"),
            Quickshell.shellPath("Scripts/voyager.py")
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: chunk => keyboardService.handleVoyagerLine(chunk)
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: chunk => {
                const text = String(chunk || "").trim()
                if (text)
                    console.log("[KeyboardService]", text)
            }
        }
        onRunningChanged: {
            if (running)
                return
            keyboardService.connected = false
            if (!keyboardService.serial)
                lsusbSerial.running = true
            voyagerRestart.restart()
        }
    }

    Timer {
        id: voyagerRestart
        interval: 2000
        repeat: false
        onTriggered: {
            if (!voyager.running)
                voyager.running = true
        }
    }

    Process {
        id: lsusbSerial
        running: false
        command: [
            "sh", "-c",
            "lsusb -v -d 3297:1977 2>/dev/null | grep -iE '(iSerial|iProduct)'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (keyboardService.serial)
                    return
                const lines = text.trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].toLowerCase().indexOf("iserial") >= 0) {
                        const parts = lines[i].trim().split(/\s+/)
                        keyboardService.applySerial(parts[parts.length - 1])
                        return
                    }
                }
                keyboardService.error = "Voyager layout serial not found"
                keyboardService.loading = false
            }
        }
    }

    Component.onCompleted: resetKeyStates()
}
