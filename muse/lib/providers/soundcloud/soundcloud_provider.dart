import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/song.dart';
import '../base/music_provider.dart';

class SoundCloudProvider implements MusicProvider {
  String? _clientId;

  @override
  String get sourceName => 'SoundCloud';

  // --- THE RAW SCRAPER ---
  // Rips the internal API key directly from SoundCloud's frontend JavaScript
  Future<String> _getClientId() async {
    if (_clientId != null) return _clientId!;

    try {
      debugPrint("Fetching SC Homepage...");
      final response = await http.get(Uri.parse('https://soundcloud.com'));
      
      // Regex to find all JS bundles
      final bundleRegex = RegExp(r'src="(https://a-v2\.sndcdn\.com/assets/[^"]+\.js)"');
      final matches = bundleRegex.allMatches(response.body).toList();

      // Search the bundles (newest first) for the 32-character Client ID
      for (final match in matches.reversed) {
        final jsUrl = match.group(1)!;
        final jsResponse = await http.get(Uri.parse(jsUrl));
        final clientIdMatch = RegExp(r'client_id\s*:\s*"([a-zA-Z0-9]{32})"').firstMatch(jsResponse.body);
        
        if (clientIdMatch != null) {
          _clientId = clientIdMatch.group(1);
          debugPrint("SUCCESS: Intercepted SC Client ID: $_clientId");
          return _clientId!;
        }
      }
    } catch (e) {
      debugPrint("Failed to scrape Client ID: $e");
    }
    throw Exception("Could not extract SoundCloud Client ID");
  }

  @override
  Future<List<Song>> search(String query) async {
    try {
      final clientId = await _getClientId();
      
      // Hit the undocumented V2 API directly
      final url = Uri.parse('https://api-v2.soundcloud.com/search/tracks?q=${Uri.encodeComponent(query)}&client_id=$clientId&limit=15');
      final response = await http.get(url);
      
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final List<Song> songs = [];

      for (var track in data['collection']) {
        // Skip geo-blocked or Premium-only tracks
        if (track['policy'] == 'BLOCK') continue;

        String rawArtUrl = track['artwork_url'] ?? track['user']['avatar_url'] ?? '';
        String hdArtwork = rawArtUrl.replaceAll('large', 't500x500');

        songs.add(Song(
          id: track['id'].toString(),
          title: track['title'] ?? 'Unknown',
          artist: track['user']['username'] ?? 'Unknown',
          albumArt: hdArtwork,
          audioURL: "", // Extracted strictly on play
          duration: Duration(milliseconds: track['duration'] ?? 0),
          source: SongSource.soundcloud,
        ));
      }
      return songs;
    } catch (e) {
      debugPrint("Raw SC Search Error: $e");
      return [];
    }
  }

  @override
  Future<String?> getStreamUrl(String id) async {
    try {
      final clientId = await _getClientId();
      
      final trackUrl = Uri.parse('https://api-v2.soundcloud.com/tracks/$id?client_id=$clientId');
      final trackRes = await http.get(trackUrl);
      if (trackRes.statusCode != 200) return null;

      final trackData = jsonDecode(trackRes.body);
      final transcodings = trackData['media']['transcodings'] as List;
      if (transcodings.isEmpty) return null;

      // Prefer progressive mp3 (direct file), fallback to hls (playlist)
      var bestTranscoding = transcodings.firstWhere(
        (t) => t['format']['protocol'] == 'progressive', 
        orElse: () => transcodings.first
      );

      // Step 2: Hit the transcoding endpoint to get the final raw audio URL
      final streamReqUrl = bestTranscoding['url'] + '?client_id=$clientId';
      final streamRes = await http.get(Uri.parse(streamReqUrl));
      
      if (streamRes.statusCode == 200) {
         final streamData = jsonDecode(streamRes.body);
         return streamData['url']; // This is the raw .mp3 or .m3u8 URL!
      }
    } catch (e) {
      debugPrint("Raw SC Extraction Error: $e");
    }
    return null;
  }

  @override
  Future<Song?> getSongDetails(String id) async => null;

  @override
  Future<Song> normalizeTrack(String input) async {
    throw UnimplementedError();
  }
}