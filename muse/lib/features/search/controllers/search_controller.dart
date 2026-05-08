import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse/models/song.dart';
import '../../../providers/youtube/youtube_provider.dart';

final searchControllerProvider =
    StateNotifierProvider<SearchController, AsyncValue<List<Song>>>(
  (ref) => SearchController(),
);

class SearchController extends StateNotifier<AsyncValue<List<Song>>> {
  SearchController() : super(const AsyncValue.data([]));

  final _youtubeProvider = YouTubeMusicProvider();

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    state = const AsyncValue.loading();

    try {
      final results = await _youtubeProvider.search(query);

      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}