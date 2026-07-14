from ytmusicapi import YTMusic
import sys

yt = YTMusic() 

track_name = sys.argv[1]
track_artist = sys.argv[2]
track_album = sys.argv[3]
track_duration = sys.argv[4]
search_results = yt.search(f"{track_name} - {track_artist} - {track_album}", filter="songs")

def get_duration_diff(song):
    duration_str = song.get("duration", "0:00")
    
    parts = duration_str.split(':')
    
    if len(parts) == 2:
        minutes, seconds = int(parts[0]), int(parts[1])
    else:
        minutes, seconds = 0, int(parts[0])
        
    total_seconds = (minutes * 60) + seconds
    
    return abs(total_seconds - float(track_duration))

matching = [
    song for song in search_results
    if song['title'].lower() == track_name.lower() and song['album']['name'].lower() == track_album.lower() and any(a['name'].lower() in track_artist.lower() for a in song['artists'])
]

matching.sort(key=get_duration_diff)

if len(matching) < 1:
    exit()

top_song = matching[0]
if get_duration_diff(top_song) > 5:
    exit()

video_id = top_song['videoId']

watch_playlist = yt.get_watch_playlist(videoId=video_id)
lyrics_id = watch_playlist.get('lyrics')

if lyrics_id:
    lyrics_data = yt.get_lyrics(lyrics_id, timestamps=True)
    
    if lyrics_data.get('hasTimestamps'):
        print("[0] (Lyrics by ytmusic)")
        for line in lyrics_data['lyrics']:
            start = getattr(line, 'start_time', '0') 
            text = getattr(line, 'text', '')
            
            print(f"[{start}] {text}")
            
