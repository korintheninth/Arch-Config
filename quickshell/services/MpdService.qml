pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool connected: false
    property bool active: false
    property bool isPlaying: false
    property string trackTitle: ""
    property string trackArtist: ""
    property string trackAlbum: ""
    property string trackArtUrl: ""
    property string file: ""
    property string path: "" // absolute path of the current track file
    property real length: 0
    property real position: 0
    property real volume: 0
    property bool shuffle: false
    property string loopMode: "off" // off | playlist | one
    property bool canNext: false
    property bool canPrevious: false

    readonly property bool canPlay: active
    readonly property bool canPause: active
    readonly property bool canControl: active
    readonly property bool shuffleSupported: true
    readonly property bool loopSupported: true
    readonly property var streamHints: ["Music Player Daemon", "mpd"]

    property real _syncedPos: 0
    property real _syncedAt: 0

    signal tick()

    function applySnapshot(data) {
        if (!data || !data.ok) {
            connected = false
            isPlaying = false
            return
        }
        connected = true
        active = !!data.active
        isPlaying = !!data.isPlaying
        trackTitle = String(data.title ?? "")
        trackArtist = String(data.artist ?? "")
        trackAlbum = String(data.album ?? "")
        file = String(data.file ?? "")
        path = String(data.path ?? "")
        trackArtUrl = String(data.cover ?? "")
        length = Math.max(0, Number(data.duration) || 0)
        _syncedPos = Math.max(0, Number(data.position) || 0)
        _syncedAt = Date.now()
        shuffle = !!data.shuffle
        loopMode = String(data.loopMode ?? "off")
        volume = Math.max(0, Math.min(1, Number(data.volume) || 0))
        canNext = data.canNext !== undefined ? !!data.canNext : active
        canPrevious = data.canPrevious !== undefined ? !!data.canPrevious : active
        refreshPosition()
    }

    function send(line) {
        if (!command.running) {
            command.running = true
            Qt.callLater(() => {
                if (command.running)
                    command.write(line + "\n")
            })
            return
        }
        command.write(line + "\n")
    }

    function refreshPosition() {
        if (!active) {
            position = 0
        } else if (isPlaying) {
            let pos = _syncedPos + (Date.now() - _syncedAt) / 1000
            if (length > 0)
                pos = Math.min(pos, length)
            position = pos
        } else {
            position = _syncedPos
        }
        tick()
    }

    function play() { send("play") }
    function pause() { send("pause") }
    function togglePlayPause() { isPlaying ? pause() : play() }
    function next() { send("next") }
    function previous() { send("previous") }
    function refresh() {} // UI state comes from the listener only

    function seek(seconds) {
        send("seek " + Math.max(0, Number(seconds) || 0))
    }

    function setVolume(v) {
        send("volume " + Math.max(0, Math.min(1, v)))
    }

    function setShuffle(on) {
        send("shuffle " + (on ? "1" : "0"))
    }

    function toggleShuffle() { setShuffle(!shuffle) }

    function setLoopMode(mode) {
        send("loop " + (mode === "one" || mode === "playlist" ? mode : "off"))
    }

    function cycleLoop() {
        setLoopMode(loopMode === "off" ? "playlist" : loopMode === "playlist" ? "one" : "off")
    }

    // Listener: idle → snapshot → UI. Only source of playback state.
    Process {
        id: listener
        command: ["python3", "-u", Quickshell.shellPath("services/mpd/listen.py")]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const raw = String(line ?? "").trim()
                if (!raw)
                    return
                try {
                    root.applySnapshot(JSON.parse(raw))
                } catch (e) {}
            }
        }
        onExited: {
            root.connected = false
            root.isPlaying = false
            listenerRestart.restart()
        }
    }

    // Command: stdin controls only. No UI updates.
    Process {
        id: command
        command: ["python3", "-u", Quickshell.shellPath("services/mpd/command.py")]
        running: true
        stdinEnabled: true
        onExited: commandRestart.restart()
    }

    Timer {
        id: listenerRestart
        interval: 400
        onTriggered: {
            if (!listener.running)
                listener.running = true
        }
    }

    Timer {
        id: commandRestart
        interval: 400
        onTriggered: {
            if (!command.running)
                command.running = true
        }
    }

    Timer {
        interval: 3000
        running: root.active && !root.connected
        onTriggered: {
            if (!root.connected)
                root.active = false
        }
    }

    Timer {
        interval: 100
        running: root.active && root.isPlaying
        repeat: true
        onTriggered: root.refreshPosition()
    }
}
