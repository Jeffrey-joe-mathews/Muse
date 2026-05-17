// lib/features/library/controllers/collection_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse_local_db/muse_local_db.dart';
import '../../../models/song.dart'; 
import '../../../providers/local/local_provider.dart'; 

final databaseProvider = Provider((ref) => DatabaseService());

final collectionControllerProvider =
    StateNotifierProvider<CollectionController, AsyncValue<List<Song>>>((ref) {
  return CollectionController(ref.read(databaseProvider));
});

class CollectionController extends StateNotifier<AsyncValue<List<Song>>> {
  final DatabaseService _db;
  
  // 1. Instantiate the provider that handles metadata extraction
  final LocalMusicProvider _localProvider = LocalMusicProvider();

  CollectionController(this._db) : super(const AsyncValue.loading()) {
    loadSongs(); 
  }

  Future<void> loadSongs() async {
    try {
      final entities = await _db.getAllSongs();

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
      
      final songs = entities.map((entity) {
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

      state = AsyncValue.data(songs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }


  Future<void> addSong(String path) async {
    final Song normalizedSong = await _localProvider.normalizeTrack(path);
    
    debugPrint("=== DATABASE X-RAY ===");
    debugPrint("Saving to Isar -> Artist: ${normalizedSong.artist}, ArtPath: ${normalizedSong.albumArt}");

    final newSong = SongEntity()
      ..title = normalizedSong.title
      ..artist = normalizedSong.artist
      ..albumArtPath = normalizedSong.albumArt
      ..filePath = normalizedSong.audioURL
      ..source = 'local';

    await _db.saveSong(newSong);
    await loadSongs(); 
  }

  Future<void> addStreamShortcut(Song networkSong) async {
    // We create a "dummy" path so Isar's unique index is happy, 
    final dummyPath = "stream://${networkSong.source.name}/${networkSong.id}";

    final newShortcut = SongEntity()
      ..title = networkSong.title
      ..artist = networkSong.artist
      ..albumArtPath = networkSong.albumArt
      ..filePath = dummyPath 
      ..streamUrl = networkSong.audioURL 
      ..source = networkSong.source.name 
      ..networkId = networkSong.id;

    await _db.saveSong(newShortcut);
    await loadSongs();
  }
}