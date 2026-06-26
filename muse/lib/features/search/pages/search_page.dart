import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muse/features/library/controllers/collection_controller.dart';
import 'package:muse/features/radio_player/controller/radio_controller.dart';
import 'package:muse/features/radio_player/pages/radio_listen_page.dart';
import 'package:muse/features/search/widgets/history_widget.dart';
import '../controllers/search_controller.dart';
import '../controllers/history_controller.dart';
import '../../player/controllers/player_controller.dart';
import '../../../models/song.dart';

// 1. IMPORTING THE GLOBAL PRIMITIVES
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primitives/muse_glass.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  
  // LIVE TELEMETRY STATE
  String? _activeResultFilter;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetSearchState() {
    _searchFocusNode.unfocus();
    _searchController.clear();
    _activeResultFilter = null;
    ref.read(searchControllerProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final resultsMap = searchState.value ?? {};
    
    // STRICT INTENT BOOLEANS
    final isFocused = _searchFocusNode.hasFocus;
    final hasResults = resultsMap.isNotEmpty;
    final isSearchActive = isFocused || hasResults;

    return PopScope(
      canPop: !isSearchActive, 
      onPopInvoked: (didPop) {
        if (didPop) return; 
        _resetSearchState();
      },
      child: Scaffold(
        backgroundColor: AppColors.background, 
        body: SafeArea(
          child: Column(
            children: [
              // 1. THE GLASSMORPHIC SEARCH BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: MuseGlass(
                  borderRadius: 12.0,
                  blurSigma: 15.0,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: AppColors.pureWhite),
                    decoration: InputDecoration(
                      hintText: "Search tracks or genres...",
                      hintStyle: const TextStyle(color: AppColors.glassTextMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      
                      prefixIcon: isSearchActive
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.pureWhite, size: 20),
                              onPressed: _resetSearchState,
                            )
                          : const Icon(Icons.search_rounded, color: AppColors.glassTextMuted, size: 22),
                            
                      suffixIcon: isFocused || _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.glassTextMuted, size: 20),
                              onPressed: _resetSearchState,
                            )
                          : null,
                    ),
                    onSubmitted: (query) {
                      ref.read(searchControllerProvider.notifier).searchMusic(query);
                      _searchFocusNode.unfocus(); 
                      setState(() => _activeResultFilter = null); 
                    },
                  ),
                ),
              ),
              
              // 2. THE STRICT BINARY ROUTER
              Expanded(
                child: _buildBodyContent(hasResults, searchState, resultsMap),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── THE BINARY ROUTER ─────────────────────────────────────────────
  Widget _buildBodyContent(bool hasResults, AsyncValue<Map<String, List<Song>>> searchState, Map<String, List<Song>> resultsMap) {
    if (hasResults || searchState.isLoading) {
      return _buildDataState(searchState, resultsMap);
    } else {
      return SearchHistoryWidget(searchFocusNode: _searchFocusNode);
    }
  }

  // ─── THE DATA STATE (JIT PROGRESSIVE RENDERING) ────────────────────
  Widget _buildDataState(AsyncValue<Map<String, List<Song>>> searchState, Map<String, List<Song>> resultsMap) {
    
    // 1. If we are completely empty and still loading, show the spinner
    if (searchState.isLoading && resultsMap.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.pureWhite));
    }

    // 2. If an error occurred and we have NO data
    if (searchState.hasError && resultsMap.isEmpty) {
      return Center(child: Text("Error: ${searchState.error}", style: const TextStyle(color: Colors.redAccent)));
    }

    // 3. JIT Processing: Flatten the map into a single Omni-List
    final List<Song> displayQueue = [];
    int totalResults = 0;
    
    for (var entry in resultsMap.entries) {
      totalResults += entry.value.length;
      if (_activeResultFilter == null || _activeResultFilter == entry.key) {
        displayQueue.addAll(entry.value);
      }
    }

    // 4. Handle Empty Return State
    if (totalResults == 0 && !searchState.isLoading) {
      return const Center(child: Text("No signals found.", style: TextStyle(color: AppColors.glassTextMuted)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // THE LIVE TELEMETRY FILTER ROW
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildTelemetryPill("ALL", totalResults, _activeResultFilter == null),
              for (var provider in resultsMap.keys)
                _buildTelemetryPill(provider, resultsMap[provider]!.length, _activeResultFilter == provider),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // THE UNIFIED OMNI-LIST
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
            itemCount: displayQueue.length,
            itemBuilder: (context, index) {
              final song = displayQueue[index];
              return _buildListTile(song, displayQueue, index);
            },
          ),
        ),
      ],
    );
  }

  // ─── COMPONENT BUILDERS ──────────────────────────────────────────────
  Widget _buildTelemetryPill(String label, int count, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeResultFilter = (label == "ALL") ? null : label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.pureWhite.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.pureWhite.withOpacity(0.3) : AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isActive ? AppColors.pureWhite : AppColors.glassTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "$count",
              style: TextStyle(
                color: isActive ? AppColors.pureWhite : AppColors.glassTextMuted.withOpacity(0.4),
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(Song song, List<Song> queue, int index) {
    final bool hasArt = song.albumArt.isNotEmpty;
    final imageProvider = hasArt 
        ? (song.albumArt.startsWith('http') ? NetworkImage(song.albumArt) : FileImage(File(song.albumArt))) as ImageProvider
        : null;

    return InkWell(
      onTap: () {
        ref.read(historyControllerProvider.notifier).addSongToHistory(song);
        if (song.source == SongSource.radio) {
          ref.read(radioControllerProvider.notifier).tuneToStation(song);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, 
            useSafeArea: false,
            backgroundColor: Colors.transparent, 
            builder: (context) => const RadioListenPage(),
          );
        } else {
          ref.read(playerControllerProvider.notifier).playQueue(queue, index);
        }
      },
      onLongPress: () {
        ref.read(collectionControllerProvider.notifier).addStreamShortcut(song);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Saved ${song.title} to Vault", style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.hardwareSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppColors.glassBorder)),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 46, height: 46, 
              decoration: BoxDecoration(
                color: AppColors.glassShell, 
                borderRadius: BorderRadius.circular(10),
                image: hasArt ? DecorationImage(image: imageProvider!, fit: BoxFit.cover) : null,
              ),
              child: hasArt ? null : const Icon(Icons.music_note_rounded, size: 20, color: AppColors.glassTextMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, style: const TextStyle(color: AppColors.pureWhite, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(song.artist, style: const TextStyle(color: AppColors.glassTextMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            _SourceBadge(source: song.source),
          ],
        ),
      ),
    );
  }
}

// --- UNIFIED MONOCHROME SOURCE BADGE ---
class _SourceBadge extends StatelessWidget {
  final SongSource source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    String label = source.name.toUpperCase();
    if (source == SongSource.soundcloud) label = "SC";
    if (source == SongSource.youtube) label = "YT";
    if (source == SongSource.jamendo) label = "JM";
    if (source == SongSource.archive) label = "ARC";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.glassShell,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.glassTextMuted,
          fontSize: 9,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}