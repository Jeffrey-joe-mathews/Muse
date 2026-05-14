import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/song.dart';

class LocalMusicProvider {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<bool> requestPermissions() async {
    var status = await Permission.audio.request();
    if (status.isDenied) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<List<Song>> getLocalSongs() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];

    List<SongModel> localSongs = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    return localSongs.map((song) {
      return Song(
        id: song.id.toString(),
        title: song.title,
        artist: song.artist ?? "Unknown Artist",
        albumArt: "",
        audioURL: song.data, // This is the absolute file path
        duration: Duration(milliseconds: song.duration ?? 0),
        source: SongSource.local,
      );
    }).toList();
  }
}