import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../components"
import "../../themes"
import "../../services"

PanelWindow {
    id: win

    color: "transparent"
    visible: open
    implicitWidth: screen ? screen.width : Styles.wallpaperGallery.windowWidth
    implicitHeight: Styles.wallpaperGallery.windowHeight
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: Styles.topbar.implicitHeight + 8

    property bool open: false

    // -- index data and browsing state --
    readonly property string tool: Quickshell.shellPath("apps/wallpaper/tool.py")
    property var folders: []
    property var files: []
    property var collapsedIds: []
    property string selectedFolder: ""
    property var selectedFile: null
    property string savedPath: ""
    property string searchQuery: ""
    property bool searchAll: true
    property bool includeSubfolders: false
    property string kindFilter: "all"
    property var thumbs: ({})
    property var thumbQueue: []

    // -- ui status --
    property bool loadingIndex: false
    property int indexCount: 0
    property bool applying: false
    property bool saving: false
    property bool grabReady: false
    property string statusText: ""
    property string previewPath: ""
    property int previewNonce: 0

    // True while values are being loaded from disk or a running process,
    // so the change reactions below don't write them straight back.
    property bool restoring: false
    property bool stateLoaded: false
    readonly property string statePath: Quickshell.shellPath("cache/state.json")

    // -- image filters --
    readonly property var colorStops: [0, 2, 4, 8, 16, 32, 64, 128, 256]
    property int colorStopIndex: 0
    readonly property int filterColors: colorStops[Math.max(0, Math.min(colorStopIndex, colorStops.length - 1))]
    property int filterSat: 100
    property int filterBri: 100
    property int filterCon: 100
    property int filterHue: 0
    property bool filterGray: false
    property bool filterBw: false
    property bool filterInvert: false
    property bool filterSepia: false
    property bool filterDither: false
    property string filterTint: "none"
    property int filterTintAmount: 30

    // -- wallpaper manager and awww transitions --
    property string manager: "auto"
    property string awwwTransition: "simple"
    property int awwwStep: 90
    property int awwwDuration: 3
    property int awwwFps: 30
    property int awwwAngle: 45
    property string awwwPos: "center"
    property string awwwBezier: "default"
    property int awwwWave: 20
    readonly property var awwwTransitions: [
        "none", "simple", "fade", "left", "right", "top", "bottom",
        "wipe", "wave", "grow", "center", "any", "outer", "random"
    ]
    readonly property var awwwPositions: [
        "center", "top", "left", "right", "bottom",
        "top-left", "top-right", "bottom-left", "bottom-right"
    ]
    readonly property var awwwBeziers: ["default", "linear", "ease"]

    // -- live video wallpaper (mpvpaper) --
    property bool liveVideo: false
    property bool livePaused: false
    property bool liveMuted: true
    property int liveVolume: 50

    // -- wallust theming --
    property bool settingsOpen: false
    property string settingsTab: "wallust"
    property string wallustBackend: "wal"
    property string wallustColorSpace: "lch"
    property string wallustPalette: "dark"
    property string wallustFallback: "interpolation"
    property bool wallustContrast: false
    property bool wallustSatOn: false
    property int wallustSat: 50
    property bool wallustThrOn: false
    property int wallustThr: 0
    readonly property var wallustBackends: ["full", "resized", "wal", "thumb", "fastresize", "kmeans"]
    readonly property var wallustColorSpaces: ["lab", "labmixed", "lch", "lchmixed"]
    readonly property var wallustFallbacks: ["interpolation", "complementary"]
    readonly property var wallustPalettes: [
        "dark", "dark16", "darkcomp", "darkcomp16", "light", "light16", "lightcomp", "lightcomp16",
        "harddark", "harddark16", "harddarkcomp", "harddarkcomp16", "softdark", "softdark16",
        "softdarkcomp", "softdarkcomp16", "softlight", "softlight16", "softlightcomp", "softlightcomp16"
    ]

    // -- voyager leds --
    readonly property string keyboardScript: "/home/korin/.config/hypr/scripts/keyboard.sh"
    readonly property var keyboardModes: ["wallpaper", "color", "wallust"]
    readonly property var keyboardColorKeys: [
        "color0", "color1", "color2", "color3",
        "color4", "color5", "color6", "color7"
    ]
    property string keyboardMode: "wallpaper"
    property string keyboardColor: "color1"

    // ---- derived views ----

    readonly property var visibleFolders: {
        const byId = {}
        for (const f of folders)
            byId[f.id] = f
        const hidden = new Set(collapsedIds)
        function ancestorCollapsed(f) {
            for (let p = f.parent; p !== null && p !== undefined; p = byId[p] ? byId[p].parent : null) {
                if (hidden.has(p))
                    return true
            }
            return false
        }
        return folders
            .filter(f => !ancestorCollapsed(f))
            .sort((a, b) => folderKey(a) < folderKey(b) ? -1 : folderKey(a) > folderKey(b) ? 1 : 0)
    }

    readonly property var visibleFiles: {
        const q = searchQuery.trim().toLowerCase()
        const everywhere = q.length > 0 && searchAll
        return files.filter(f => {
            if (kindFilter !== "all" && f.kind !== kindFilter)
                return false
            if (!everywhere) {
                if (includeSubfolders) {
                    if (selectedFolder !== "" && f.folder !== selectedFolder
                            && !f.folder.startsWith(selectedFolder + "/"))
                        return false
                } else if (f.folder !== selectedFolder) {
                    return false
                }
            }
            return !q || f.name.toLowerCase().includes(q) || f.rel.toLowerCase().includes(q)
        })
    }

    // ---- change reactions ----
    // Each key is a binding over everything relevant, replacing per-property
    // onChanged handlers: when any dependency changes, the key changes.

    readonly property string persistedState: JSON.stringify(stateObject())
    onPersistedStateChanged: {
        if (!restoring)
            saveTimer.restart()
    }

    readonly property string previewInputs: JSON.stringify(filterArgs())
    onPreviewInputsChanged: previewTimer.restart()

    readonly property string wallustConfig: JSON.stringify([
        wallustBackend, wallustColorSpace, wallustPalette, wallustFallback,
        wallustContrast, wallustSatOn, wallustSat, wallustThrOn, wallustThr
    ])
    onWallustConfigChanged: {
        if (!restoring)
            wallustSaveTimer.restart()
    }

    // ---- helpers ----

    function fileUrl(path) {
        if (!path)
            return ""
        const raw = String(path)
        if (raw.startsWith("file:"))
            return raw
        return "file://" + raw.split("/").map(encodeURIComponent).join("/")
    }

    function folderKey(f) {
        return (f.rel || f.id || "").toLowerCase()
    }

    function folderHasChildren(id) {
        return folders.some(f => f.parent === id)
    }

    function isCollapsed(id) {
        return collapsedIds.indexOf(id) >= 0
    }

    function toggleCollapsed(id) {
        if (isCollapsed(id))
            collapsedIds = collapsedIds.filter(x => x !== id)
        else
            collapsedIds = collapsedIds.concat([id])
    }

    function selectFolder(id) {
        if (isCollapsed(id))
            toggleCollapsed(id)
        const folder = folders.find(f => f.id === id)
        const children = folders.filter(f => f.parent === id)
            .sort((a, b) => folderKey(a) < folderKey(b) ? -1 : 1)
        // Folders that only hold subfolders jump straight to the first child.
        if (folder && folder.count === 0 && children.length > 0)
            selectedFolder = children[0].id
        else
            selectedFolder = id
    }

    function selectFile(file) {
        selectedFile = file
        savedPath = file ? file.path : ""
        previewPath = ""
        statusText = ""
        previewTimer.restart()
    }

    function restoreSelected() {
        if (!savedPath || selectedFile || !files.length)
            return
        const file = files.find(f => f.path === savedPath)
        if (file) {
            selectedFolder = file.folder
            selectFile(file)
        }
    }

    function thumbFor(path) {
        return thumbs[path] || ""
    }

    function requestThumb(path) {
        if (!path || thumbs[path] || thumbQueue.indexOf(path) >= 0)
            return
        thumbQueue = thumbQueue.concat([path])
        pumpThumbs()
    }

    function pumpThumbs() {
        if (thumbProc.running || thumbQueue.length === 0)
            return
        const batch = thumbQueue.slice(0, 12)
        thumbQueue = thumbQueue.slice(batch.length)
        thumbProc.command = ["python3", win.tool, "thumbs"].concat(batch)
        thumbProc.running = true
    }

    // ---- filters ----

    function filtersActive() {
        return filterColors > 0
            || filterSat !== 100
            || filterBri !== 100
            || filterCon !== 100
            || filterHue !== 0
            || filterGray
            || filterBw
            || filterInvert
            || filterSepia
            || filterDither
            || (filterTint !== "none" && filterTintAmount > 0)
    }

    function resetFilters() {
        colorStopIndex = 0
        filterSat = 100
        filterBri = 100
        filterCon = 100
        filterHue = 0
        filterGray = false
        filterBw = false
        filterInvert = false
        filterSepia = false
        filterDither = false
        filterTint = "none"
        filterTintAmount = 30
    }

    function filterArgs() {
        const a = [
            "--colors", String(filterColors),
            "--sat", String(filterSat),
            "--bri", String(filterBri),
            "--con", String(filterCon),
            "--hue", String(filterHue),
            "--tint", filterTint,
            "--tint-amount", String(filterTintAmount)
        ]
        if (filterGray)
            a.push("--gray")
        if (filterBw)
            a.push("--bw")
        if (filterInvert)
            a.push("--invert")
        if (filterSepia)
            a.push("--sepia")
        if (filterDither)
            a.push("--dither")
        return a
    }

    function awwwArgs() {
        return [
            "--transition", awwwTransition,
            "--transition-step", String(awwwStep),
            "--transition-duration", String(awwwDuration),
            "--transition-fps", String(awwwFps),
            "--transition-angle", String(awwwAngle),
            "--transition-pos", awwwPos,
            "--transition-bezier", awwwBezier,
            "--transition-wave", String(awwwWave)
        ]
    }

    // ---- actions ----

    function startPreview() {
        if (!selectedFile || !filtersActive()) {
            previewPath = ""
            previewProc.running = false
            return
        }
        previewProc.exec(["preview", selectedFile.path, "--manager", manager].concat(filterArgs()))
    }

    function applySelected() {
        if (!selectedFile || applying)
            return
        applying = true
        statusText = "applying..."
        applyProc.exec([
            "apply", selectedFile.path,
            "--manager", manager,
            "--volume", String(liveVolume),
            "--mute", liveMuted ? "1" : "0"
        ].concat(filterArgs()).concat(awwwArgs()))
    }

    function saveSelected() {
        if (!selectedFile || saving)
            return
        if (!filtersActive()) {
            statusText = "no filters to save"
            return
        }
        saving = true
        statusText = "saving..."
        saveProc.exec(["save", selectedFile.path].concat(filterArgs()))
    }

    function mpvIpc(action, value) {
        const cmd = ["ipc", action]
        if (value !== undefined && value !== "")
            cmd.push(String(value))
        mpvIpcProc.exec(cmd)
    }

    function liveTogglePause() {
        livePaused = !livePaused
        mpvIpc("toggle")
    }

    function liveToggleMute() {
        liveMuted = !liveMuted
        mpvIpc("cycle-mute")
    }

    function liveSetVolume(v) {
        liveVolume = v
        mpvIpc("volume", v)
    }

    function keyboardSwatch(key) {
        switch (key) {
        case "color0": return Colors.color0
        case "color1": return Colors.color1
        case "color2": return Colors.color2
        case "color3": return Colors.color3
        case "color4": return Colors.color4
        case "color5": return Colors.color5
        case "color6": return Colors.color6
        case "color7": return Colors.color7
        default: return Colors.color1
        }
    }

    function applyKeyboard() {
        Quickshell.execDetached(["bash", keyboardScript, keyboardMode, keyboardColor])
    }

    // ---- state persistence ----

    function stateObject() {
        return {
            selected: selectedFile ? selectedFile.path : savedPath,
            manager: manager,
            filters: {
                colors: filterColors,
                sat: filterSat,
                bri: filterBri,
                con: filterCon,
                hue: filterHue,
                gray: filterGray,
                bw: filterBw,
                invert: filterInvert,
                sepia: filterSepia,
                dither: filterDither,
                tint: filterTint,
                tintAmount: filterTintAmount
            },
            awww: {
                transition: awwwTransition,
                step: awwwStep,
                duration: awwwDuration,
                fps: awwwFps,
                angle: awwwAngle,
                pos: awwwPos,
                bezier: awwwBezier,
                wave: awwwWave
            },
            mpv: {
                volume: liveVolume,
                mute: liveMuted
            },
            wallust: {
                backend: wallustBackend,
                colorSpace: wallustColorSpace,
                palette: wallustPalette,
                fallback: wallustFallback,
                contrast: wallustContrast,
                satOn: wallustSatOn,
                sat: wallustSat,
                thrOn: wallustThrOn,
                thr: wallustThr
            },
            keyboard: {
                mode: keyboardMode,
                color: keyboardColor
            },
            settingsTab: settingsTab
        }
    }

    function pick(obj, key, current) {
        return obj[key] !== undefined ? obj[key] : current
    }

    function applyState(data) {
        if (!data)
            return
        restoring = true
        savedPath = data.selected || ""
        manager = data.manager || manager
        const f = data.filters || {}
        colorStopIndex = Math.max(0, colorStops.indexOf(pick(f, "colors", filterColors)))
        filterSat = pick(f, "sat", filterSat)
        filterBri = pick(f, "bri", filterBri)
        filterCon = pick(f, "con", filterCon)
        filterHue = pick(f, "hue", filterHue)
        filterGray = pick(f, "gray", filterGray)
        filterBw = pick(f, "bw", filterBw)
        filterInvert = pick(f, "invert", filterInvert)
        filterSepia = pick(f, "sepia", filterSepia)
        filterDither = pick(f, "dither", filterDither)
        filterTint = f.tint || filterTint
        filterTintAmount = pick(f, "tintAmount", filterTintAmount)
        const a = data.awww || {}
        awwwTransition = a.transition || awwwTransition
        awwwStep = pick(a, "step", awwwStep)
        awwwDuration = pick(a, "duration", awwwDuration)
        awwwFps = pick(a, "fps", awwwFps)
        awwwAngle = pick(a, "angle", awwwAngle)
        awwwPos = a.pos || awwwPos
        awwwBezier = a.bezier || awwwBezier
        awwwWave = pick(a, "wave", awwwWave)
        const m = data.mpv || {}
        liveVolume = pick(m, "volume", liveVolume)
        liveMuted = pick(m, "mute", liveMuted)
        const w = data.wallust || {}
        wallustBackend = w.backend || wallustBackend
        wallustColorSpace = w.colorSpace || wallustColorSpace
        wallustPalette = w.palette || wallustPalette
        wallustFallback = w.fallback || wallustFallback
        wallustContrast = pick(w, "contrast", wallustContrast)
        wallustSatOn = pick(w, "satOn", wallustSatOn)
        wallustSat = pick(w, "sat", wallustSat)
        wallustThrOn = pick(w, "thrOn", wallustThrOn)
        wallustThr = pick(w, "thr", wallustThr)
        const k = data.keyboard || {}
        keyboardMode = k.mode || keyboardMode
        keyboardColor = k.color || keyboardColor
        settingsTab = data.settingsTab || settingsTab
        stateLoaded = true
        restoring = false
        restoreSelected()
    }

    FileView {
        id: stateFile
        path: win.statePath
        printErrors: false
        onLoaded: {
            try {
                win.applyState(JSON.parse(text()))
            } catch (e) {
            }
        }
    }

    // ---- open/close and focus handling ----

    function focusedQuickshellScreen() {
        return Quickshell.screens.find(
            s => s.name === Hyprland.focusedMonitor?.name
        ) ?? Quickshell.screens[0]
    }

    function pinScreen() {
        const next = focusedQuickshellScreen()
        if (next)
            screen = next
    }

    Component.onCompleted: pinScreen()

    HyprlandFocusGrab {
        active: win.open && win.visible && win.grabReady
        windows: [win]
        onCleared: {
            win.open = false
            WallpaperGalleryService.open = false
        }
    }

    Connections {
        target: WallpaperGalleryService
        function onOpenChanged() {
            if (WallpaperGalleryService.open) {
                win.pinScreen()
                win.open = true
            } else {
                win.open = false
            }
        }
    }

    onVisibleChanged: {
        if (!visible)
            win.open = false
    }

    onOpenChanged: {
        if (!win.open) {
            win.grabReady = false
            if (WallpaperGalleryService.open)
                WallpaperGalleryService.open = false
            return
        }
        win.pinScreen()
        if (!WallpaperGalleryService.open)
            WallpaperGalleryService.open = true
        win.grabReady = false
        if (!indexProc.running) {
            win.loadingIndex = true
            indexProc.exec(["index"])
        }
        searchFocusTimer.restart()
        grabDelay.restart()
        if (!stateLoaded)
            wallustGetProc.exec(["wallust-get"])
    }

    // ---- timers ----

    Timer {
        id: grabDelay
        interval: 120
        onTriggered: {
            if (win.open && win.visible)
                win.grabReady = true
        }
    }

    Timer {
        id: searchFocusTimer
        interval: 30
        onTriggered: searchField.forceActiveFocus()
    }

    Timer {
        id: previewTimer
        interval: 220
        onTriggered: win.startPreview()
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: stateFile.setText(JSON.stringify(win.stateObject(), null, 2) + "\n")
    }

    Timer {
        id: wallustSaveTimer
        interval: 160
        onTriggered: wallustSetProc.exec([
            "wallust-set",
            "--backend", win.wallustBackend,
            "--color-space", win.wallustColorSpace,
            "--palette", win.wallustPalette,
            "--fallback-generator", win.wallustFallback,
            "--check-contrast", win.wallustContrast ? "1" : "0",
            "--saturation-on", win.wallustSatOn ? "1" : "0",
            "--saturation", String(win.wallustSat),
            "--threshold-on", win.wallustThrOn ? "1" : "0",
            "--threshold", String(win.wallustThr)
        ])
    }

    Timer {
        interval: 800
        repeat: true
        running: win.open
        onTriggered: {
            if (!mpvStatusProc.running)
                mpvStatusProc.exec(["ipc", "status"])
        }
    }

    // ---- backend processes ----

    ToolProcess {
        id: indexProc
        tag: "wallpaper index"
        onResult: data => {
            win.loadingIndex = false
            if (!data.ok) {
                win.statusText = data.error || "failed to index wallpapers"
                return
            }
            win.folders = data.folders || []
            win.files = data.files || []
            win.indexCount = data.count || 0
            win.collapsedIds = win.folders
                .filter(f => f.depth === 1 && f.count === 0)
                .map(f => f.id)
            win.restoreSelected()
        }
    }

    ToolProcess {
        id: previewProc
        tag: "wallpaper preview"
        onResult: data => {
            if (data.ok) {
                win.previewPath = data.path || ""
                if (data.path)
                    win.previewNonce += 1
            } else {
                win.statusText = data.error || "preview failed"
            }
        }
    }

    ToolProcess {
        id: applyProc
        tag: "wallpaper apply"
        onRunningChanged: {
            if (!running)
                win.applying = false
        }
        onResult: data => {
            if (data.ok) {
                win.statusText = "applied with " + data.manager
                win.liveVideo = data.manager === "mpvpaper" && data.kind === "video"
                mpvStatusProc.exec(["ipc", "status"])
            } else {
                win.statusText = data.error || "apply failed"
            }
        }
    }

    ToolProcess {
        id: saveProc
        tag: "wallpaper save"
        onRunningChanged: {
            if (!running)
                win.saving = false
        }
        onResult: data => {
            if (data.ok) {
                const name = (data.path || "").split("/").pop()
                win.statusText = name ? "saved " + name : "saved"
                indexProc.exec(["index"])
            } else {
                win.statusText = data.error || "save failed"
            }
        }
    }

    ToolProcess {
        id: mpvIpcProc
        tag: "mpv ipc"
    }

    ToolProcess {
        id: mpvStatusProc
        tag: "mpv status"
        onResult: data => {
            if (!data.ok) {
                win.liveVideo = false
                return
            }
            win.restoring = true
            win.liveVideo = !!data.running
            if (data.running) {
                win.livePaused = !!data.pause
                win.liveMuted = !!data.mute
                if (data.volume !== undefined)
                    win.liveVolume = data.volume
            }
            win.restoring = false
        }
    }

    ToolProcess {
        id: wallustGetProc
        tag: "wallust"
        onResult: data => {
            if (!data.ok)
                return
            win.restoring = true
            win.wallustBackend = data.backend || "wal"
            win.wallustColorSpace = data.color_space || "lch"
            win.wallustPalette = data.palette || "dark"
            win.wallustFallback = data.fallback_generator || "interpolation"
            win.wallustContrast = !!data.check_contrast
            win.wallustSatOn = data.saturation !== null && data.saturation !== undefined
            win.wallustSat = win.wallustSatOn ? data.saturation : (data.saturation_hint || 50)
            win.wallustThrOn = data.threshold !== null && data.threshold !== undefined
            win.wallustThr = win.wallustThrOn ? data.threshold : (data.threshold_hint || 0)
            win.restoring = false
            saveTimer.restart()
        }
    }

    ToolProcess {
        id: wallustSetProc
        tag: "wallust"
    }

    Process {
        id: thumbProc
        running: false
        stdout: SplitParser {
            onRead: chunk => {
                try {
                    const data = JSON.parse(chunk)
                    if (data.ok && data.src && data.path) {
                        const next = Object.assign({}, win.thumbs)
                        next[data.src] = data.path
                        win.thumbs = next
                    }
                } catch (e) {
                }
            }
        }
        onRunningChanged: {
            if (!running)
                win.pumpThumbs()
        }
    }

    // ---- ui ----

    Shortcut {
        sequences: ["Escape"]
        enabled: win.open
        onActivated: win.open = false
    }

    Shortcut {
        sequences: ["Return", "Enter"]
        enabled: win.open
        onActivated: win.applySelected()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: win.open = false
    }

    Rectangle {
        id: root
        width: Math.min(Styles.wallpaperGallery.windowWidth, win.width - 16)
        height: win.height
        anchors.horizontalCenter: parent.horizontalCenter
        color: Styles.wallpaperGallery.background.color
        radius: Styles.wallpaperGallery.background.radius
        border.width: Styles.wallpaperGallery.background.border.width
        border.color: Styles.wallpaperGallery.background.border.color
        clip: radius > 0

        readonly property int pad: Styles.wallpaperGallery.padding
        readonly property int gap: Styles.wallpaperGallery.spacing

        MouseArea {
            // Swallows clicks so they don't reach the close-on-click backdrop.
            anchors.fill: parent
            onClicked: {}
        }

        FolderSidebar {
            id: foldersPane
            gallery: win
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.topMargin: root.pad
            anchors.leftMargin: root.pad
            anchors.bottomMargin: root.pad
            width: Styles.wallpaperGallery.sidebarWidth
        }

        Rectangle {
            id: gridPane
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: foldersPane.right
            anchors.right: settingsPane.visible ? settingsPane.left : filtersPane.left
            anchors.topMargin: root.pad
            anchors.bottomMargin: root.pad
            anchors.leftMargin: root.gap
            anchors.rightMargin: root.gap
            color: Styles.wallpaperGallery.grid.color
            radius: Styles.wallpaperGallery.grid.radius
            border.width: Styles.wallpaperGallery.grid.border.width
            border.color: Styles.wallpaperGallery.grid.border.color
            clip: radius > 0

            Item {
                id: gridHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: root.pad
                anchors.leftMargin: root.pad
                anchors.rightMargin: root.pad
                height: Styles.wallpaperGallery.headerHeight

                TextField {
                    id: searchField
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 220
                    height: 24
                    leftPadding: 10
                    placeholderText: "search"
                    placeholderTextColor: Styles.wallpaperGallery.search.text.placeholder
                    color: Styles.wallpaperGallery.search.text.color
                    font.family: Styles.wallpaperGallery.search.text.font.family
                    font.pixelSize: Styles.wallpaperGallery.search.text.font.pixelSize
                    onTextChanged: win.searchQuery = text
                    background: Rectangle {
                        color: Styles.wallpaperGallery.search.color
                        radius: Styles.wallpaperGallery.search.radius
                        border.width: Styles.wallpaperGallery.search.border.width
                        border.color: Styles.wallpaperGallery.search.border.color
                    }
                }

                Row {
                    id: filterChips
                    anchors.left: searchField.right
                    anchors.right: metaRow.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6
                    clip: true

                    Repeater {
                        model: [
                            { label: "all", kind: "all" },
                            { label: "images", kind: "image" },
                            { label: "gifs", kind: "gif" },
                            { label: "videos", kind: "video" }
                        ]
                        GalleryChip {
                            required property var modelData
                            label: modelData.label
                            selected: win.kindFilter === modelData.kind
                            onClicked: win.kindFilter = modelData.kind
                        }
                    }
                    GalleryChip {
                        label: "subfolders"
                        selected: win.includeSubfolders
                        onClicked: win.includeSubfolders = !win.includeSubfolders
                    }
                    GalleryChip {
                        label: "search all"
                        selected: win.searchAll
                        onClicked: win.searchAll = !win.searchAll
                    }
                }

                Row {
                    id: metaRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    BetterText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.loadingIndex
                            ? "indexing..."
                            : win.visibleFiles.length + " shown"
                        color: Styles.wallpaperGallery.preview.muted.color
                        font.family: Styles.wallpaperGallery.preview.muted.font.family
                        font.pixelSize: Styles.wallpaperGallery.preview.muted.font.pixelSize
                    }

                    GalleryChip {
                        label: "settings"
                        selected: win.settingsOpen
                        onClicked: win.settingsOpen = !win.settingsOpen
                    }
                }
            }

            GridView {
                id: grid
                readonly property int scrollWidth: 6
                readonly property int thumbInset: 4
                readonly property int scrollGutter: root.pad + scrollWidth + root.pad - thumbInset
                anchors.top: gridHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: root.pad
                anchors.rightMargin: scrollGutter
                anchors.bottomMargin: root.pad
                anchors.topMargin: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: win.visibleFiles
                cacheBuffer: 800
                cellWidth: {
                    const cols = Math.max(2, Math.floor(width / Styles.wallpaperGallery.thumbMin))
                    return width / cols
                }
                cellHeight: Math.round(cellWidth * 0.78)

                delegate: ThumbCell {
                    required property var modelData
                    width: grid.cellWidth
                    height: grid.cellHeight
                    gallery: win
                    file: modelData
                    selected: win.selectedFile && modelData && win.selectedFile.path === modelData.path
                }
            }

            ScrollBar {
                id: gridScrollBar
                orientation: Qt.Vertical
                policy: ScrollBar.AlwaysOn
                visible: grid.contentHeight > grid.height
                interactive: true
                hoverEnabled: true
                active: hovered || pressed || grid.movingVertically
                padding: 0
                implicitWidth: grid.scrollWidth
                width: grid.scrollWidth
                size: grid.visibleArea.heightRatio
                anchors.top: grid.top
                anchors.bottom: grid.bottom
                anchors.right: parent.right
                anchors.rightMargin: root.pad
                background: null
                contentItem: Rectangle {
                    implicitWidth: grid.scrollWidth
                    radius: 3
                    color: Styles.fgBase
                }

                Binding {
                    target: gridScrollBar
                    property: "position"
                    value: grid.visibleArea.yPosition
                    when: !gridScrollBar.pressed
                    restoreMode: Binding.RestoreNone
                }

                onPositionChanged: {
                    if (!pressed)
                        return
                    grid.contentY = grid.originY + position * grid.contentHeight
                }
            }

            BetterText {
                anchors.centerIn: grid
                visible: !win.loadingIndex && win.visibleFiles.length === 0
                text: win.searchQuery.length ? "no matches" : "pick a folder"
                color: Styles.wallpaperGallery.preview.muted.color
                font.family: Styles.wallpaperGallery.preview.muted.font.family
                font.pixelSize: Styles.wallpaperGallery.preview.muted.font.pixelSize
            }
        }

        SettingsPanel {
            id: settingsPane
            gallery: win
            visible: win.settingsOpen
            anchors.top: parent.top
            anchors.right: filtersPane.left
            anchors.bottom: parent.bottom
            anchors.topMargin: root.pad
            anchors.bottomMargin: root.pad
            anchors.rightMargin: visible ? root.gap : 0
            width: visible ? Styles.wallpaperGallery.previewWidth : 0
        }

        FilterPanel {
            id: filtersPane
            gallery: win
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: root.pad
            anchors.rightMargin: root.pad
            anchors.bottomMargin: root.pad
            width: Styles.wallpaperGallery.previewWidth
        }
    }
}
