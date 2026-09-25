#!/usr/bin/env python3
"""Backend CLI for the quickshell MPD client (library / queue / playlists).

Playback status and controls live in services/mpd (MpdService). This tool
imports the shared protocol client from that package.
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from pathlib import Path
from typing import Any

# Depend on services/mpd (MpdService tooling), not the reverse.
_SERVICES = Path(__file__).resolve().parents[2] / "services"
if str(_SERVICES) not in sys.path:
    sys.path.insert(0, str(_SERVICES))

from mpd.client import (  # noqa: E402
    DEFAULT_HOST,
    DEFAULT_PORT,
    Mpd,
    MpdError,
    absolute_track_path,
    dump,
    ensure_cover,
    fail,
    first_track_file,
    format_duration,
    music_directory,
    parse_format,
    quote,
    records_from_pairs,
    sum_duration,
    track_sort_key,
)

def cmd_artists(mpd: Mpd) -> dict[str, Any]:
    artists = sorted(mpd.list_values("Artist"), key=lambda s: s.casefold())
    return {"ok": True, "artists": artists}


def cmd_search(mpd: Mpd, query: str, limit: int = 1000) -> dict[str, Any]:
    """Match artists, albums, songs, and playlists independently against a query."""
    q = (query or "").strip()
    if not q:
        return {
            "ok": True,
            "query": "",
            "artists": [],
            "albums": [],
            "tracks": [],
            "playlists": [],
            "truncated": False,
        }

    qf = q.casefold()

    # Artists: only names that themselves contain the query.
    artists = sorted(
        (name for name in mpd.list_values("Artist") if qf in name.casefold()),
        key=lambda s: s.casefold(),
    )

    # Albums: only albums whose title contains the query (not parents of song hits).
    albums_map: dict[tuple[str, str], None] = {}
    for row in records_from_pairs(mpd.pairs(f"search album {quote(q)}")):
        album = str(row.get("album") or "")
        if not album or qf not in album.casefold():
            continue
        artist = str(row.get("artist") or "")
        albums_map[(artist, album)] = None
    albums = [
        {"artist": artist, "album": album}
        for artist, album in sorted(
            albums_map.keys(), key=lambda pair: (pair[0].casefold(), pair[1].casefold())
        )
    ]

    # Tracks: any-tag song matches (title, file, genre, etc.).
    tracks = records_from_pairs(mpd.pairs(f"search any {quote(q)}"))
    truncated = False
    if limit > 0 and len(tracks) > limit:
        tracks = tracks[:limit]
        truncated = True
    tracks_sorted = sorted(tracks, key=track_sort_key)

    # Playlists: only names that contain the query.
    playlists = sorted(
        (
            name
            for key, name in mpd.pairs("listplaylists")
            if key == "playlist" and name and qf in name.casefold()
        ),
        key=lambda s: s.casefold(),
    )

    return {
        "ok": True,
        "query": q,
        "artists": artists,
        "albums": albums,
        "tracks": tracks_sorted,
        "playlists": playlists,
        "truncated": truncated,
    }


def cmd_albums(mpd: Mpd, artist: str) -> dict[str, Any]:
    albums = sorted(
        mpd.list_values("Album", "artist", quote(artist)),
        key=lambda s: s.casefold(),
    )
    return {"ok": True, "artist": artist, "albums": albums}


def cmd_tracks(mpd: Mpd, artist: str, album: str) -> dict[str, Any]:
    pairs = mpd.pairs(f"find artist {quote(artist)} album {quote(album)}")
    tracks = records_from_pairs(pairs)
    tracks.sort(key=track_sort_key)
    return {"ok": True, "artist": artist, "album": album, "tracks": tracks}


def cmd_artistinfo(mpd: Mpd, artist: str) -> dict[str, Any]:
    albums = sorted(
        mpd.list_values("Album", "artist", quote(artist)),
        key=lambda s: s.casefold(),
    )
    counts = mpd.count("artist", quote(artist))
    cover = ""
    if albums:
        pairs = mpd.pairs(f"find artist {quote(artist)} album {quote(albums[0])}")
        tracks = records_from_pairs(pairs)
        tracks.sort(key=track_sort_key)
        cover = ensure_cover(mpd, first_track_file(tracks))
    return {
        "ok": True,
        "mode": "artist",
        "artist": artist,
        "albumCount": len(albums),
        "songCount": counts["songs"],
        "duration": counts["playtime"],
        "durationText": format_duration(counts["playtime"]),
        "cover": cover,
        "albums": albums,
    }


def cmd_albuminfo(mpd: Mpd, artist: str, album: str) -> dict[str, Any]:
    pairs = mpd.pairs(f"find artist {quote(artist)} album {quote(album)}")
    tracks = records_from_pairs(pairs)
    tracks.sort(key=track_sort_key)
    duration = sum_duration(tracks)
    cover = ensure_cover(mpd, first_track_file(tracks))

    date = ""
    original_date = ""
    label = ""
    genres: list[str] = []
    extras: dict[str, Any] = {}
    for t in tracks:
        date = date or str(t.get("date") or "")
        original_date = original_date or str(t.get("originalDate") or "")
        label = label or str(t.get("label") or "")
        for g in t.get("genres") or []:
            if g not in genres:
                genres.append(g)
        for k, v in (t.get("extras") or {}).items():
            if k not in extras and not str(k).startswith("MUSICBRAINZ"):
                extras[k] = v

    return {
        "ok": True,
        "mode": "album",
        "artist": artist,
        "album": album,
        "date": date,
        "originalDate": original_date,
        "label": label,
        "genres": genres,
        "trackCount": len(tracks),
        "duration": duration,
        "durationText": format_duration(duration),
        "cover": cover,
        "extras": extras,
    }


def cmd_songinfo(mpd: Mpd, uri: str) -> dict[str, Any]:
    track = resolve_file(mpd, uri)
    if not track:
        fail(f"song not found: {uri}")
    uri = str(track.get("file") or uri)
    cover = ensure_cover(mpd, uri)

    # Merge non-musicbrainz extras into top-level display fields when useful.
    extras = {
        k: v
        for k, v in (track.get("extras") or {}).items()
        if not str(k).startswith("MUSICBRAINZ")
    }

    sample_rate = track.get("sampleRate")
    bits = track.get("bits")
    channels = track.get("channels")

    return {
        "ok": True,
        "mode": "song",
        "file": uri,
        "title": track.get("title") or Path(uri).stem,
        "artist": track.get("artist") or "",
        "album": track.get("album") or "",
        "albumArtist": track.get("albumArtist") or "",
        "track": track.get("track"),
        "disc": track.get("disc"),
        "date": track.get("date") or "",
        "originalDate": track.get("originalDate") or "",
        "label": track.get("label") or "",
        "genres": track.get("genres") or [],
        "duration": track.get("duration", track.get("time", 0)),
        "durationText": format_duration(track.get("duration", track.get("time", 0))),
        "sampleRate": sample_rate,
        "bits": bits,
        "channels": channels,
        "format": track.get("format") or "",
        "cover": cover,
        "extras": extras,
    }


def cmd_playfile(mpd: Mpd, uri: str) -> dict[str, Any]:
    track = resolve_file(mpd, uri)
    if track and track.get("file"):
        uri = str(track["file"])
    mpd.command("clear")
    mpd.command(f"add {quote(uri)}")
    mpd.command("play")
    return {"ok": True, "file": uri}


def cmd_playalbum(mpd: Mpd, artist: str, album: str) -> dict[str, Any]:
    mpd.command("clear")
    mpd.command(f"findadd artist {quote(artist)} album {quote(album)}")
    mpd.command("play")
    return {"ok": True, "artist": artist, "album": album}

def cmd_playartist(mpd: Mpd, artist: str) -> dict[str, Any]:
    mpd.command("clear")
    mpd.command(f"findadd artist {quote(artist)}")
    mpd.command("play")
    return {"ok": True, "artist": artist}


def resolve_file(mpd: Mpd, uri: str) -> dict[str, Any] | None:
    """Map a playlist path to a library song, tolerating stale/basename paths."""
    uri = (uri or "").strip()
    if not uri:
        return None
    tracks = records_from_pairs(mpd.pairs(f"find file {quote(uri)}"))
    if tracks:
        return tracks[0]

    base = Path(uri).name
    if not base:
        return None
    tracks = records_from_pairs(mpd.pairs(f"search file {quote(base)}"))
    if not tracks:
        return None

    uri_norm = uri.replace("\\", "/")
    for t in tracks:
        f = str(t.get("file") or "").replace("\\", "/")
        if f == uri_norm or f.endswith("/" + uri_norm) or f.endswith(uri_norm):
            return t

    matches = [t for t in tracks if Path(str(t.get("file") or "")).name == base]
    if matches:
        return matches[0]
    return tracks[0]


def playlist_entries(mpd: Mpd, name: str) -> list[dict[str, Any]]:
    pairs = mpd.pairs(f"listplaylistinfo {quote(name)}")
    rows = records_from_pairs(pairs)
    if not rows:
        for key, value in mpd.pairs(f"listplaylist {quote(name)}"):
            if key == "file":
                rows.append({"file": value})

    out: list[dict[str, Any]] = []
    for row in rows:
        uri = str(row.get("file") or "")
        resolved = resolve_file(mpd, uri)
        if resolved:
            out.append(resolved)
        elif uri:
            out.append(row)
    return out


def cmd_playlists(mpd: Mpd) -> dict[str, Any]:
    names = sorted(
        (v for k, v in mpd.pairs("listplaylists") if k == "playlist" and v),
        key=lambda s: s.casefold(),
    )
    return {"ok": True, "playlists": names}


def cmd_playlisttracks(mpd: Mpd, name: str) -> dict[str, Any]:
    tracks = playlist_entries(mpd, name)
    return {"ok": True, "playlist": name, "tracks": tracks}


def cmd_playlistinfo(mpd: Mpd, name: str) -> dict[str, Any]:
    tracks = playlist_entries(mpd, name)
    duration = sum_duration(tracks)
    cover = ensure_cover(mpd, first_track_file(tracks))
    return {
        "ok": True,
        "mode": "playlist",
        "playlist": name,
        "songCount": len(tracks),
        "duration": duration,
        "durationText": format_duration(duration),
        "cover": cover,
    }


def cmd_playplaylist(mpd: Mpd, name: str) -> dict[str, Any]:
    tracks = playlist_entries(mpd, name)
    mpd.command("clear")
    added = 0
    for t in tracks:
        uri = str(t.get("file") or "")
        if not uri:
            continue
        try:
            mpd.command(f"add {quote(uri)}")
            added += 1
        except MpdError:
            continue
    if added:
        mpd.command("play")
    return {"ok": True, "playlist": name, "count": added}


def cmd_queueaddplaylist(mpd: Mpd, name: str, where: str = "end") -> dict[str, Any]:
    tracks = playlist_entries(mpd, name)
    if not tracks:
        fail(f"no tracks in playlist: {name}")
    where = (where or "end").strip().lower()
    added = 0

    if where in ("next", "after", "afterthis"):
        status = {k.lower(): v for k, v in mpd.pairs("status")}
        try:
            current = int(status["song"]) if "song" in status else -1
        except ValueError:
            current = -1
        if current < 0:
            for t in tracks:
                uri = str(t.get("file") or "")
                if not uri:
                    continue
                try:
                    mpd.command(f"add {quote(uri)}")
                    added += 1
                except MpdError:
                    continue
        else:
            pos = current + 1
            for t in tracks:
                uri = str(t.get("file") or "")
                if not uri:
                    continue
                try:
                    mpd.command(f"addid {quote(uri)} {pos}")
                    pos += 1
                    added += 1
                except MpdError:
                    continue
        return {
            "ok": True,
            "playlist": name,
            "where": "next",
            "count": added,
            "mutated": "queue",
        }

    for t in tracks:
        uri = str(t.get("file") or "")
        if not uri:
            continue
        try:
            mpd.command(f"add {quote(uri)}")
            added += 1
        except MpdError:
            continue
    return {
        "ok": True,
        "playlist": name,
        "where": "end",
        "count": added,
        "mutated": "queue",
    }


def cmd_rmplaylist(mpd: Mpd, name: str) -> dict[str, Any]:
    name = (name or "").strip()
    if not name:
        fail("playlist name required")
    mpd.command(f"rm {quote(name)}")
    return {"ok": True, "playlist": name, "removedPlaylist": True, "mutated": "playlist"}


def cmd_queue(mpd: Mpd) -> dict[str, Any]:
    pairs = mpd.pairs("playlistinfo")
    tracks = records_from_pairs(pairs)
    status = {k.lower(): v for k, v in mpd.pairs("status")}
    current = -1
    try:
        if "song" in status:
            current = int(status["song"])
    except ValueError:
        current = -1
    return {
        "ok": True,
        "tracks": tracks,
        "current": current,
        "length": len(tracks),
    }


def cmd_currentsong(mpd: Mpd) -> dict[str, Any]:
    pairs = mpd.pairs("currentsong")
    tracks = records_from_pairs(pairs)
    status = {k.lower(): v for k, v in mpd.pairs("status")}
    track = tracks[0] if tracks else {}

    sample_rate = track.get("sampleRate")
    bits = track.get("bits")
    channels = track.get("channels")
    if "audio" in status:
        fmt = parse_format(str(status["audio"]))
        if sample_rate is None:
            sample_rate = fmt.get("sampleRate")
        bits = bits or fmt.get("bits")
        channels = channels or fmt.get("channels")

    genres = track.get("genres") or []
    genre = ", ".join(genres) if genres else ""

    return {
        "ok": True,
        "file": track.get("file") or "",
        "title": track.get("title") or "",
        "artist": track.get("artist") or "",
        "album": track.get("album") or "",
        "track": track.get("track"),
        "disc": track.get("disc"),
        "genre": genre,
        "genres": genres,
        "sampleRate": sample_rate,
        "bits": bits,
        "channels": channels,
        "duration": track.get("duration", track.get("time", 0)),
        "durationText": format_duration(track.get("duration", track.get("time", 0))),
    }


def cmd_queuedel(mpd: Mpd, song_id: int) -> dict[str, Any]:
    mpd.command(f"deleteid {int(song_id)}")
    return cmd_queue(mpd)


def cmd_queueclear(mpd: Mpd) -> dict[str, Any]:
    mpd.command("clear")
    return cmd_queue(mpd)


def cmd_queueplay(mpd: Mpd, pos: int) -> dict[str, Any]:
    mpd.command(f"play {int(pos)}")
    return cmd_queue(mpd)


def canonical_file(mpd: Mpd, uri: str) -> str:
    track = resolve_file(mpd, uri)
    if track and track.get("file"):
        return str(track["file"])
    return (uri or "").replace("\\", "/")


def files_match(mpd: Mpd, a: str, b: str) -> bool:
    ca = canonical_file(mpd, a)
    cb = canonical_file(mpd, b)
    if ca and cb and ca == cb:
        return True
    na = Path(a or "").name
    nb = Path(b or "").name
    return bool(na and nb and na == nb)


def cmd_queueadd(mpd: Mpd, uri: str, where: str = "end") -> dict[str, Any]:
    track = resolve_file(mpd, uri)
    if not track or not track.get("file"):
        fail(f"song not found: {uri}")
    path = str(track["file"])
    where = (where or "end").strip().lower()

    if where in ("next", "after", "afterthis"):
        status = {k.lower(): v for k, v in mpd.pairs("status")}
        try:
            current = int(status["song"]) if "song" in status else -1
        except ValueError:
            current = -1
        if current < 0:
            # Nothing playing / empty queue — fall back to end.
            mpd.command(f"add {quote(path)}")
            pos = None
        else:
            pos = current + 1
            mpd.command(f"addid {quote(path)} {pos}")
        return {"ok": True, "file": path, "where": "next", "pos": pos, "mutated": "queue"}

    mpd.command(f"add {quote(path)}")
    return {"ok": True, "file": path, "where": "end", "pos": None, "mutated": "queue"}


def album_track_list(mpd: Mpd, artist: str, album: str) -> list[dict[str, Any]]:
    pairs = mpd.pairs(f"find artist {quote(artist)} album {quote(album)}")
    tracks = records_from_pairs(pairs)
    tracks.sort(key=track_sort_key)
    return tracks


def artist_track_list(mpd: Mpd, artist: str) -> list[dict[str, Any]]:
    pairs = mpd.pairs(f"find artist {quote(artist)}")
    tracks = records_from_pairs(pairs)
    tracks.sort(key=track_sort_key)
    return tracks


def _queue_add_tracks(
    mpd: Mpd, tracks: list[dict[str, Any]], where: str, meta: dict[str, Any]
) -> dict[str, Any]:
    if not tracks:
        fail("no tracks to add")
    where = (where or "end").strip().lower()
    added = 0

    if where in ("next", "after", "afterthis"):
        status = {k.lower(): v for k, v in mpd.pairs("status")}
        try:
            current = int(status["song"]) if "song" in status else -1
        except ValueError:
            current = -1
        if current < 0:
            for t in tracks:
                uri = str(t.get("file") or "")
                if not uri:
                    continue
                mpd.command(f"add {quote(uri)}")
                added += 1
            where_out = "next"
        else:
            pos = current + 1
            for t in tracks:
                uri = str(t.get("file") or "")
                if not uri:
                    continue
                mpd.command(f"addid {quote(uri)} {pos}")
                pos += 1
                added += 1
            where_out = "next"
    else:
        for t in tracks:
            uri = str(t.get("file") or "")
            if not uri:
                continue
            mpd.command(f"add {quote(uri)}")
            added += 1
        where_out = "end"

    out = {"ok": True, "where": where_out, "count": added, "mutated": "queue"}
    out.update(meta)
    return out


def cmd_queueaddalbum(
    mpd: Mpd, artist: str, album: str, where: str = "end"
) -> dict[str, Any]:
    tracks = album_track_list(mpd, artist, album)
    if not tracks:
        fail(f"no tracks for album: {artist} / {album}")
    return _queue_add_tracks(
        mpd, tracks, where, {"artist": artist, "album": album}
    )


def cmd_queueaddartist(mpd: Mpd, artist: str, where: str = "end") -> dict[str, Any]:
    tracks = artist_track_list(mpd, artist)
    if not tracks:
        fail(f"no tracks for artist: {artist}")
    return _queue_add_tracks(mpd, tracks, where, {"artist": artist})


def cmd_playlistadd(mpd: Mpd, name: str, uri: str) -> dict[str, Any]:
    name = (name or "").strip()
    if not name:
        fail("playlist name required")
    track = resolve_file(mpd, uri)
    if not track or not track.get("file"):
        fail(f"song not found: {uri}")
    path = str(track["file"])
    mpd.command(f"playlistadd {quote(name)} {quote(path)}")
    return {"ok": True, "playlist": name, "file": path, "mutated": "playlist"}


def cmd_playlistaddalbum(
    mpd: Mpd, name: str, artist: str, album: str
) -> dict[str, Any]:
    name = (name or "").strip()
    if not name:
        fail("playlist name required")
    tracks = album_track_list(mpd, artist, album)
    if not tracks:
        fail(f"no tracks for album: {artist} / {album}")
    added = 0
    for t in tracks:
        uri = str(t.get("file") or "")
        if not uri:
            continue
        mpd.command(f"playlistadd {quote(name)} {quote(uri)}")
        added += 1
    return {
        "ok": True,
        "playlist": name,
        "artist": artist,
        "album": album,
        "count": added,
        "mutated": "playlist",
    }


def cmd_playlistaddartist(mpd: Mpd, name: str, artist: str) -> dict[str, Any]:
    name = (name or "").strip()
    if not name:
        fail("playlist name required")
    tracks = artist_track_list(mpd, artist)
    if not tracks:
        fail(f"no tracks for artist: {artist}")
    added = 0
    for t in tracks:
        uri = str(t.get("file") or "")
        if not uri:
            continue
        mpd.command(f"playlistadd {quote(name)} {quote(uri)}")
        added += 1
    return {
        "ok": True,
        "playlist": name,
        "artist": artist,
        "count": added,
        "mutated": "playlist",
    }


def cmd_playlistremove(mpd: Mpd, name: str, uri: str) -> dict[str, Any]:
    name = (name or "").strip()
    if not name:
        fail("playlist name required")
    track = resolve_file(mpd, uri)
    target = str(track["file"]) if track and track.get("file") else (uri or "")
    if not target:
        fail(f"song not found: {uri}")

    pairs = mpd.pairs(f"listplaylistinfo {quote(name)}")
    rows = records_from_pairs(pairs)
    positions = [
        i
        for i, row in enumerate(rows)
        if files_match(mpd, str(row.get("file") or ""), target)
    ]
    removed = 0
    for pos in reversed(positions):
        try:
            mpd.command(f"playlistdelete {quote(name)} {int(pos)}")
            removed += 1
        except MpdError:
            continue
    return {
        "ok": True,
        "playlist": name,
        "file": target,
        "removed": removed,
        "mutated": "playlist",
    }


def _purge_song(mpd: Mpd, path: str, *, update: bool = True) -> dict[str, Any]:
    abs_path = absolute_track_path(path)

    queue_rows = records_from_pairs(mpd.pairs("playlistinfo"))
    removed_queue = 0
    for row in queue_rows:
        if not files_match(mpd, str(row.get("file") or ""), path):
            continue
        sid = row.get("id")
        if sid is None:
            continue
        try:
            mpd.command(f"deleteid {int(sid)}")
            removed_queue += 1
        except MpdError:
            continue

    removed_playlist = 0
    playlists = [
        v for k, v in mpd.pairs("listplaylists") if k == "playlist" and v
    ]
    for pl_name in playlists:
        pairs = mpd.pairs(f"listplaylistinfo {quote(pl_name)}")
        rows = records_from_pairs(pairs)
        positions = [
            i
            for i, row in enumerate(rows)
            if files_match(mpd, str(row.get("file") or ""), path)
        ]
        for pos in reversed(positions):
            try:
                mpd.command(f"playlistdelete {quote(pl_name)} {int(pos)}")
                removed_playlist += 1
            except MpdError:
                continue

    deleted_file = False
    if abs_path and abs_path.is_file():
        try:
            abs_path.unlink()
            deleted_file = True
        except OSError as e:
            fail(f"delete failed: {e}")

    if update and deleted_file:
        update_uri = str(Path(path).parent).replace("\\", "/")
        if update_uri in ("", "."):
            mpd.command("update")
        else:
            try:
                mpd.command(f"update {quote(update_uri)}")
            except MpdError:
                mpd.command("update")
        wait_for_db_update(mpd)

    return {
        "file": path,
        "deletedFile": deleted_file,
        "removedQueue": removed_queue,
        "removedPlaylist": removed_playlist,
    }


def cmd_songdelete(mpd: Mpd, uri: str) -> dict[str, Any]:
    track = resolve_file(mpd, uri)
    if not track or not track.get("file"):
        fail(f"song not found: {uri}")
    path = str(track["file"])
    result = _purge_song(mpd, path, update=True)
    result["ok"] = True
    result["mutated"] = "library"
    return result


def cmd_albumdelete(mpd: Mpd, artist: str, album: str) -> dict[str, Any]:
    tracks = album_track_list(mpd, artist, album)
    if not tracks:
        fail(f"no tracks for album: {artist} / {album}")

    folders: set[str] = set()
    deleted = 0
    removed_queue = 0
    removed_playlist = 0
    for t in tracks:
        uri = str(t.get("file") or "")
        if not uri:
            continue
        result = _purge_song(mpd, uri, update=False)
        if result.get("deletedFile"):
            deleted += 1
            folders.add(str(Path(uri).parent).replace("\\", "/"))
        removed_queue += int(result.get("removedQueue") or 0)
        removed_playlist += int(result.get("removedPlaylist") or 0)

    if folders:
        # Prefer one folder update; fall back to full update if mixed roots.
        if len(folders) == 1:
            folder = next(iter(folders))
            if folder in ("", "."):
                mpd.command("update")
            else:
                try:
                    mpd.command(f"update {quote(folder)}")
                except MpdError:
                    mpd.command("update")
        else:
            mpd.command("update")
        wait_for_db_update(mpd)

    return {
        "ok": True,
        "artist": artist,
        "album": album,
        "deletedFiles": deleted,
        "removedQueue": removed_queue,
        "removedPlaylist": removed_playlist,
        "deletedFile": True,
        "mutated": "library",
    }


def cmd_artistdelete(mpd: Mpd, artist: str) -> dict[str, Any]:
    tracks = artist_track_list(mpd, artist)
    if not tracks:
        fail(f"no tracks for artist: {artist}")

    folders: set[str] = set()
    deleted = 0
    removed_queue = 0
    removed_playlist = 0
    for t in tracks:
        uri = str(t.get("file") or "")
        if not uri:
            continue
        result = _purge_song(mpd, uri, update=False)
        if result.get("deletedFile"):
            deleted += 1
            folders.add(str(Path(uri).parent).replace("\\", "/"))
        removed_queue += int(result.get("removedQueue") or 0)
        removed_playlist += int(result.get("removedPlaylist") or 0)

    if folders:
        if len(folders) == 1:
            folder = next(iter(folders))
            if folder in ("", "."):
                mpd.command("update")
            else:
                try:
                    mpd.command(f"update {quote(folder)}")
                except MpdError:
                    mpd.command("update")
        else:
            mpd.command("update")
        wait_for_db_update(mpd)

    return {
        "ok": True,
        "artist": artist,
        "deletedFiles": deleted,
        "removedQueue": removed_queue,
        "removedPlaylist": removed_playlist,
        "deletedFile": True,
        "mutated": "library",
    }


def _purge_many(mpd: Mpd, tracks: list[dict[str, Any]], meta: dict[str, Any]) -> dict[str, Any]:
    folders: set[str] = set()
    deleted = 0
    removed_queue = 0
    removed_playlist = 0
    for t in tracks:
        uri = str(t.get("file") or "")
        if not uri:
            continue
        result = _purge_song(mpd, uri, update=False)
        if result.get("deletedFile"):
            deleted += 1
            folders.add(str(Path(uri).parent).replace("\\", "/"))
        removed_queue += int(result.get("removedQueue") or 0)
        removed_playlist += int(result.get("removedPlaylist") or 0)

    if folders:
        if len(folders) == 1:
            folder = next(iter(folders))
            if folder in ("", "."):
                mpd.command("update")
            else:
                try:
                    mpd.command(f"update {quote(folder)}")
                except MpdError:
                    mpd.command("update")
        else:
            mpd.command("update")
        wait_for_db_update(mpd)

    out = {
        "ok": True,
        "deletedFiles": deleted,
        "removedQueue": removed_queue,
        "removedPlaylist": removed_playlist,
        "deletedFile": deleted > 0,
        "mutated": "library",
    }
    out.update(meta)
    return out


def cmd_queueaddmany(mpd: Mpd, where: str, files: list[str]) -> dict[str, Any]:
    tracks: list[dict[str, Any]] = []
    for uri in files:
        track = resolve_file(mpd, uri)
        if track:
            tracks.append(track)
    if not tracks:
        fail("no songs found")
    return _queue_add_tracks(mpd, tracks, where, {"count": len(tracks)})


def cmd_queueaddalbummany(
    mpd: Mpd, artist: str, where: str, albums: list[str]
) -> dict[str, Any]:
    tracks: list[dict[str, Any]] = []
    for album in albums:
        tracks.extend(album_track_list(mpd, artist, album))
    if not tracks:
        fail(f"no tracks for albums of: {artist}")
    return _queue_add_tracks(
        mpd, tracks, where, {"artist": artist, "albums": albums}
    )


def cmd_queueaddartistmany(
    mpd: Mpd, where: str, artists: list[str]
) -> dict[str, Any]:
    tracks: list[dict[str, Any]] = []
    for artist in artists:
        tracks.extend(artist_track_list(mpd, artist))
    if not tracks:
        fail("no tracks for artists")
    return _queue_add_tracks(mpd, tracks, where, {"artists": artists})


def cmd_queueaddplaylistmany(
    mpd: Mpd, where: str, names: list[str]
) -> dict[str, Any]:
    tracks: list[dict[str, Any]] = []
    for name in names:
        tracks.extend(playlist_entries(mpd, name))
    if not tracks:
        fail("no tracks in playlists")
    return _queue_add_tracks(mpd, tracks, where, {"playlists": names})


def cmd_playlistaddmany(mpd: Mpd, name: str, files: list[str]) -> dict[str, Any]:
    name = (name or "").strip()
    if not name:
        fail("playlist name required")
    added = 0
    for uri in files:
        track = resolve_file(mpd, uri)
        path = str(track["file"]) if track and track.get("file") else ""
        if not path:
            continue
        mpd.command(f"playlistadd {quote(name)} {quote(path)}")
        added += 1
    return {"ok": True, "playlist": name, "count": added, "mutated": "playlist"}


def cmd_playlistaddalbummany(
    mpd: Mpd, name: str, artist: str, albums: list[str]
) -> dict[str, Any]:
    name = (name or "").strip()
    if not name:
        fail("playlist name required")
    added = 0
    for album in albums:
        for t in album_track_list(mpd, artist, album):
            uri = str(t.get("file") or "")
            if not uri:
                continue
            mpd.command(f"playlistadd {quote(name)} {quote(uri)}")
            added += 1
    return {
        "ok": True,
        "playlist": name,
        "artist": artist,
        "albums": albums,
        "count": added,
        "mutated": "playlist",
    }


def cmd_playlistaddartistmany(
    mpd: Mpd, name: str, artists: list[str]
) -> dict[str, Any]:
    name = (name or "").strip()
    if not name:
        fail("playlist name required")
    added = 0
    for artist in artists:
        for t in artist_track_list(mpd, artist):
            uri = str(t.get("file") or "")
            if not uri:
                continue
            mpd.command(f"playlistadd {quote(name)} {quote(uri)}")
            added += 1
    return {
        "ok": True,
        "playlist": name,
        "artists": artists,
        "count": added,
        "mutated": "playlist",
    }


def cmd_playlistremovemany(mpd: Mpd, name: str, files: list[str]) -> dict[str, Any]:
    removed = 0
    for uri in files:
        result = cmd_playlistremove(mpd, name, uri)
        removed += int(result.get("removed") or 0)
    return {
        "ok": True,
        "playlist": name,
        "removed": removed,
        "mutated": "playlist",
    }


def cmd_songdeletemany(mpd: Mpd, files: list[str]) -> dict[str, Any]:
    tracks: list[dict[str, Any]] = []
    for uri in files:
        track = resolve_file(mpd, uri)
        if track:
            tracks.append(track)
        elif uri:
            tracks.append({"file": uri})
    if not tracks:
        fail("no songs found")
    return _purge_many(mpd, tracks, {"files": [str(t.get("file") or "") for t in tracks]})


def cmd_albumdeletemany(mpd: Mpd, artist: str, albums: list[str]) -> dict[str, Any]:
    tracks: list[dict[str, Any]] = []
    for album in albums:
        tracks.extend(album_track_list(mpd, artist, album))
    if not tracks:
        fail(f"no tracks for albums of: {artist}")
    return _purge_many(mpd, tracks, {"artist": artist, "albums": albums})


def cmd_artistdeletemany(mpd: Mpd, artists: list[str]) -> dict[str, Any]:
    tracks: list[dict[str, Any]] = []
    for artist in artists:
        tracks.extend(artist_track_list(mpd, artist))
    if not tracks:
        fail("no tracks for artists")
    return _purge_many(mpd, tracks, {"artists": artists})


def cmd_rmplaylistmany(mpd: Mpd, names: list[str]) -> dict[str, Any]:
    removed = []
    for name in names:
        name = (name or "").strip()
        if not name:
            continue
        try:
            mpd.command(f"rm {quote(name)}")
            removed.append(name)
        except MpdError:
            continue
    return {
        "ok": True,
        "playlists": removed,
        "removedPlaylist": True,
        "mutated": "playlist",
    }


def wait_for_db_update(mpd: Mpd, timeout: float = 5.0) -> None:
    """Block until MPD finishes an in-progress database update."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        status = {k.lower(): v for k, v in mpd.pairs("status")}
        if "updating_db" not in status:
            return
        time.sleep(0.05)


def cmd_update(mpd: Mpd) -> dict[str, Any]:
    """Rescan the music library and wait until MPD finishes."""
    mpd.command("update")
    wait_for_db_update(mpd, timeout=120.0)
    return {"ok": True, "mutated": "library"}


def main() -> None:
    parser = argparse.ArgumentParser(description="MPD JSON tool for quickshell")
    parser.add_argument("--host", default=DEFAULT_HOST)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("artists")
    sub.add_parser("update")
    p_search = sub.add_parser("search")
    p_search.add_argument("query")
    p_albums = sub.add_parser("albums")
    p_albums.add_argument("artist")
    p_tracks = sub.add_parser("tracks")
    p_tracks.add_argument("artist")
    p_tracks.add_argument("album")
    p_ainfo = sub.add_parser("artistinfo")
    p_ainfo.add_argument("artist")
    p_alinfo = sub.add_parser("albuminfo")
    p_alinfo.add_argument("artist")
    p_alinfo.add_argument("album")
    p_sinfo = sub.add_parser("songinfo")
    p_sinfo.add_argument("file")
    p_play = sub.add_parser("playfile")
    p_play.add_argument("file")
    p_playalbum = sub.add_parser("playalbum")
    p_playalbum.add_argument("artist")
    p_playalbum.add_argument("album")
    p_playartist = sub.add_parser("playartist")
    p_playartist.add_argument("artist")
    sub.add_parser("queue")
    sub.add_parser("queueclear")
    sub.add_parser("currentsong")
    p_queuedel = sub.add_parser("queuedel")
    p_queuedel.add_argument("id", type=int)
    p_queueplay = sub.add_parser("queueplay")
    p_queueplay.add_argument("pos", type=int)
    sub.add_parser("playlists")
    p_pltracks = sub.add_parser("playlisttracks")
    p_pltracks.add_argument("playlist")
    p_plinfo = sub.add_parser("playlistinfo")
    p_plinfo.add_argument("playlist")
    p_playpl = sub.add_parser("playplaylist")
    p_playpl.add_argument("playlist")
    p_queueaddpl = sub.add_parser("queueaddplaylist")
    p_queueaddpl.add_argument("playlist")
    p_queueaddpl.add_argument(
        "where",
        nargs="?",
        default="end",
        choices=["end", "next", "after", "afterthis"],
    )
    p_rmpl = sub.add_parser("rmplaylist")
    p_rmpl.add_argument("playlist")
    p_queueadd = sub.add_parser("queueadd")
    p_queueadd.add_argument("file")
    p_queueadd.add_argument(
        "where",
        nargs="?",
        default="end",
        choices=["end", "next", "after", "afterthis"],
        help="end of queue, or after the current song",
    )
    p_queueaddalbum = sub.add_parser("queueaddalbum")
    p_queueaddalbum.add_argument("artist")
    p_queueaddalbum.add_argument("album")
    p_queueaddalbum.add_argument(
        "where",
        nargs="?",
        default="end",
        choices=["end", "next", "after", "afterthis"],
    )
    p_queueaddartist = sub.add_parser("queueaddartist")
    p_queueaddartist.add_argument("artist")
    p_queueaddartist.add_argument(
        "where",
        nargs="?",
        default="end",
        choices=["end", "next", "after", "afterthis"],
    )
    p_pladd = sub.add_parser("playlistadd")
    p_pladd.add_argument("playlist")
    p_pladd.add_argument("file")
    p_pladdalbum = sub.add_parser("playlistaddalbum")
    p_pladdalbum.add_argument("playlist")
    p_pladdalbum.add_argument("artist")
    p_pladdalbum.add_argument("album")
    p_pladdartist = sub.add_parser("playlistaddartist")
    p_pladdartist.add_argument("playlist")
    p_pladdartist.add_argument("artist")
    p_plrm = sub.add_parser("playlistremove")
    p_plrm.add_argument("playlist")
    p_plrm.add_argument("file")
    p_songdel = sub.add_parser("songdelete")
    p_songdel.add_argument("file")
    p_albumdel = sub.add_parser("albumdelete")
    p_albumdel.add_argument("artist")
    p_albumdel.add_argument("album")
    p_artistdel = sub.add_parser("artistdelete")
    p_artistdel.add_argument("artist")

    p_queueaddmany = sub.add_parser("queueaddmany")
    p_queueaddmany.add_argument("where", choices=["end", "next", "after", "afterthis"])
    p_queueaddmany.add_argument("files", nargs="+")
    p_queueaddalbummany = sub.add_parser("queueaddalbummany")
    p_queueaddalbummany.add_argument("artist")
    p_queueaddalbummany.add_argument("where", choices=["end", "next", "after", "afterthis"])
    p_queueaddalbummany.add_argument("albums", nargs="+")
    p_queueaddartistmany = sub.add_parser("queueaddartistmany")
    p_queueaddartistmany.add_argument("where", choices=["end", "next", "after", "afterthis"])
    p_queueaddartistmany.add_argument("artists", nargs="+")
    p_queueaddplmany = sub.add_parser("queueaddplaylistmany")
    p_queueaddplmany.add_argument("where", choices=["end", "next", "after", "afterthis"])
    p_queueaddplmany.add_argument("playlists", nargs="+")
    p_pladdmany = sub.add_parser("playlistaddmany")
    p_pladdmany.add_argument("playlist")
    p_pladdmany.add_argument("files", nargs="+")
    p_pladdalbummany = sub.add_parser("playlistaddalbummany")
    p_pladdalbummany.add_argument("playlist")
    p_pladdalbummany.add_argument("artist")
    p_pladdalbummany.add_argument("albums", nargs="+")
    p_pladdartistmany = sub.add_parser("playlistaddartistmany")
    p_pladdartistmany.add_argument("playlist")
    p_pladdartistmany.add_argument("artists", nargs="+")
    p_plrmmany = sub.add_parser("playlistremovemany")
    p_plrmmany.add_argument("playlist")
    p_plrmmany.add_argument("files", nargs="+")
    p_songdelmany = sub.add_parser("songdeletemany")
    p_songdelmany.add_argument("files", nargs="+")
    p_albumdelmany = sub.add_parser("albumdeletemany")
    p_albumdelmany.add_argument("artist")
    p_albumdelmany.add_argument("albums", nargs="+")
    p_artistdelmany = sub.add_parser("artistdeletemany")
    p_artistdelmany.add_argument("artists", nargs="+")
    p_rmplmany = sub.add_parser("rmplaylistmany")
    p_rmplmany.add_argument("playlists", nargs="+")

    args = parser.parse_args()
    try:
        mpd = Mpd(args.host, args.port)
    except OSError as e:
        fail(f"connect failed: {e}")
    except MpdError as e:
        fail(str(e))

    try:
        if args.cmd == "artists":
            dump(cmd_artists(mpd))
        elif args.cmd == "update":
            dump(cmd_update(mpd))
        elif args.cmd == "search":
            dump(cmd_search(mpd, args.query))
        elif args.cmd == "albums":
            dump(cmd_albums(mpd, args.artist))
        elif args.cmd == "tracks":
            dump(cmd_tracks(mpd, args.artist, args.album))
        elif args.cmd == "artistinfo":
            dump(cmd_artistinfo(mpd, args.artist))
        elif args.cmd == "albuminfo":
            dump(cmd_albuminfo(mpd, args.artist, args.album))
        elif args.cmd == "songinfo":
            dump(cmd_songinfo(mpd, args.file))
        elif args.cmd == "playfile":
            dump(cmd_playfile(mpd, args.file))
        elif args.cmd == "playalbum":
            dump(cmd_playalbum(mpd, args.artist, args.album))
        elif args.cmd == "playartist":
            dump(cmd_playartist(mpd, args.artist))
        elif args.cmd == "queue":
            dump(cmd_queue(mpd))
        elif args.cmd == "queueclear":
            dump(cmd_queueclear(mpd))
        elif args.cmd == "currentsong":
            dump(cmd_currentsong(mpd))

        elif args.cmd == "queuedel":
            dump(cmd_queuedel(mpd, args.id))
        elif args.cmd == "queueplay":
            dump(cmd_queueplay(mpd, args.pos))
        elif args.cmd == "playlists":
            dump(cmd_playlists(mpd))
        elif args.cmd == "playlisttracks":
            dump(cmd_playlisttracks(mpd, args.playlist))
        elif args.cmd == "playlistinfo":
            dump(cmd_playlistinfo(mpd, args.playlist))
        elif args.cmd == "playplaylist":
            dump(cmd_playplaylist(mpd, args.playlist))
        elif args.cmd == "queueaddplaylist":
            dump(cmd_queueaddplaylist(mpd, args.playlist, args.where))
        elif args.cmd == "rmplaylist":
            dump(cmd_rmplaylist(mpd, args.playlist))
        elif args.cmd == "queueadd":
            dump(cmd_queueadd(mpd, args.file, args.where))
        elif args.cmd == "queueaddalbum":
            dump(cmd_queueaddalbum(mpd, args.artist, args.album, args.where))
        elif args.cmd == "queueaddartist":
            dump(cmd_queueaddartist(mpd, args.artist, args.where))
        elif args.cmd == "playlistadd":
            dump(cmd_playlistadd(mpd, args.playlist, args.file))
        elif args.cmd == "playlistaddalbum":
            dump(cmd_playlistaddalbum(mpd, args.playlist, args.artist, args.album))
        elif args.cmd == "playlistaddartist":
            dump(cmd_playlistaddartist(mpd, args.playlist, args.artist))
        elif args.cmd == "playlistremove":
            dump(cmd_playlistremove(mpd, args.playlist, args.file))
        elif args.cmd == "songdelete":
            dump(cmd_songdelete(mpd, args.file))
        elif args.cmd == "albumdelete":
            dump(cmd_albumdelete(mpd, args.artist, args.album))
        elif args.cmd == "artistdelete":
            dump(cmd_artistdelete(mpd, args.artist))
        elif args.cmd == "queueaddmany":
            dump(cmd_queueaddmany(mpd, args.where, args.files))
        elif args.cmd == "queueaddalbummany":
            dump(cmd_queueaddalbummany(mpd, args.artist, args.where, args.albums))
        elif args.cmd == "queueaddartistmany":
            dump(cmd_queueaddartistmany(mpd, args.where, args.artists))
        elif args.cmd == "queueaddplaylistmany":
            dump(cmd_queueaddplaylistmany(mpd, args.where, args.playlists))
        elif args.cmd == "playlistaddmany":
            dump(cmd_playlistaddmany(mpd, args.playlist, args.files))
        elif args.cmd == "playlistaddalbummany":
            dump(cmd_playlistaddalbummany(mpd, args.playlist, args.artist, args.albums))
        elif args.cmd == "playlistaddartistmany":
            dump(cmd_playlistaddartistmany(mpd, args.playlist, args.artists))
        elif args.cmd == "playlistremovemany":
            dump(cmd_playlistremovemany(mpd, args.playlist, args.files))
        elif args.cmd == "songdeletemany":
            dump(cmd_songdeletemany(mpd, args.files))
        elif args.cmd == "albumdeletemany":
            dump(cmd_albumdeletemany(mpd, args.artist, args.albums))
        elif args.cmd == "artistdeletemany":
            dump(cmd_artistdeletemany(mpd, args.artists))
        elif args.cmd == "rmplaylistmany":
            dump(cmd_rmplaylistmany(mpd, args.playlists))
        else:
            fail(f"unknown command: {args.cmd}")
    except MpdError as e:
        fail(str(e))
    finally:
        mpd.close()


if __name__ == "__main__":
    main()
