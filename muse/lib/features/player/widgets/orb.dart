import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../controllers/player_controller.dart';
import '../pages/listen_page.dart';

class MuseOrb extends ConsumerWidget {
  
  const MuseOrb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final song = playerState.currentSong;

    // Invisible if nothing is playing
    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Slide up the Listen Page
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, 
          useSafeArea: false,
          backgroundColor: Colors.transparent, 
          builder: (context) => const ListenPage(),
        );
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              children: [
                const SizedBox(width: 8),
                
                // ARTWORK (Safely handles missing images)
                // ARTWORK (Safely handles local vs web images)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle, 
                    image: song.albumArt.isNotEmpty 
                        ? DecorationImage(
                            image: song.albumArt.startsWith('http') 
                                ? NetworkImage(song.albumArt) as ImageProvider
                                : FileImage(File(song.albumArt)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: song.albumArt.isEmpty 
                      ? const Icon(Icons.music_note, color: Colors.white54, size: 20)
                      : null,
                ),
                
                const SizedBox(width: 12),
                
                // TRACK INFO
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                
                // PLAY/PAUSE
                IconButton(
                  icon: Icon(playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                  onPressed: () {
                    ref.read(playerControllerProvider.notifier).pauseOrResume();
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}