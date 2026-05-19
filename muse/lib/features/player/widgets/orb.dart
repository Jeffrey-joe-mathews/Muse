import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import 'package:muse/features/player/controllers/player_controller.dart';
import 'package:muse/features/player/pages/listen_page.dart';
import 'package:muse/features/radio_player/controller/radio_controller.dart';
import 'package:muse/features/radio_player/pages/radio_listen_page.dart';

class MuseOrb extends ConsumerWidget {
  const MuseOrb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final radioState = ref.watch(radioControllerProvider);

    final standardSong = playerState.currentSong;
    final radioStation = radioState.currentStation;

    // THE FIX: Smart Session Routing
    // Radio owns the Orb IF it is actively playing, OR if a station is loaded and no standard song exists.
    final isRadioActive = radioState.isPlaying || (radioStation != null && standardSong == null);
    final isStandardActive = !isRadioActive && standardSong != null;

    if (!isStandardActive && !isRadioActive) return const SizedBox.shrink();

    // Safely route the variables based on who owns the session
    final activeTitle = isRadioActive ? radioStation!.title : standardSong!.title;
    final activeArtist = isRadioActive ? radioStation!.artist : standardSong!.artist;
    final activeArt = isRadioActive ? radioStation!.albumArt : standardSong!.albumArt;
    final isPlaying = isRadioActive ? radioState.isPlaying : playerState.isPlaying;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, 
          useSafeArea: false,
          backgroundColor: Colors.transparent, 
          builder: (context) => isStandardActive ? const ListenPage() : const RadioListenPage(),
        );
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Row(
              children: [
                const SizedBox(width: 8),
                
                // ARTWORK
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle, 
                    image: activeArt.isNotEmpty 
                        ? DecorationImage(
                            image: activeArt.startsWith('http') 
                                ? NetworkImage(activeArt) as ImageProvider
                                : FileImage(File(activeArt)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: activeArt.isEmpty 
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(activeTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          // LIVE badge strictly follows the smart routing boolean
                          if (isRadioActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Text("LIVE", style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                            )
                          ]
                        ],
                      ),
                      Text(activeArtist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                
                // PLAY/PAUSE
                IconButton(
                  icon: Icon(
                    isPlaying ? (isRadioActive ? Icons.stop_rounded : Icons.pause_rounded) : Icons.play_arrow_rounded, 
                    color: Colors.white
                  ),
                  onPressed: () {
                    if (isStandardActive) {
                      ref.read(playerControllerProvider.notifier).pauseOrResume();
                    } else {
                      if (isPlaying) {
                        ref.read(radioControllerProvider.notifier).stopRadio();
                      } else {
                        ref.read(radioControllerProvider.notifier).tuneToStation(radioStation!);
                      }
                    }
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