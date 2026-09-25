pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Io
import "../components"

Singleton {
    id: lyricsFetcher

    readonly property var lyricsProviders: ["local", "ytmusic", "musixmatch", "netease"]

    property var lyricsMap: ({})
    property string trackKey: ""
    property string _lastKey: ""

    // Figure/en/em dashes, non-breaking hyphen, minus sign, fullwidth hyphen, etc. → ASCII "-"
    function normalizeMeta(text) {
        return String(text ?? "")
            .replace(/[\u00AD\u2010\u2011\u2012\u2013\u2014\u2015\u2212\uFE58\uFE63\uFF0D]/g, "-")
            .trim()
    }

    function makeKey(trackName, trackArtist) {
        return normalizeMeta(trackName) + "|" + normalizeMeta(trackArtist)
    }

    // Sibling .lrc next to the playing file (same folder, same basename).
    function resolveLocalLrcPath(trackPath) {
        let abs = String(trackPath ?? "").trim()
        if (!abs)
            return ""
        if (abs.startsWith("file://"))
            abs = decodeURIComponent(abs.slice(7))
        if (!abs.startsWith("/"))
            return ""
        const slash = Math.max(abs.lastIndexOf("/"), abs.lastIndexOf("\\"))
        if (slash < 0)
            return ""
        const dot = abs.lastIndexOf(".")
        if (dot > slash)
            return abs.slice(0, dot) + ".lrc"
        return abs + ".lrc"
    }

    function refreshTrackKey() {
        const title = normalizeMeta(PlayerService.trackTitle)
        const artist = normalizeMeta(PlayerService.trackArtist)
        if (!title || !artist)
            return
        const key = makeKey(title, artist)
        if (trackKey !== key)
            trackKey = key
    }

    Timer {
        id: debounceTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (!PlayerService.trackTitle || PlayerService.trackTitle == ""
                || !PlayerService.trackArtist || PlayerService.trackArtist == ""
                || !PlayerService.length || PlayerService.length == 0)
                return
            fetchLyrics(PlayerService.trackTitle, PlayerService.trackArtist, PlayerService.trackAlbum, PlayerService.length)
        }
    }

    Connections {
        target: PlayerService
        function onTrackTitleChanged() { refreshTrackKey() }
        function onTrackArtistChanged() { refreshTrackKey() }
        function onTrackAlbumChanged() { debounceTimer.restart() }
        function onLengthChanged() { debounceTimer.restart() }
        function onPlayerChanged() { refreshTrackKey() }
    }

    Connections {
        target: lyricsFetcher
        function onTrackKeyChanged() { debounceTimer.restart() }
    }

    function updateLyrics() {
        refreshTrackKey()
        debounceTimer.restart()
    }

    Component.onCompleted: updateLyrics()

    CurlRequest {
        id: http
        name: "Lyrics"
        timeoutSec: 20
    }

    function fetchLyrics(trackName, trackArtist, trackAlbum, trackLength) {
        trackName = normalizeMeta(trackName)
        trackArtist = normalizeMeta(trackArtist)
        trackAlbum = normalizeMeta(trackAlbum)
        if (!trackName || trackName == "" || !trackArtist || trackArtist == "" || !trackLength || trackLength == 0) return
        var key = makeKey(trackName, trackArtist)
        if (lyricsMap[key] || key == _lastKey) {
            console.log("Succesfully recalled lyrics for:", trackName, trackArtist)
            return
        }
        _lastKey = key
        fetchFromProvider(lyricsProviders[0], trackName, trackArtist, trackAlbum, trackLength)
    }

    function fetchFromProvider(provider, trackName, trackArtist, trackAlbum, trackLength) {
        switch (provider) {
        case "local":
            fetchLyricsLocal(trackName, trackArtist, trackAlbum, trackLength)
            break
        case "ytmusic":
            fetchLyricsYTMusic(trackName, trackArtist, trackAlbum, trackLength)
            break
        case "netease":
            fetchLyricsNetease(trackName, trackArtist, trackAlbum, trackLength)
            break
        case "musixmatch":
            fetchLyricsMusixmatch(trackName, trackArtist, trackAlbum, trackLength)
            break
        default:
            console.log(`[Lyrics] Unknown provider "${provider}"`)
        }
    }

    function providerFallback(failedProvider, reason, trackName, trackArtist, trackAlbum, trackLength, detail) {
        const detailSuffix = detail !== undefined && detail !== "" ? ` (${detail})` : ""
        console.log(`[Lyrics/${failedProvider}] ${reason}${detailSuffix}: "${trackName}" by "${trackArtist}" - "${trackAlbum}" - "${trackLength}"`)
        const nextIndex = lyricsProviders.indexOf(failedProvider) + 1
        if (nextIndex < lyricsProviders.length)
            fetchFromProvider(lyricsProviders[nextIndex], trackName, trackArtist, trackAlbum, trackLength)
        else {
            const key = makeKey(trackName, trackArtist)
            lyricsMap[key] = [{
                timestamp: 0,
                lyric: "♪♪♪"
            }]
        }
    }

    function primaryArtist(artist) {
        return String(artist ?? "").replace(/\s*(?:[&,]|feat\.?|ft\.?|featuring)\s+.*/i, "").trim()
    }

    function compactTitle(text) {
        return String(text ?? "").toLowerCase().replace(/\s+/g, "")
    }

    function isBetterCandidate(diff, albumMatch, bestDiff, bestAlbumMatch) {
        if (bestDiff === Infinity)
            return true
        if (albumMatch !== bestAlbumMatch)
            return albumMatch
        return diff < bestDiff
    }

    function pickNeteaseSong(songs, trackName, trackArtist, trackAlbum, trackLength) {
        const title = compactTitle(trackName)
        const artist = primaryArtist(trackArtist).toLowerCase()
        const album = compactTitle(trackAlbum)
        const targetMs = Number(trackLength) * 1000
        let best = null
        let bestDiff = Infinity
        let bestAlbumMatch = false
        for (const song of songs) {
            if (compactTitle(song.name) !== title)
                continue
            const artists = song.ar || song.artists || []
            if (!artists.some(a => String(a.name ?? "").toLowerCase() === artist))
                continue
            const songAlbum = compactTitle(song.al?.name ?? song.album?.name ?? "")
            const albumMatch = !!(album && songAlbum && songAlbum === album)
            const diff = Math.abs((Number(song.dt) || 0) - targetMs)
            if (isBetterCandidate(diff, albumMatch, bestDiff, bestAlbumMatch)) {
                best = song
                bestDiff = diff
                bestAlbumMatch = albumMatch
            }
        }
        return best
    }

    function httpGet(url, headers, callback) {
        http.request({
            url: url,
            headers: headers,
            callback: callback
        })
    }

    function fetchLyricsNetease(trackName, trackArtist, trackAlbum, trackLength) {
        if (!trackName || !trackArtist) {
            console.log("[Lyrics/NetEase] Missing track name or artist, skipping search")
            return
        }

        const query = encodeURIComponent(trackName + " " + primaryArtist(trackArtist))
        httpGet(
            `https://music.163.com/api/cloudsearch/pc?s=${query}&type=1&limit=5&offset=0`,
            {
                "Content-Type": "application/x-www-form-urlencoded",
                "Referer": "https://music.163.com/",
                "Cookie": "os=pc; appver=2.9.7;",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            },
            function(data, status) {
                if (status !== 200) {
                    providerFallback("netease", "Search HTTP error", trackName, trackArtist, trackAlbum, trackLength, `status ${status}`)
                    return
                }
                try {
                    const songs = data && data.result && data.result.songs
                    const song = songs && pickNeteaseSong(songs, trackName, trackArtist, trackAlbum, trackLength)
                    if (song)
                        fetchNetEase(song.id, trackName, trackArtist, trackAlbum, trackLength)
                    else
                        providerFallback("netease", "Search returned no matching songs", trackName, trackArtist, trackAlbum, trackLength)
                } catch (e) {
                    providerFallback("netease", "Search response parse error", trackName, trackArtist, trackAlbum, trackLength, e.message ?? String(e))
                }
            }
        )
    }

    function fetchNetEase(trackId, trackName, trackArtist, trackAlbum, trackLength) {
        httpGet(
            `https://music.163.com/api/song/lyric?id=${trackId}&lv=1&kv=1&tv=-1`,
            {
                "Referer": "https://music.163.com/",
                "Cookie": "os=pc; appver=2.9.7;",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            },
            function(data, status) {
                if (status !== 200) {
                    providerFallback("netease", "Lyric HTTP error", trackName, trackArtist, trackAlbum, trackLength, `status ${status}, trackId ${trackId}`)
                    return
                }
                try {
                    if (data && data.lrc && data.lrc.lyric) {
                        let syncedText = data.lrc.lyric
                        syncedText = syncedText.replace(/[\u4e00-\u9fa5]/g, '')
                        if (syncedText.trim() == "" || !syncedText) {
                            providerFallback("netease", "Lyrics empty after stripping Chinese characters", trackName, trackArtist, trackAlbum, trackLength, `trackId ${trackId}`)
                            return
                        }
                        const key = makeKey(trackName, trackArtist)
                        parseLyrics("[0] (Lyrics By NetEase)\n" + syncedText, key)
                        console.log("Succesfully added lyrics for:", trackName, trackArtist)
                    } else {
                        providerFallback("netease", "Lyric response missing lrc.lyric", trackName, trackArtist, trackAlbum, trackLength, `trackId ${trackId}`)
                    }
                } catch (e) {
                    providerFallback("netease", "Lyric response parse error", trackName, trackArtist, trackAlbum, trackLength, e.message ?? String(e))
                }
            }
        )
    }

    function fetchLyricsMusixmatch(trackName, trackArtist, trackAlbum, trackLength) {
        if (!trackName || !trackArtist)
            return

        const tokens = [
            "2501192ac605cc2e16b6b2c04fe43d1011a38d919fe802976084e7",
            "1710144894f79b194e5a5866d9e084d48f227d257dcd8438261277",
            "240907c8a5257abdda0a975ac3ec819a5bb759721255daec124ddc",
            "180220daeb2405592f296c4aea0f6d15e90e08222b559182bacf92",
            "191231a5ea353397cca5b11ab22048db1f50f515a99e174078b148"
        ]
        const token = tokens[Math.floor(Math.random() * tokens.length)]
        const params = new URLSearchParams({
            format: "json",
            q_track: trackName,
            q_artist: primaryArtist(trackArtist) || trackArtist,
            q_album: trackAlbum,
            q_duration: trackLength,
            app_id: "web-desktop-app-v1.0",
            usertoken: token,
            f_has_lyrics: 1,
            f_has_subtitles: 1,
            s_track_rating: "desc"
        })

        httpGet(
            `https://apic-desktop.musixmatch.com/ws/1.1/track.search?${params.toString()}`,
            {},
            function(data, status) {
                if (status !== 200) {
                    providerFallback("musixmatch", "Search HTTP error", trackName, trackArtist, trackAlbum, trackLength, `status ${status}`)
                    return
                }
                try {
                    const trackList = data && data.message && data.message.body && data.message.body.track_list
                    const track = trackList && pickMusixmatchTrack(trackList, trackName, trackArtist, trackAlbum, trackLength)
                    if (track)
                        fetchMusixmatch(track.track_id, token, trackName, trackArtist, trackAlbum, trackLength)
                    else
                        providerFallback("musixmatch", "Search returned no matching tracks", trackName, trackArtist, trackAlbum, trackLength)
                } catch (e) {
                    providerFallback("musixmatch", "Search response parse error", trackName, trackArtist, trackAlbum, trackLength, e.message ?? String(e))
                }
            }
        )
    }

    function pickMusixmatchTrack(trackList, trackName, trackArtist, trackAlbum, trackLength) {
        const title = compactTitle(trackName)
        const artist = primaryArtist(trackArtist).toLowerCase()
        const album = compactTitle(trackAlbum)
        const targetSec = Number(trackLength)
        let best = null
        let bestDiff = Infinity
        let bestAlbumMatch = false
        for (const item of trackList) {
            const track = item.track || item
            if (compactTitle(track.track_name) !== title)
                continue
            if (primaryArtist(track.artist_name).toLowerCase() !== artist)
                continue
            const songAlbum = compactTitle(track.album_name)
            const albumMatch = !!(album && songAlbum && songAlbum === album)
            const diff = Math.abs((Number(track.track_length) || 0) - targetSec)
            if (isBetterCandidate(diff, albumMatch, bestDiff, bestAlbumMatch)) {
                best = track
                bestDiff = diff
                bestAlbumMatch = albumMatch
            }
        }
        return best
    }

    function fetchMusixmatch(trackId, token, trackName, trackArtist, trackAlbum, trackLength) {
        const params = new URLSearchParams({
            format: "json",
            track_id: trackId,
            subtitle_format: "lrc",
            app_id: "web-desktop-app-v1.0",
            usertoken: token
        })

        httpGet(
            `https://apic-desktop.musixmatch.com/ws/1.1/track.subtitle.get?${params.toString()}`,
            {},
            function(data, status) {
                if (status !== 200) {
                    providerFallback("musixmatch", "Subtitle HTTP error", trackName, trackArtist, trackAlbum, trackLength, `status ${status}, trackId ${trackId}`)
                    return
                }
                try {
                    const body = (data && data.message && data.message.body) || {}
                    const subtitle = body.subtitle
                        || (body.subtitle_list && body.subtitle_list[0] && body.subtitle_list[0].subtitle)
                    const syncedText = subtitle && subtitle.subtitle_body
                    if (data && data.message && data.message.header && data.message.header.status_code === 200 && syncedText) {
                        parseLyrics("[0] (Lyrics By Musixmatch)\n" + syncedText, makeKey(trackName, trackArtist))
                        console.log("Succesfully added lyrics for:", trackName, trackArtist)
                    } else {
                        providerFallback("musixmatch", "Subtitle response empty", trackName, trackArtist, trackAlbum, trackLength, `trackId ${trackId}`)
                    }
                } catch (e) {
                    providerFallback("musixmatch", "Subtitle response parse error", trackName, trackArtist, trackAlbum, trackLength, e.message ?? String(e))
                }
            }
        )
    }

    Component {
        id: localLrcFactory

        FileView {
            id: localLrc

            property string trackName: ""
            property string trackArtist: ""
            property string trackAlbum: ""
            property var trackLength: 0

            printErrors: false
            onLoaded: {
                const raw = text().trim()
                if (!raw) {
                    providerFallback("local", "Empty lrc", localLrc.trackName, localLrc.trackArtist, localLrc.trackAlbum, localLrc.trackLength)
                } else {
                    parseLyrics("[0] (Lyrics By Local)\n" + raw, makeKey(localLrc.trackName, localLrc.trackArtist))
                    console.log("Succesfully added lyrics for:", localLrc.trackName, localLrc.trackArtist)
                }
                localLrc.destroy()
            }
            onLoadFailed: {
                providerFallback("local", "No local lrc", localLrc.trackName, localLrc.trackArtist, localLrc.trackAlbum, localLrc.trackLength, path)
                localLrc.destroy()
            }
        }
    }

    function fetchLyricsLocal(trackName, trackArtist, trackAlbum, trackLength) {
        const lrcPath = resolveLocalLrcPath(PlayerService.trackPath)
        if (!lrcPath) {
            providerFallback("local", "No track path", trackName, trackArtist, trackAlbum, trackLength)
            return
        }
        localLrcFactory.createObject(lyricsFetcher, {
            trackName: trackName,
            trackArtist: trackArtist,
            trackAlbum: trackAlbum,
            trackLength: trackLength,
            path: lrcPath
        })
    }

    Component {
        id: lyricsProcessFactory

        Process {
            id: dynProcess
            
            property string trackName: ""
            property string trackArtist: ""
            property string trackAlbum: ""
            property var trackLength: 0

            command: [
                "/home/korin/.config/quickshell/Scripts/venv/bin/python",
                "/home/korin/.config/quickshell/Scripts/ytlyrics.py",
                trackName,
                primaryArtist(trackArtist),
                trackAlbum,
                trackLength
            ]

            stdout: StdioCollector {
                onStreamFinished: {
                    const output = text.trim()
                    if (!output) {
                        providerFallback("ytmusic", "No lyrics returned", dynProcess.trackName, dynProcess.trackArtist, dynProcess.trackAlbum, dynProcess.trackLength)
                    } else {
                        const key = makeKey(dynProcess.trackName, dynProcess.trackArtist)
                        parseLyrics(output, key)
                    }
                    dynProcess.destroy()
                }
            }
        }
    }

    function fetchLyricsYTMusic(trackName, trackArtist, trackAlbum, trackLength) {
        if (!trackName || !trackArtist || !trackLength) return
        console.log(trackName, primaryArtist(trackArtist), trackAlbum, trackLength)
        lyricsProcessFactory.createObject(lyricsFetcher, {
            trackName: trackName,
            trackArtist: trackArtist,
            trackAlbum: trackAlbum,
            trackLength: trackLength,
            running: true
        })
    }

    function parseLyrics(lyrics, key) {
        var parsed = []
        var lines = lyrics.split("\n")
        for (var line of lines) {
            let closeBracketIndex = line.indexOf("]");
            var timesec = 0;
            var timestr = line.slice(1, closeBracketIndex).trim("")
            var parts = timestr.split(":")
            timesec = parts.length >= 2
                ? parseInt(parts[0]) * 60 + parseFloat(parts[1])
                : parseInt(timestr) / 1000
            var body = {
                timestamp: timesec,
                lyric: line.slice(closeBracketIndex + 1)
            }
            parsed.push(body)
        }
        lyricsMap[key] = parsed
        return parsed
    }
}
