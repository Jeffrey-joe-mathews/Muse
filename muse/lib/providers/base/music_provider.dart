// TwT
import 'package:muse/models/song.dart';

abstract class MusicProvider {
  /// Unique identifier for the source 
  String get sourceName;

  // --- SEARCH & DISCOVERY ---
  Future<List<Song>> search(String query);
  Future<Song?> getSongDetails(String id);

  // --- PLAYBACK ---
  // For remote sources, fetches the actual audio URL. 
  // For local sources, just returns the ID/Path.
  Future<String?> getStreamUrl(String id);

  // --- IMPORT & NORMALIZATION ---
  // Takes a raw input (a file path or a URL) and returns a clean Song model
  Future<Song> normalizeTrack(String input);
}