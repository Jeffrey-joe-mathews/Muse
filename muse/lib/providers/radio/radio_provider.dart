import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/song.dart';
import '../base/music_provider.dart';

class RadioProvider implements MusicProvider {
  @override
  String get sourceName => 'RadioBrowser';

  // We use one of the round-robin DNS servers for the open database
  final String _baseUrl = 'https://de1.api.radio-browser.info/json/stations/search';

  @override
  Future<List<Song>> search(String query) async {
    // For radio, the "query" will actually be our genre/tag (e.g., "jazz", "lofi")
    try {
      final uri = Uri.parse(
          '$_baseUrl?tag=$query&limit=5&order=clickcount&reverse=true&hidebroken=true');
          
      final response = await http.get(uri, headers: {
        'User-Agent': 'MuseApp/1.0', // Good etiquette for FOSS APIs
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        return data.map((station) {
          return Song(
            id: station['stationuuid'],
            title: station['name'].toString().trim(),
            artist: "Live FM • ${station['tags'].toString().split(',').first}", // Grab primary genre
            albumArt: station['favicon'] ?? '',
            audioURL: station['url_resolved'], // The actual live stream URL!
            source: SongSource.radio,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print("Radio Provider Error: $e");
      return [];
    }
  }

  @override
  Future<String?> getStreamUrl(String id) async {
   return null; 
  }
  
  @override
  Future<Song?> getSongDetails(String id) {
    // TODO: implement getSongDetails
    throw UnimplementedError();
  }
  
  @override
  Future<Song> normalizeTrack(String input) {
    // TODO: implement normalizeTrack
    throw UnimplementedError();
  }
}