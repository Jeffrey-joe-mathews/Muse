import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/search_controller.dart';
import '../../player/controllers/player_controller.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search SoundCloud, YouTube, etc...",
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white54),
          ),
          onSubmitted: (query) {
            ref.read(searchControllerProvider.notifier).searchMusic(query);
          },
        ),
      ),
      body: searchState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
        data: (resultsMap) {
          if (resultsMap.isEmpty) {
            return const Center(child: Text("Type a track or artist to begin...", style: TextStyle(color: Colors.white54)));
          }

          // Build a vertical list of Providers
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
                    // Provider Label (e.g., "SoundCloud")
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        providerName,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // THE FIX: Increased height from 180 to 220 so the text won't overflow
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
                              ref.read(playerControllerProvider.notifier).playQueue(songs, horizontalIndex);
                            },
                            child: Container(
                              width: 130, // Width of each card
                              margin: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min, // THE FIX: Prevents overflow panic
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Artwork Square
                                  Container(
                                    height: 130,
                                    width: 130,
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(12),
                                      image: song.albumArt.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(song.albumArt),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: song.albumArt.isEmpty
                                        ? const Icon(Icons.music_note, color: Colors.white54, size: 40)
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  // Title
                                  Text(
                                    song.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // Artist
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
      ),
    );
  }
}