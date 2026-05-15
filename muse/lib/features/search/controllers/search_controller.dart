import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse/providers/archive/archive_provider.dart';
import 'package:muse/providers/audius/audius_provider.dart';
import 'package:muse/providers/jamendo/jamendo_provider.dart';
import '../../../models/song.dart';
import '../../../providers/base/music_provider.dart';
import '../../../providers/youtube/youtube_provider.dart';
import '../../../providers/soundcloud/soundcloud_provider.dart';

// Provide the instances
final youTubeProviderInstance = Provider((ref) => YouTubeProvider());
final soundCloudProviderInstance = Provider((ref) => SoundCloudProvider());
final jamendoProviderInstance = Provider((ref) => JamendoProvider());
final audiusProviderInstance = Provider((ref) => AudiusProvider());
final archiveProviderInstance = Provider((ref) => ArchiveProvider());

// The State is now a Map connecting the Provider Name to its list of Songs
final searchControllerProvider =
    StateNotifierProvider<SearchController, AsyncValue<Map<String, List<Song>>>>((ref) {
  return SearchController([
    ref.read(soundCloudProviderInstance),
    ref.read(jamendoProviderInstance),
    ref.read(audiusProviderInstance),
    ref.read(archiveProviderInstance),
    ref.read(youTubeProviderInstance),
  ]);
});

class SearchController extends StateNotifier<AsyncValue<Map<String, List<Song>>>> {
  final List<MusicProvider> _providers;

  SearchController(this._providers) : super(const AsyncValue.data({}));

  Future<void> searchMusic(String query) async {
    if (query.trim().isEmpty) return;
    
    state = const AsyncValue.loading();

    try {
      Map<String, List<Song>> combinedResults = {};

      // Fire off all searches to all networks concurrently!
      final searchFutures = _providers.map((provider) async {
        final results = await provider.search(query);
        return MapEntry(provider.sourceName, results);
      });

      // Wait for all of them to finish
      final completedSearches = await Future.wait(searchFutures);

      // Assemble the final map
      for (var result in completedSearches) {
        if (result.value.isNotEmpty) {
          combinedResults[result.key] = result.value;
        }
      }

      state = AsyncValue.data(combinedResults);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}