import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muse/features/library/controllers/collection_controller.dart';
import 'package:muse/features/radio_player/controller/radio_controller.dart';
import 'package:muse/features/radio_player/pages/radio_listen_page.dart';
import 'package:muse/features/search/widgets/history_widget.dart';
import 'package:muse/features/search/widgets/radio_widget.dart';
import '../controllers/search_controller.dart';
import '../controllers/history_controller.dart';
import '../../player/controllers/player_controller.dart';
import '../../../models/song.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search SoundCloud, YouTube, etc...",
            hintStyle: const TextStyle(color: Colors.white54),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            suffixIcon: _searchFocusNode.hasFocus || _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                    },
                  )
                : null,
          ),
          onSubmitted: (query) {
            ref.read(searchControllerProvider.notifier).searchMusic(query);
            _searchFocusNode.unfocus(); 
          },
        ),
      ),
      
      // 2. USE THE MODULAR WIDGET HERE
      body: _searchFocusNode.hasFocus 
          ? SearchHistoryWidget(searchFocusNode: _searchFocusNode) 
          : _buildSearchResults(searchState),
    );
  }

  Widget _buildSearchResults(AsyncValue<Map<String, List<Song>>> searchState) {
    return searchState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
      data: (resultsMap) {
        if (resultsMap.isEmpty) {
          return const Column(
            children: [
              SizedBox(height: 20),
              RadioDashboardWidget(), 
            ],
          );
        }

        return ListView.builder(
          itemCount: resultsMap.keys.length,
          itemBuilder: (context, verticalIndex) {
            final providerName = resultsMap.keys.elementAt(verticalIndex);
            final songs = resultsMap[providerName]!;

            return Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      providerName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 190, 
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      itemCount: songs.length,
                      itemBuilder: (context, horizontalIndex) {
                        final song = songs[horizontalIndex];
                        
                        return GestureDetector(
                          onTap: () {
                            // 3. THIS IS THE CRITICAL FIX: Save the ghost record to Isar!
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
                            ref.read(playerControllerProvider.notifier).playQueue(songs, horizontalIndex);
                          }

                            ref.read(playerControllerProvider.notifier).playQueue(songs, horizontalIndex);
                          },
                          onLongPress: () {
                            ref.read(collectionControllerProvider.notifier).addStreamShortcut(song);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Saved ${song.title} to Collection 🔗"),
                                backgroundColor: Colors.teal.shade800,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            width: 130,
                            margin: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 130,
                                  width: 130,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(12),
                                    image: song.albumArt.isNotEmpty
                                        ? DecorationImage(
                                            image: song.albumArt.startsWith("http") ? NetworkImage(song.albumArt) : FileImage(File(song.albumArt)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: song.albumArt.isEmpty
                                      ? const Icon(Icons.music_note, color: Colors.white54, size: 40)
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  song.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  song.artist,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}