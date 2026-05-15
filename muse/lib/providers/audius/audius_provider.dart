import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/song.dart';
import '../base/music_provider.dart';

class AudiusProvider implements MusicProvider {
  final String _appName = 'muse_os'; 
  String? _activeHost;

  @override
  String get sourceName => 'Audius';

  // Find the fastest decentralized node
  Future<String> _getHost() async {
    if (_activeHost != null) return _activeHost!;
    try {
      final res = await http.get(Uri.parse('https://api.audius.co'));
      final data = jsonDecode(res.body);
      _activeHost = data['data'][0]; // Grab the top recommended node
      return _activeHost!;
    } catch (e) {
      return 'https://discoveryprovider.audius.co';
    }
  }

  @override
  Future<List<Song>> search(String query) async {
    try {
      final host = await _getHost();
      final url = Uri.parse('$host/v1/tracks/search?query=${Uri.encodeComponent(query)}&app_name=$_appName');
      final response = await http.get(url);

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final List<Song> songs = [];

      for (var track in data['data']) {
        // Only grab tracks that are actually streamable
        if (track['is_streamable'] == true) {
          songs.add(Song(
            id: track['id'].toString(),
            title: track['title'] ?? 'Unknown',
            artist: track['user']['name'] ?? 'Unknown',
            albumArt: track['artwork']?['480x480'] ?? '',
            audioURL: "", // Extracted on play
            duration: Duration(seconds: track['duration'] ?? 0),
            source: SongSource.audius,
          ));
        }
      }
      return songs;
    } catch (e) {
      debugPrint("Audius Search Error: $e");
      return [];
    }
  }

  @override
  Future<String?> getStreamUrl(String id) async {
    try {
      final host = await _getHost();
      return '$host/v1/tracks/$id/stream?app_name=$_appName';
    } catch (e) {
      debugPrint("Audius Extraction Error: $e");
      return null;
    }
  }

  @override
  Future<Song?> getSongDetails(String id) async => null;

  @override
  Future<Song> normalizeTrack(String input) async {
    throw UnimplementedError("Audius normalizeTrack not implemented");
  }
}