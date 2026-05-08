import 'package:muse/models/song.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../base/music_provider.dart';

class YouTubeMusicProvider extends MusicProvider {

  final YoutubeExplode yt = YoutubeExplode();

  @override
  Future<List<Song>> search(String query) async {

    final results = await yt.search.search(query);

    return results.map((video) {

      return Song(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        albumArt: video.thumbnails.highResUrl,
        audioURL: '',
        duration: video.duration,
        source: SongSource.youtube,
      );

    }).toList();
  }

  @override
  Future<Song?> getSongDetails(String id) async {

    final video = await yt.videos.get(id);

    return Song(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      albumArt: video.thumbnails.highResUrl,
      audioURL: '',
      duration: video.duration,
      source: SongSource.youtube,
    );
  }

  @override
  Future<String?> getStreamUrl(String id) async {

    final manifest =
        await yt.videos.streamsClient.getManifest(id);

    final audioStream =
        manifest.audio.withHighestBitrate();

    return audioStream.url.toString();
  }
}