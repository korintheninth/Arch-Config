from ytmusicapi import YTMusic
import sys
import cutlet
from pypinyin import pinyin, Style
import re
import urllib3.util.connection as urllib3_conn

# music.youtube.com AAAA is Google APAC anycast; TCP/443 black-holes from this
# network. urllib3 tries those first (no Happy Eyeballs), ~30s each.
urllib3_conn.HAS_IPV6 = False

katsu = cutlet.Cutlet()
katsu.use_foreign_spelling = False

yt = YTMusic() 

track_name = sys.argv[1]
track_artist = sys.argv[2]
track_album = sys.argv[3]
track_duration = sys.argv[4]
search_results = yt.search(f"{track_name} - {track_artist} - {track_album}", filter="songs")

def compact_title(text):
    return re.sub(r"\s+", "", str(text or "").lower())

def get_duration_diff(song):
    duration_str = song.get("duration", "0:00")
    
    parts = duration_str.split(':')
    
    if len(parts) == 2:
        minutes, seconds = int(parts[0]), int(parts[1])
    else:
        minutes, seconds = 0, int(parts[0])
        
    total_seconds = (minutes * 60) + seconds
    
    return abs(total_seconds - float(track_duration))

def song_album_name(song):
    album = song.get("album") or {}
    if isinstance(album, dict):
        return album.get("name", "")
    return str(album)

def album_matches(song):
    target = compact_title(track_album)
    if not target:
        return False
    return compact_title(song_album_name(song)) == target

def to_pinyin(line):
    converted = pinyin(line, style=Style.TONE)
    pinyin_line = ' '.join([word[0] for word in converted])
    return pinyin_line

def to_romaji(line):
    return katsu.romaji(line)

def detect_lyric_language(line):
    has_kana = bool(re.search(r'[\u3040-\u309F\u30A0-\u30FF]', line))
    has_cjk_ideographs = bool(re.search(r'[\u4E00-\u9FFF]', line))
    
    if has_kana:
        return "japanese"
    elif has_cjk_ideographs and not has_kana:
        return "chinese"
    else:
        return "latin"

target_title = compact_title(track_name)

matching = [
    song for song in search_results
    if compact_title(song.get("title")) == target_title
        and any(a['name'].lower() in track_artist.lower() or track_artist.lower() in a['name'].lower() for a in song['artists'])
]

if len(matching) < 1:
    exit()

matching.sort(key=lambda song: (0 if album_matches(song) else 1, get_duration_diff(song)))

top_song = matching[0]

if get_duration_diff(top_song) > 1:
    exit()

video_id = top_song['videoId']

watch_playlist = yt.get_watch_playlist(videoId=video_id)
lyrics_id = watch_playlist.get('lyrics')

if lyrics_id:
    lyrics_data = yt.get_lyrics(lyrics_id, timestamps=True)
    
    if lyrics_data.get('hasTimestamps'):
        print("[0] (Lyrics by ytmusic)")
        print(f"[0] ({top_song['title']} - {' & '.join(artist['name'] for artist in top_song['artists'])} - {top_song['album']['name']})")
        for line in lyrics_data['lyrics']:
            text = getattr(line, 'text', '')
            lang = detect_lyric_language(text)
            if lang == "japanese":
                text = to_romaji(text)
            elif lang == "chinese":
                text = to_pinyin(text)

            start = getattr(line, 'start_time', '0') 
            
            print(f"[{start}] {text}")
            
