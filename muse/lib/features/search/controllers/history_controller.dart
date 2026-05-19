// Re-Zero is peak TwT

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse_local_db/muse_local_db.dart';
import '../../library/controllers/collection_controller.dart'; 
import '../../../models/song.dart';

final historyControllerProvider = StateNotifierProvider<HistoryController, List<Song>>((ref) {
  return HistoryController(ref.read(databaseProvider));
});

class HistoryController extends StateNotifier<List<Song>> {
  final dynamic _db;

  HistoryController(this._db) : super([]) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    debugPrint("HISTORY ENGINE: Fetching recent history from Isar...");
    final entities = await _db.getRecentHistory();
    debugPrint("HISTORY ENGINE: Found ${entities.length} items in history.");
    
    SongSource parseSource(String src) {
      switch (src) {
        case 'soundcloud': return SongSource.soundcloud;
        case 'jamendo': return SongSource.jamendo;
        case 'youtube': return SongSource.youtube;
        case 'audius': return SongSource.audius;
        case 'archive': return SongSource.archive;
        default: return SongSource.local;
      }
    }

    final List<Song> songs = (entities as List<dynamic>).map<Song>((entity) {
      return Song(
        id: entity.networkId ?? entity.id.toString(),
        title: entity.title,
        artist: entity.artist,
        albumArt: entity.albumArtPath,
        audioURL: (entity.streamUrl != null && entity.streamUrl!.isNotEmpty) 
            ? entity.streamUrl! 
            : entity.filePath,
        source: parseSource(entity.source),
      );
    }).toList();

    state = songs;
  }

  Future<void> addSongToHistory(Song networkSong) async {
    debugPrint("HISTORY ENGINE: Logging '${networkSong.title}' to Isar cache...");
    
    final dummyPath = "stream://${networkSong.source.name}/${networkSong.id}";

    final newHistoryTrack = SongEntity()
      ..title = networkSong.title
      ..artist = networkSong.artist
      ..albumArtPath = networkSong.albumArt
      ..filePath = dummyPath 
      ..streamUrl = networkSong.audioURL 
      ..source = networkSong.source.name 
      ..networkId = networkSong.id
      ..isSavedToVault = false 
      ..lastPlayed = DateTime.now();

    await _db.saveSong(newHistoryTrack);
    await loadHistory(); 
  }

  Future<void> removeFromHistory(String path) async {
    debugPrint("HISTORY ENGINE: Optimistically removing item from UI...");
    
    state = state.where((song) {
      final dummyPath = "stream://${song.source.name}/${song.id}";
      return dummyPath != path && song.audioURL != path;
    }).toList();

    await _db.removeFromHistory(path);
  }
}