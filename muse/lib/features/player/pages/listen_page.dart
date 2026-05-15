// import 'package:flutter/material.dart';

// class ListenPage extends StatefulWidget {
//   const ListenPage({super.key});

//   @override
//   State<ListenPage> createState() => _ListenPageState();
// }

// class _ListenPageState extends State<ListenPage> {
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }
// lib/features/player/pages/listen_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/player_controller.dart';
import 'dart:io';

class ListenPage extends ConsumerWidget {
  const ListenPage({super.key});

  // Helper function to format Duration into mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final song = playerState.currentSong;

    // Safety fallback just in case it opens before a song is loaded
    if (song == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("No song playing", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
          onPressed: () => Navigator.pop(context), // Slides the page back down
        ),
        title: const Text("Now Playing", style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. ALBUM ARTWORK (Safely handles empty local artwork)
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05),
                      blurRadius: 40,
                      spreadRadius: 10,
                      offset: const Offset(0, 10),
                    )
                  ],
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
                    ? const Icon(Icons.music_note_rounded, size: 100, color: Colors.white24)
                    : null,
              ),
            ),
            const SizedBox(height: 48),

            // 2. TRACK TITLE & ARTIST
            Text(
              song.title,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              song.artist,
              style: const TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 40),

            // 3. PROGRESS BAR & TIMESTAMPS
            Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    min: 0,
                    // Safety check to prevent division by zero errors on load
                    max: playerState.totalDuration.inSeconds.toDouble() > 0 
                        ? playerState.totalDuration.inSeconds.toDouble() 
                        : 1.0, 
                    value: playerState.currentPosition.inSeconds.toDouble().clamp(
                        0.0, 
                        playerState.totalDuration.inSeconds.toDouble() > 0 ? playerState.totalDuration.inSeconds.toDouble() : 1.0
                    ),
                    onChangeEnd: (value) {
                      // Trigger audio seek when user drops the slider
                      ref.read(playerControllerProvider.notifier).seek(Duration(seconds: value.toInt()));
                    },
                    onChanged: (value) {
                      // Optional: Update local state here if you want the number to change while dragging
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(playerState.currentPosition), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(_formatDuration(playerState.totalDuration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. PLAYBACK CONTROLS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                  onPressed: () => ref.read(playerControllerProvider.notifier).playPreviousSong(),
                ),
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(
                      playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                      color: Colors.black, 
                      size: 40
                    ),
                    onPressed: () => ref.read(playerControllerProvider.notifier).pauseOrResume(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
                  onPressed: () => ref.read(playerControllerProvider.notifier).playNextSong(),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}