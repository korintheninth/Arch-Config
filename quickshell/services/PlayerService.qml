pragma Singleton

import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell
import QtQuick

Singleton {
    id: root

    function isMpdPlayer(p) {
        if (!p)
            return false
        const dbus = String(p.dbusName ?? "").toLowerCase()
        const entry = String(p.desktopEntry ?? "").toLowerCase()
        const identity = String(p.identity ?? "").toLowerCase()
        const rest = dbus.replace(/^org\.mpris\.mediaplayer2\./, "")
        return entry === "mpd"
            || entry.includes("mpd")
            || identity.includes("mpd")
            || rest.includes("mpd")
            || dbus.includes("mpd")
    }

    function isRealPlayer(p) {
        if (!p)
            return false
        // MPD is bound via MpdService — ignore mpd-mpris if present.
        if (isMpdPlayer(p))
            return false
        const dbus = String(p.dbusName ?? "").toLowerCase()
        if (dbus.includes("playerctld"))
            return false
        const entry = String(p.desktopEntry ?? "").toLowerCase()
        const identity = String(p.identity ?? "").toLowerCase()
        const rest = dbus.replace(/^org\.mpris\.mediaplayer2\./, "")
        return entry === "spotify"
            || entry.includes("youtube-music")
            || entry.includes("youtubemusic")
            || identity.includes("spotify")
            || identity.includes("youtube-music")
            || identity.includes("youtube music")
            || identity.includes("youtubemusic")
            || identity.includes("mixtapes")
            || rest.includes("spotify")
            || rest.includes("youtube")
            || dbus.includes("spotify")
    }

    function buildStreamHints(p) {
        if (!p)
            return []
        const dbus = String(p.dbusName ?? "")
        const rest = dbus.replace(/^org\.mpris\.MediaPlayer2\./i, "")
        const identity = String(p.identity ?? "")
        const entry = String(p.desktopEntry ?? "")
        const parts = [rest, entry, identity]
        const idl = identity.toLowerCase()
        const entryl = entry.toLowerCase()
        const restl = rest.toLowerCase()
        const busl = dbus.toLowerCase()

        if (idl.includes("spotify") || entryl === "spotify" || restl.includes("spotify") || busl.includes("spotify"))
            parts.push("spotify")
        // th-ch YouTube Music is Electron; PipeWire names the stream Chromium.
        if (idl.includes("youtube-music") || idl.includes("youtube music") || idl.includes("youtubemusic")
            || entryl.includes("youtube") || restl.includes("youtube") || busl.includes("youtube"))
            parts.push("chromium", "electron", "youtube-music", "youtube music")
        if (idl.includes("mixtapes") || restl.includes("mixtapes"))
            parts.push("mixtapes")

        const seen = {}
        const out = []
        for (const v of parts) {
            const s = String(v ?? "").trim()
            if (!s)
                continue
            const key = s.toLowerCase()
            if (seen[key])
                continue
            seen[key] = true
            out.push(s)
        }
        return out
    }

    function nodeText(n) {
        const props = n.properties || {}
        return [
            n.name,
            n.description,
            n.nickname,
            props["application.name"],
            props["application.process.binary"],
            props["media.name"],
            props["node.name"]
        ].map(v => String(v ?? "").toLowerCase()).filter(v => v.length)
    }

    function nodeMatchesHints(n, hints) {
        if (!hints || !hints.length)
            return false
        const fields = nodeText(n)
        if (!fields.length)
            return false
        for (const hint of hints) {
            const h = String(hint ?? "").toLowerCase().trim()
            if (!h || h.length < 3)
                continue
            // Avoid matching ultra-generic tokens that appear in many nodes.
            if (h === "org" || h === "media" || h === "player" || h === "audio" || h === "instance")
                continue
            for (const f of fields) {
                if (f.includes(h) || (h.length >= 4 && h.includes(f)))
                    return true
            }
        }
        return false
    }

    readonly property MprisPlayer mprisPlayer: {
        const players = Mpris.players.values
        let firstReal = null
        for (const p of players) {
            if (!isRealPlayer(p))
                continue
            if (!firstReal)
                firstReal = p
            if (p.isPlaying)
                return p
        }
        return firstReal
    }

    readonly property bool mprisPlaying: mprisPlayer?.isPlaying ?? false

    // Prefer a playing MPRIS app; otherwise use MPD when it has something loaded.
    // Use `active` (not `connected`) so a brief watcher reconnect doesn't blank the UI.
    readonly property bool usingMpd: {
        if (mprisPlaying)
            return false
        return MpdService.active
    }

    // Kept for callers that still reference PlayerService.player (MPRIS only).
    readonly property var player: usingMpd ? null : mprisPlayer

    readonly property bool active: usingMpd ? MpdService.active : (mprisPlayer !== null)
    readonly property bool isPlaying: usingMpd ? MpdService.isPlaying : (mprisPlayer?.isPlaying ?? false)
    readonly property bool canPlay: usingMpd ? MpdService.canPlay : (mprisPlayer?.canPlay ?? false)
    readonly property bool canPause: usingMpd ? MpdService.canPause : (mprisPlayer?.canPause ?? false)
    readonly property bool canControl: usingMpd ? MpdService.canControl : (mprisPlayer?.canControl ?? false)
    readonly property bool canGoNext: usingMpd ? MpdService.canNext : (mprisPlayer?.canGoNext ?? false)
    readonly property bool canGoPrevious: usingMpd ? MpdService.canPrevious : (mprisPlayer?.canGoPrevious ?? false)
    readonly property string trackTitle: usingMpd ? MpdService.trackTitle : (mprisPlayer?.trackTitle ?? "")
    readonly property string trackArtist: usingMpd ? MpdService.trackArtist : (mprisPlayer?.trackArtist ?? "")
    readonly property string trackAlbum: usingMpd ? MpdService.trackAlbum : (mprisPlayer?.trackAlbum ?? "")
    readonly property string trackArtUrl: usingMpd ? MpdService.trackArtUrl : (mprisPlayer?.trackArtUrl ?? "")
    // Absolute path of the current MPD track file (empty for MPRIS).
    readonly property string trackPath: usingMpd ? MpdService.path : ""
    readonly property string dbusName: usingMpd ? "mpd" : (mprisPlayer?.dbusName ?? "")
    readonly property string identity: usingMpd ? "MPD" : (mprisPlayer?.identity ?? "")
    readonly property string desktopEntry: usingMpd ? "mpd" : (mprisPlayer?.desktopEntry ?? "")
    readonly property var streamHintList: usingMpd ? MpdService.streamHints : buildStreamHints(mprisPlayer)
    readonly property string streamHints: streamHintList.join("|")
    readonly property real length: {
        if (usingMpd) {
            const len = MpdService.length
            return len > 0 ? len : _stableLength
        }
        const len = mprisPlayer?.length ?? 0
        if (len > 0)
            return len
        return mprisPlayer ? _stableLength : 0
    }

    readonly property bool shuffleSupported: usingMpd ? MpdService.shuffleSupported : (mprisPlayer?.shuffleSupported ?? false)
    readonly property bool shuffle: usingMpd ? MpdService.shuffle : (mprisPlayer?.shuffle ?? false)
    readonly property bool loopSupported: usingMpd ? MpdService.loopSupported : (mprisPlayer?.loopSupported ?? false)
    readonly property var loopState: {
        if (usingMpd) {
            if (MpdService.loopMode === "one")
                return MprisLoopState.Track
            if (MpdService.loopMode === "playlist")
                return MprisLoopState.Playlist
            return MprisLoopState.None
        }
        return mprisPlayer?.loopState ?? MprisLoopState.None
    }
    // "off" | "playlist" | "one"
    readonly property string loopMode: {
        if (usingMpd)
            return MpdService.loopMode
        switch (loopState) {
        case MprisLoopState.Track:
            return "one"
        case MprisLoopState.Playlist:
            return "playlist"
        default:
            return "off"
        }
    }

    property real position: 0
    property real _stableLength: 0
    property string _playerId: ""

    property var outputStreams: []
    property int _nodeCount: Pipewire.nodes.values.length
    readonly property real volume: {
        if (usingMpd) {
            const streamVol = outputStreams[0]?.audio?.volume
            if (streamVol !== undefined && streamVol !== null)
                return streamVol
            return MpdService.volume
        }
        return outputStreams[0]?.audio?.volume ?? 0
    }

    signal tick()

    function updateStreams() {
        const out = []
        if (!active) {
            outputStreams = out
            return
        }
        const hints = streamHintList
        for (var n of Pipewire.nodes.values) {
            if (!n.audio || !n.isStream || !n.isSink)
                continue
            if (nodeMatchesHints(n, hints))
                out.push(n)
        }
        outputStreams = out
    }

    on_NodeCountChanged: updateStreams()
    onDbusNameChanged: updateStreams()
    onIdentityChanged: updateStreams()
    onDesktopEntryChanged: updateStreams()
    onStreamHintsChanged: updateStreams()
    onUsingMpdChanged: {
        updateStreams()
        refreshPosition()
    }
    Component.onCompleted: updateStreams()

    PwObjectTracker {
        objects: root.outputStreams
    }

    Connections {
        target: MpdService
        function onTick() {
            if (!root.usingMpd)
                return
            root.position = MpdService.position
            if (MpdService.length > 0)
                root._stableLength = MpdService.length
            root.tick()
        }
        function onActiveChanged() {
            root.updateStreams()
            root.refreshPosition()
        }
        function onIsPlayingChanged() {
            root.updateStreams()
            root.refreshPosition()
        }
        function onTrackTitleChanged() {
            if (root.usingMpd)
                root.updateStreams()
        }
    }

    onMprisPlayerChanged: {
        if (usingMpd)
            return
        const id = mprisPlayer?.dbusName || ""
        if (id !== _playerId) {
            _playerId = id
            _stableLength = (mprisPlayer && mprisPlayer.length > 0) ? mprisPlayer.length : 0
            position = 0
        }
        refreshPosition()
        updateStreams()
    }

    onIsPlayingChanged: {
        if (isPlaying)
            refreshPosition()
        updateStreams()
    }

    Timer {
        interval: 100
        running: root.active && root.isPlaying && !root.usingMpd
        repeat: true
        onTriggered: root.refreshPosition()
    }

    Timer {
        interval: 2000
        running: root.active && root.outputStreams.length === 0
        repeat: true
        onTriggered: root.updateStreams()
    }

    function refreshPosition() {
        if (usingMpd) {
            position = MpdService.position
            if (MpdService.length > 0)
                _stableLength = MpdService.length
            tick()
            return
        }

        if (!mprisPlayer) {
            position = 0
            tick()
            return
        }

        if (mprisPlayer.length > 0)
            _stableLength = mprisPlayer.length

        mprisPlayer.positionChanged()
        position = mprisPlayer.position % mprisPlayer.length
        tick()
    }

    function formatTime(seconds) {
        if (seconds == null || seconds < 0 || !isFinite(seconds))
            return "0:00"
        const total = Math.floor(seconds)
        const h = Math.floor(total / 3600)
        const m = Math.floor((total % 3600) / 60)
        const s = total % 60
        const ss = s < 10 ? "0" + s : "" + s
        if (h > 0) {
            const mm = m < 10 ? "0" + m : "" + m
            return h + ":" + mm + ":" + ss
        }
        return m + ":" + ss
    }

    readonly property string playTime: active
        ? "[" + formatTime(position) + "/" + formatTime(length) + "]"
        : ""

    function play() {
        if (usingMpd) {
            MpdService.play()
            return
        }
        if (mprisPlayer?.canPlay)
            mprisPlayer.play()
    }

    function pause() {
        if (usingMpd) {
            MpdService.pause()
            return
        }
        if (mprisPlayer?.canPause)
            mprisPlayer.pause()
    }

    function togglePlayPause() {
        if (usingMpd) {
            MpdService.togglePlayPause()
            return
        }
        if (!mprisPlayer)
            return
        if (isPlaying && canPause)
            pause()
        else if (canPlay)
            play()
    }

    function next() {
        if (usingMpd) {
            MpdService.next()
            return
        }
        if (mprisPlayer)
            mprisPlayer.next()
    }

    function previous() {
        if (usingMpd) {
            MpdService.previous()
            return
        }
        if (mprisPlayer)
            mprisPlayer.previous()
    }

    function seek(seconds) {
        if (usingMpd) {
            position = seconds
            MpdService.seek(seconds)
            return
        }
        if (!mprisPlayer)
            return
        mprisPlayer.position = seconds
        position = seconds
    }

    function setVolume(value) {
        const v = Math.max(0, Math.min(1, value))
        if (usingMpd) {
            if (outputStreams.length > 0) {
                for (var n of outputStreams) {
                    if (n?.audio)
                        n.audio.volume = v
                }
            } else {
                MpdService.setVolume(v)
            }
            return
        }
        for (var n of outputStreams) {
            if (n?.audio)
                n.audio.volume = v
        }
    }

    function setShuffle(enabled) {
        if (usingMpd) {
            MpdService.setShuffle(enabled)
            return
        }
        if (!mprisPlayer || !shuffleSupported || !canControl)
            return
        mprisPlayer.shuffle = !!enabled
    }

    function toggleShuffle() {
        setShuffle(!shuffle)
    }

    function setLoopMode(mode) {
        if (usingMpd) {
            MpdService.setLoopMode(mode)
            return
        }
        if (!mprisPlayer || !loopSupported || !canControl)
            return
        if (mode === "one")
            mprisPlayer.loopState = MprisLoopState.Track
        else if (mode === "playlist")
            mprisPlayer.loopState = MprisLoopState.Playlist
        else
            mprisPlayer.loopState = MprisLoopState.None
    }

    function cycleLoop() {
        if (usingMpd) {
            MpdService.cycleLoop()
            return
        }
        if (loopMode === "off")
            setLoopMode("playlist")
        else if (loopMode === "playlist")
            setLoopMode("one")
        else
            setLoopMode("off")
    }
}
