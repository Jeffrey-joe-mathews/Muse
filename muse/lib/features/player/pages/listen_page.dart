import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import '../controllers/player_controller.dart';

final auraProvider = FutureProvider.family<List<Color>, String>((ref, artPath) async {
  if (artPath.isEmpty) return [Colors.grey.shade900, Colors.black, Colors.grey.shade800];
  
  try {
    final imageProvider = artPath.startsWith('http') 
        ? NetworkImage(artPath) as ImageProvider 
        : FileImage(File(artPath));
        
    final palette = await PaletteGenerator.fromImageProvider(imageProvider);
    
    return [
      palette.dominantColor?.color ?? Colors.grey.shade900,
      palette.vibrantColor?.color ?? palette.mutedColor?.color ?? Colors.black,
      palette.darkVibrantColor?.color ?? Colors.grey.shade800,
    ];
  } catch (e) {
    return [Colors.grey.shade900, Colors.black, Colors.grey.shade800];
  }
});

class ListenPage extends ConsumerWidget {
  const ListenPage({super.key});

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

    if (song == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("No song playing", style: TextStyle(color: Colors.white54))),
      );
    }

    final auraColors = ref.watch(auraProvider(song.albumArt)).value 
        ?? [Colors.grey.shade900, Colors.black, Colors.grey.shade800];

    // Removed Scaffold AppBar completely to fix the Safe Area bug
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. THE LIVING AURA BACKGROUND
          LivingAuraBackground(colors: auraColors),
          
          // 2. THE FROSTED GLASS
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),

          // 3. THE UI (Wrapped in SafeArea to protect from the notch!)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  // CUSTOM TOP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Text(
                        "NOW PLAYING", 
                        style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.w700)
                      ),
                      const SizedBox(width: 36), // Balances the down arrow to keep text perfectly centered
                    ],
                  ),

                  const SizedBox(height: 24), // Fixed gap to pull artwork up

                  // ALBUM ARTWORK
                  Flexible(
                    flex: 12,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
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
                            ? const Icon(Icons.music_note_rounded, size: 80, color: Colors.white24)
                            : null,
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),

                  // TRACK TITLE & ARTIST
                  Text(
                    song.title,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    song.artist,
                    style: const TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(flex: 2),

                  // ERGONOMIC FIX: PLAYBACK CONTROLS MOVED UP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                        onPressed: () => ref.read(playerControllerProvider.notifier).playPreviousSong(),
                      ),
                      Container(
                        width: 75, height: 75,
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            )
                          ]
                        ),
                        child: IconButton(
                          icon: Icon(
                            playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                            color: Colors.black, 
                            size: 38
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

                  const SizedBox(height: 32), // Breathing room between buttons and slider

                  // ERGONOMIC FIX: SLIDER MOVED DOWN
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          min: 0,
                          max: playerState.totalDuration.inSeconds.toDouble() > 0 
                              ? playerState.totalDuration.inSeconds.toDouble() 
                              : 1.0, 
                          value: playerState.currentPosition.inSeconds.toDouble().clamp(
                              0.0, 
                              playerState.totalDuration.inSeconds.toDouble() > 0 ? playerState.totalDuration.inSeconds.toDouble() : 1.0
                          ),
                          onChangeEnd: (value) {
                            ref.read(playerControllerProvider.notifier).seek(Duration(seconds: value.toInt()));
                          },
                          onChanged: (value) {},
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(playerState.currentPosition), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                            Text(_formatDuration(playerState.totalDuration), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(flex: 2), // Extra padding to keep slider above the home-swipe bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LivingAuraBackground extends StatefulWidget {
  final List<Color> colors;
  const LivingAuraBackground({super.key, required this.colors});

  @override
  State<LivingAuraBackground> createState() => _LivingAuraBackgroundState();
}

class _LivingAuraBackgroundState extends State<LivingAuraBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final drift = _controller.value;
        return AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.5 + drift, -0.5 + (drift * 0.5)),
              radius: 1.5,
              colors: [
                widget.colors[0].withValues(alpha: 0.8),
                widget.colors[1].withValues(alpha: 0.5),
                widget.colors[2].withValues(alpha: 0.3),
                Colors.black,
              ],
              stops: const [0.0, 0.4, 0.8, 1.0],
            ),
          ),
        );
      },
    );
  }
}