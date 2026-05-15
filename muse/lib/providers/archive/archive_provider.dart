import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/song.dart';
import '../base/music_provider.dart';

class ArchiveProvider implements MusicProvider {
  @override
  String get sourceName => 'Internet Archive';

  @override
  Future<List<Song>> search(String query) async {
    try {
      // Query the massive Archive database for audio items containing MP3s
      final safeQuery = Uri.encodeComponent('$query AND mediatype:audio AND format:(mp3)');
      final url = Uri.parse('https://archive.org/advancedsearch.php?q=$safeQuery&fl[]=identifier,title,creator,length&output=json&rows=15');
      
      final response = await http.get(url);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final List<Song> songs = [];

      for (var doc in data['response']['docs']) {
        // Archive length is often a weird string format (e.g. "03:45" or "225.5")
        // We use a safe fallback of 0 if parsing fails
        int durationSecs = 0;
        if (doc['length'] != null) {
           final lenStr = doc['length'].toString();
           if (lenStr.contains(':')) {
              final parts = lenStr.split(':');
              if (parts.length == 2) durationSecs = int.parse(parts[0]) * 60 + int.parse(parts[1].split('.')[0]);
           } else {
              durationSecs = double.tryParse(lenStr)?.toInt() ?? 0;
           }
        }

        songs.add(Song(
          id: doc['identifier'], // The unique ID for the whole album/recording
          title: doc['title'] ?? 'Unknown Archive',
          artist: doc['creator'] != null ? (doc['creator'] is List ? doc['creator'][0] : doc['creator']) : 'Unknown Artist',
          albumArt: 'https://archive.org/services/img/${doc['identifier']}', // Auto-generates the album cover!
          audioURL: "", 
          duration: Duration(seconds: durationSecs),
          source: SongSource.archive,
        ));
      }
      return songs;
    } catch (e) {
      debugPrint("Archive Search Error: $e");
      return [];
    }
  }

  @override
  Future<String?> getStreamUrl(String identifier) async {
    try {
      // 1. Fetch the exact files inside this archive item
      final url = Uri.parse('https://archive.org/metadata/$identifier/files');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['result'] as List;

        // 2. Look for the first playable MP3 file
        for (var file in files) {
          if (file['name'].toString().toLowerCase().endsWith('.mp3')) {
            // 3. Construct the immortal raw download link
            return 'https://archive.org/download/$identifier/${file['name']}';
          }
        }
      }
    } catch (e) {
      debugPrint("Archive Extraction Error: $e");
    }
    return null;
  }

  @override
  Future<Song?> getSongDetails(String id) async => null;

  @override
  Future<Song> normalizeTrack(String input) async {
    throw UnimplementedError("Archive normalizeTrack not implemented");
  }
}