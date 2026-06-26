import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:muse/providers/base/music_provider.dart';
import 'package:muse/providers/provider_config.dart';
import '../../../models/song.dart';


final searchControllerProvider =
    StateNotifierProvider<SearchController, AsyncValue<Map<String, List<Song>>>>((ref) {
  final activeProviders = ref.read(activeProviderState);
  return SearchController(activeProviders);
});

class SearchController extends StateNotifier<AsyncValue<Map<String, List<Song>>>> {
  final List<MusicProvider> _providers;
  
  // Enables lazy loading
  int _searchEpoch = 0;

  SearchController(this._providers) : super(const AsyncValue.data({}));
  
  List<String> get avilableSourceNames => _providers.map((p) => p.sourceName).toList();

  Future<void> searchMusic(String query, {Set<String>? activeFilters}) async {
    if (query.trim().isEmpty) return;

    _searchEpoch++;
    final int currentEpoch = _searchEpoch;

    // Start with a clean slate
    state = const AsyncValue.loading();
    Map<String, List<Song>> accumulatedResults = {};

    final providersToSearch = activeFilters != null && activeFilters.isNotEmpty
        ? _providers.where((p) => activeFilters.contains(p.sourceName)).toList()
        : _providers;

    if (providersToSearch.isEmpty) {
      state = const AsyncValue.data({});
      return;
    }

    int completedCount = 0;

    // JIT PROGRESSIVE EXECUTION: Fire all providers independently
    for (final provider in providersToSearch) {
      provider.search(query).then((results) {
        // Abort if the user started a new search before this one finished
        if (_searchEpoch != currentEpoch) return;

        if (results.isNotEmpty) {
          // Immutably append the new results
          accumulatedResults = Map.from(accumulatedResults)..[provider.sourceName] = results;
          
          // INSTANTLY PUSH TO UI
          state = AsyncValue.data(accumulatedResults);
        }
      }).catchError((e) {
        // A single slow/broken provider will silently fail without bringing down the OS
        debugPrint("WH System: Provider ${provider.sourceName} failed: $e");
      }).whenComplete(() {
        if (_searchEpoch != currentEpoch) return;
        
        completedCount++;
        // If ALL providers are done and we still have absolutely nothing, push empty state
        if (completedCount == providersToSearch.length && accumulatedResults.isEmpty) {
          state = const AsyncValue.data({});
        }
      });
    }
  }

  void clearSearch() {
    _searchEpoch++;
    state = const AsyncValue.data({});
  }
}