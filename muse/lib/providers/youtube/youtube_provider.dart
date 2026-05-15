import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../models/song.dart';
import '../base/music_provider.dart';

class YouTubeProvider implements MusicProvider {
  final YoutubeExplode _yt = YoutubeExplode();

  @override
  String get sourceName => 'youtube';

  @override
  Future<List<Song>> search(String query) async {
    try {
      final VideoSearchList results = await _yt.search(query);
      
      return results.map((video) {
        return Song(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          albumArt: video.thumbnails.highResUrl, 
          audioURL: "", 
          duration: video.duration,
          source: SongSource.youtube,
        );
      }).toList();
    } catch (e) {
      print("YouTube Search Error: $e");
      return [];
    }
  }

  // extract only on play
  @override
  Future<String?> getStreamUrl(String id) async {
    try {
      // This is the "Vanced" part. We ask the internal API for the stream map.
      final manifest = await _yt.videos.streamsClient.getManifest(id);
      
      // Grab the highest quality audio-only file (usually .m4a)
      final audioStream = manifest.audioOnly.withHighestBitrate();
      
      return audioStream.url.toString(); // This URL expires in a few hours!
    } catch (e) {
      print("Stream Extraction Error: $e");
      return null;
    }
  }

@override
  Future<Song?> getSongDetails(String id) async { 
    try {
      final video = await _yt.videos.get(id);
      return Song(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        albumArt: video.thumbnails.highResUrl, 
        audioURL: "", 
        duration: video.duration,
        source: SongSource.youtube,
      );
    } catch (e) {
      return null;
    }
  } 

  @override
  Future<Song> normalizeTrack(String input) async { 
    // This allows the user to paste a raw YouTube URL (or ID) and get a Song back!
    final video = await _yt.videos.get(input);
    return Song(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      albumArt: video.thumbnails.highResUrl,
      audioURL: "", 
      duration: video.duration,
      source: SongSource.youtube,
    );
  }

}