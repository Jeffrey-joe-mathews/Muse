// lib/providers/local/local_provider.dart
import 'package:muse_local_db/muse_local_db.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/song.dart';
import '../base/music_provider.dart';

import '../../core/services/metadata_service.dart';

class LocalMusicProvider implements MusicProvider {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final MetadataService _metadataService = MetadataService();
  final DatabaseService _db = DatabaseService();

  @override
  String get sourceName => 'local';

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
        audioURL: song.data, 
        duration: Duration(milliseconds: song.duration ?? 0),
        source: SongSource.local,
      );
    }).toList();
  }

  @override
  Future<List<Song>> search(String query) async {
    final cleanString = query.trim(); 
    if (cleanString.isEmpty) return [];

    final searchResults = await _db.searchLocalSongs(cleanString);

    return searchResults.map((entity) {
      return Song(
        id: entity.networkId ?? entity.id.toString(),
        title: entity.title,
        artist: entity.artist,
        albumArt: entity.albumArtPath, 
        audioURL: entity.filePath,
        source: SongSource.local,
      );
    }).toList();
  }

  @override
  Future<Song?> getSongDetails(String id) async {
    // For local files, normalizing it again gets the details
    return await normalizeTrack(id); 
  }

  @override
  Future<String?> getStreamUrl(String id) async {
    // For local files, the ID/path IS the playable URL
    return id; 
  }

  @override
  Future<Song> normalizeTrack(String input) async {
    // 'input' is the raw file path from the file picker
    // We use the MetadataService to crack open the MP3 and grab the cover art
    final meta = await _metadataService.extractLocalMetadata(input);

    return Song(
      id: input.hashCode.toString(), 
      title: meta['title'],
      artist: meta['artist'],
      albumArt: meta['albumArt'], // Clean String path to the cached JPEG!
      audioURL: input,
      duration: meta['duration'],
      source: SongSource.local,
    );
  }
}