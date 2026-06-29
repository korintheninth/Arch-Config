pragma Singleton

import Quickshell.Services.Mpris
import Quickshell
import QtQuick

Singleton {
    id: lyricsFetcher

    // Primary provider is first, fallback is second — swap entries to switch backends
    readonly property var lyricsProviders: ["musixmatch", "netease"]

    property var lyricsMap: new Map()
    property var activeLyrics: []
    property string _lastKey: ""

    function isRealPlayer(p) {
        const entry = (p?.desktopEntry ?? "").toLowerCase()
        const identity = (p?.identity ?? "").toLowerCase()
        return p && (entry === "spotify"
            || identity.includes("youtube-music")
            || identity.includes("mixtapes"))
    }

    property MprisPlayer player: {
        const players = Mpris.players.values
        for (const p of players)
            if (p.isPlaying && isRealPlayer(p)) return p
        for (const p of players)
            if (isRealPlayer(p)) return p
        return null
    }
    
    Timer {
        id: debounceTimer
        interval: 500
        repeat: false
        onTriggered: {
            fetchLyrics(player.trackTitle, player.trackArtist, player.trackAlbum, player.length)
        }

    }
    
    Connections {
        target: player
        function onTrackTitleChanged() { debounceTimer.restart() }
    }

    function updateLyrics() {
        debounceTimer.restart()
    }

    function fetchLyrics(trackName, trackArtist, trackAlbum, trackLength) {
        if (!trackName || trackName == "" || !trackArtist || trackArtist == "") return
        activeLyrics = []
        var key = trackName + "|" + trackArtist 
        if (key in lyricsMap || key == _lastKey) {
            parseLyrics(lyricsMap[trackName + "|" + trackArtist])
            console.log("Succesfully recalled lyrics for:", trackName, trackArtist)
            return
        }
        _lastKey = key
        fetchFromProvider(lyricsProviders[0], trackName, trackArtist, trackAlbum, trackLength)
    }

    function fetchFromProvider(provider, trackName, trackArtist, trackAlbum, trackLength) {
        switch (provider) {
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
        console.log(`[Lyrics/${failedProvider}] ${reason}${detailSuffix}: "${trackName}" by "${trackArtist}"`)
        const nextIndex = lyricsProviders.indexOf(failedProvider) + 1
        if (nextIndex < lyricsProviders.length)
            fetchFromProvider(lyricsProviders[nextIndex], trackName, trackArtist, trackAlbum, trackLength)
    }

    function fetchLyricsNetease(trackName, trackArtist, trackAlbum, trackLength) {
        if (!trackName || !trackArtist) {
            console.log("[Lyrics/NetEase] Missing track name or artist, skipping search")
            return
        }

        const xhr = new XMLHttpRequest();
        const query = encodeURIComponent(trackName + " " + trackArtist);

        xhr.open("GET", `https://music.163.com/api/cloudsearch/pc?s=${query}&type=1&limit=1&offset=0`);
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        xhr.setRequestHeader("Referer", "https://music.163.com/");
        xhr.setRequestHeader("Cookie", "os=pc; appver=2.9.7;");
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;

            if (xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText);
                    
                    if (data.result && data.result.songs && data.result.songs.length > 0) {
                        let trackId = data.result.songs[0].id;
                        
                        fetchNetEaseSubtitles(trackId, trackName, trackArtist, trackAlbum, trackLength);
                    } else {
                        providerFallback("netease", "Search returned no matching songs", trackName, trackArtist, trackAlbum, trackLength)
                    }
                } catch (e) {
                    providerFallback("netease", "Search response parse error", trackName, trackArtist, trackAlbum, trackLength, e.message ?? String(e))
                }
            } else {
                providerFallback("netease", "Search HTTP error", trackName, trackArtist, trackAlbum, trackLength, `status ${xhr.status}`)
            }
        };
        xhr.send(null);
    }

    function fetchNetEaseSubtitles(trackId, trackName, trackArtist, trackAlbum, trackLength) {
        const xhr = new XMLHttpRequest();
        const url = `https://music.163.com/api/song/lyric?id=${trackId}&lv=1&kv=1&tv=-1`;
        
        xhr.open("GET", url);
        xhr.setRequestHeader("Referer", "https://music.163.com/");
        xhr.setRequestHeader("Cookie", "os=pc; appver=2.9.7;");
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        let data = JSON.parse(xhr.responseText);
                        
                        if (data.lrc && data.lrc.lyric) {
                            let syncedText = data.lrc.lyric;
                            syncedText = syncedText.replace(/[\u4e00-\u9fa5]/g, '');
                            if (syncedText.trim() == "" || !syncedText) {
                                providerFallback("netease", "Lyrics empty after stripping Chinese characters", trackName, trackArtist, trackAlbum, trackLength, `trackId ${trackId}`)
                                return
                            }
                            lyricsMap[trackName + "|" + trackArtist] = syncedText
                                parseLyrics(syncedText)
                            console.log("Succesfully added lyrics for:", trackName, trackArtist)
                        } else {
                            providerFallback("netease", "Lyric response missing lrc.lyric", trackName, trackArtist, trackAlbum, trackLength, `trackId ${trackId}`)
                        }
                    } catch (e) {
                        providerFallback("netease", "Lyric response parse error", trackName, trackArtist, trackAlbum, trackLength, e.message ?? String(e))
                    }
                } else {
                    providerFallback("netease", "Lyric HTTP error", trackName, trackArtist, trackAlbum, trackLength, `status ${xhr.status}, trackId ${trackId}`)
                }
            } 
        };
        xhr.send(null);
    }

    function fetchLyricsMusixmatch(trackName, trackArtist, trackAlbum, trackLength) {
        if (!trackName || !trackArtist) return

        const tokens = [
            "2501192ac605cc2e16b6b2c04fe43d1011a38d919fe802976084e7", //works
            "1710144894f79b194e5a5866d9e084d48f227d257dcd8438261277", //works
            "240907c8a5257abdda0a975ac3ec819a5bb759721255daec124ddc", //works
            "180220daeb2405592f296c4aea0f6d15e90e08222b559182bacf92", //works
            "191231a5ea353397cca5b11ab22048db1f50f515a99e174078b148" //works
        ];

        const token = tokens[Math.floor(Math.random() * tokens.length)];
        const xhr = new XMLHttpRequest()
        const params = new URLSearchParams({
                format: "json",
                q_track: trackName,
                q_artist: trackArtist,
                q_album: trackAlbum,
                q_duration: trackLength,
                app_id: "web-desktop-app-v1.0",
                usertoken: token,
                f_has_lyrics: 1, 
                f_has_subtitles: 1,
                s_track_rating: "desc",
            });

        const url = `https://apic-desktop.musixmatch.com/ws/1.1/track.search?${params.toString()}`;
        xhr.open("GET", url)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

            if (xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText)
                    let trackList = data.message.body.track_list
                    
                    if (trackList && trackList.length > 0) {
                        let trackId = trackList[0].track.track_id
                        fetchSubtitles(trackId, token, trackName, trackArtist, trackAlbum, trackLength)
                    } else {
                        providerFallback("musixmatch", "Search returned no matching tracks", trackName, trackArtist, trackAlbum, trackLength)
                    }
                } catch (e) {
                    providerFallback("musixmatch", "Search response parse error", trackName, trackArtist, trackAlbum, trackLength, e.message ?? String(e))
                }
            } else {
                providerFallback("musixmatch", "Search HTTP error", trackName, trackArtist, trackAlbum, trackLength, `status ${xhr.status}`)
            }
        }
        xhr.send(null)
    }

    function fetchSubtitles(trackId, token, trackName, trackArtist, trackAlbum, trackLength) {
        const xhr = new XMLHttpRequest()
        const params = new URLSearchParams({
            format: "json",
            track_id: trackId,
            app_id: "web-desktop-app-v1.0",
            usertoken: token
        })
        
        xhr.open("GET", `https://apic-desktop.musixmatch.com/ws/1.1/track.subtitles.get?${params.toString()}`)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

            if (xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText)
                    let subs = data.message.body.subtitle_list
                    
                    if (subs && subs.length > 0) {
                        let syncedText = subs[0].subtitle.subtitle_body
                        lyricsMap[trackName + "|" + trackArtist] = syncedText
                        parseLyrics(syncedText)
                        console.log("Succesfully added lyrics for:", trackName, trackArtist)
                    } else {
                        providerFallback("musixmatch", "Subtitle response empty", trackName, trackArtist, trackAlbum, trackLength, `trackId ${trackId}`)
                    }
                } catch (e) {
                    providerFallback("musixmatch", "Subtitle response parse error", trackName, trackArtist, trackAlbum, trackLength, e.message ?? String(e))
                }
            } else {
                providerFallback("musixmatch", "Subtitle HTTP error", trackName, trackArtist, trackAlbum, trackLength, `status ${xhr.status}, trackId ${trackId}`)
            }
        }
        xhr.send(null)
    }

    function parseLyrics(lyrics) {
        var lines = lyrics.split("\n")
        for (var line of lines) {
            let closeBracketIndex = line.indexOf("]");
            var timestr = line.slice(1, closeBracketIndex).trim("")
            var parts = timestr.split(":")
            var timesec = parseInt(parts[0]) * 60 + parseFloat(parts[1])
            var body = {
                timestamp: timesec,
                lyric: line.slice(closeBracketIndex + 1)
            }
            activeLyrics.push(body)
        }
        return activeLyrics
    }
}
