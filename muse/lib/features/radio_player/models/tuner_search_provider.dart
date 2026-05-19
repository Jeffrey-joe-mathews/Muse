import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse/features/search/controllers/search_controller.dart';
import 'package:muse/providers/radio/radio_provider.dart';

// THE FIX: A dedicated search state that ONLY uses the RadioProvider
final tunerSearchProvider = StateNotifierProvider<SearchController, AsyncValue<Map<String, dynamic>>>((ref) {
  return SearchController([RadioProvider()]);
});