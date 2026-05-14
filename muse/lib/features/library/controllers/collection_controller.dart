// lib/features/library/controllers/collection_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse_local_db/muse_local_db.dart';

// Provide the database service
final databaseProvider = Provider((ref) => DatabaseService());

// Provide the collection state
final collectionControllerProvider =
    StateNotifierProvider<CollectionController, AsyncValue<List<SongEntity>>>((ref) {
  return CollectionController(ref.read(databaseProvider));
});

class CollectionController extends StateNotifier<AsyncValue<List<SongEntity>>> {
  final DatabaseService _db;

  CollectionController(this._db) : super(const AsyncValue.loading()) {
    loadSongs(); // Load songs as soon as the controller is created
  }

  Future<void> loadSongs() async {
    try {
      final songs = await _db.getAllSongs();
      state = AsyncValue.data(songs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSong(String path, String fileName) async {
    // Strip the file extension (e.g., .mp3) for a cleaner title
    final title = fileName.replaceAll(RegExp(r'\.[^.]*$'), '');

    final newSong = SongEntity()
      ..title = title
      ..filePath = path;

    await _db.saveSong(newSong);
    await loadSongs(); // Refresh the list automatically
  }
}