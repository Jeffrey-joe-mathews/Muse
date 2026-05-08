abstract class MusicRepository {
  Future<List<Song>> search(String query);

  Future<String> getStreamUrl(String songId);
}