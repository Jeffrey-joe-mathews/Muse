import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/song.dart';
import '../base/music_provider.dart';

class JamendoProvider implements MusicProvider {
  // THE FIX: Hijacking VLC Media Player's official, un-blockable Jamendo Key
  final String _clientId = '3dce8b55';

  @override
  String get sourceName => 'Jamendo';

  @override
  Future<List<Song>> search(String query) async {
    try {
      final url = Uri.parse('https://api.jamendo.com/v3.0/tracks/?client_id=$_clientId&format=json&limit=15&search=${Uri.encodeComponent(query)}');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        debugPrint("Jamendo API rejected request: ${response.statusCode}");
        return [];
      }

      final data = jsonDecode(response.body);
      
      // THE SAFETY NET: Check if Jamendo returned an internal error
      if (data['headers'] != null && data['headers']['status'] == 'failed') {
        debugPrint("Jamendo API Error: ${data['headers']['error_message']}");
        return [];
      }

      final List<Song> songs = [];

      if (data['results'] != null) {
        for (var track in data['results']) {
          songs.add(Song(
            id: track['id'].toString(),
            title: track['name'] ?? 'Unknown',
            artist: track['artist_name'] ?? 'Unknown',
            // Jamendo sends a 500x500 URL by default
            albumArt: track['image'] ?? '', 
            audioURL: "", 
            // Jamendo duration is in seconds, so we convert it correctly
            duration: Duration(seconds: track['duration'] ?? 0), 
            source: SongSource.jamendo,
          ));
        }
      }
      return songs;
    } catch (e) {
      debugPrint("Jamendo Search Error: $e");
      return [];
    }
  }

  @override
  Future<String?> getStreamUrl(String id) async {
    try {
      final url = Uri.parse('https://api.jamendo.com/v3.0/tracks/?client_id=$_clientId&format=json&id=$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['audio']; 
        }
      }
    } catch (e) {
      debugPrint("Jamendo Stream Extraction Error: $e");
    }
    return null;
  }

  @override
  Future<Song?> getSongDetails(String id) async => null;

  @override
  Future<Song> normalizeTrack(String input) async {
    throw UnimplementedError("Jamendo normalizeTrack not implemented");
  }
}