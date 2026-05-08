import 'package:muse/models/song.dart';

abstract class MusicProvider {

  // search function
  Future<List<Song>> search(String query);

  // get song metadata
  Future<Song?> getSongDetails(String id);

  // get playable url for streaming
  Future<String?> getStreamUrl(String id);

}