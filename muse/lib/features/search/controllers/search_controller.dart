// lib/features/search/controllers/search_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse/models/song.dart';
import '../../../providers/local/local_provider.dart';

final searchControllerProvider =
    StateNotifierProvider<SearchController, AsyncValue<List<Song>>>(
  (ref) => SearchController(),
);

class SearchController extends StateNotifier<AsyncValue<List<Song>>> {
  SearchController() : super(const AsyncValue.data([]));

  final _localProvider = LocalMusicProvider();

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      // Fetch all local songs
      final allSongs = await _localProvider.getLocalSongs();
      
      // Filter locally based on the query (case-insensitive)
      final lowercaseQuery = query.toLowerCase();
      final results = allSongs.where((song) {
        return song.title.toLowerCase().contains(lowercaseQuery) ||
               song.artist.toLowerCase().contains(lowercaseQuery);
      }).toList();

      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}