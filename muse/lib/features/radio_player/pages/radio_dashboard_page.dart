import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

import '../controller/radio_controller.dart';
import '../models/radio_presets_provider.dart';
import 'radio_search_page.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primitives/muse_tactile_button.dart';

final radioAuraProvider = FutureProvider.family<List<Color>, String>((ref, artPath) async {
  if (artPath.isEmpty) return [Colors.grey.shade700, Colors.black, Colors.grey.shade800];
  try {
    final imageProvider = artPath.startsWith('http') 
        ? NetworkImage(artPath) as ImageProvider 
        : FileImage(File(artPath));
    final palette = await PaletteGenerator.fromImageProvider(imageProvider);
    return [
      palette.dominantColor?.color ?? Colors.grey.shade600,
      palette.vibrantColor?.color ?? palette.mutedColor?.color ?? Colors.black,
      palette.darkVibrantColor?.color ?? Colors.grey.shade800,
    ];
  } catch (e) {
    return [Colors.red.shade900, Colors.black, Colors.grey.shade800];
  }
});

class RadioDashboardPage extends ConsumerWidget {
  const RadioDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioState = ref.watch(radioControllerProvider);
    final presets = ref.watch(radioPresetsProvider);
    final station = radioState.currentStation;

    final auraColors = ref.watch(radioAuraProvider(station?.albumArt ?? "")).value
        ?? [Colors.red.shade900, Colors.black, Colors.grey.shade800];

    return Scaffold(
      backgroundColor: AppColors.background, // Standardized pitch black baseline
      body: SafeArea(
        child: Column(
          children: [
            // 1. THE FLOW-STYLE HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Radio",
                        style: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const RadioSearchPage())
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
                          child: Icon(Icons.sensors_rounded, color: AppColors.glassTextMuted, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. THE TACTILE COMMAND DECK (Clean, no numbers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station != null ? "HOLD PRESET TO BURN" : "SELECT PRESET",
                    style: const TextStyle(
                      color: AppColors.glassTextMuted, 
                      fontSize: 10, 
                      letterSpacing: 2, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.0,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final preset = presets[index];
                      final isActive = station?.id == preset?.id && preset != null;

                      // Using your primitive. Vibration logic is natively handled inside the button!
                      return MuseTactileButton(
                        width: double.infinity, // Allows grid to manage sizing
                        height: double.infinity,
                        isPrimaryRecord: index == 0,
                        isActive: isActive,
                        onTap: () {
                          if (preset != null) {
                            ref.read(radioControllerProvider.notifier).tuneToStation(preset);
                          }
                        },
                        onLongPress: () {
                          if (station != null) {
                            ref.read(radioPresetsProvider.notifier).assignStationToSlot(index, station);
                          }
                        },
                        // Elegant state indications without ugly numbers
                        child: preset == null 
                          ? Icon(Icons.add_rounded, color: AppColors.pureWhite.withValues(alpha: 0.1), size: 20)
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 3. THE SPEAKER CONE
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    if (station != null) ...[
                      _BreathingCircleDisplay(
                        albumArt: station.albumArt,
                        isPlaying: radioState.isPlaying,
                        glowColor: auraColors[0],
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          station.title,
                          style: const TextStyle(
                            color: AppColors.pureWhite, 
                            fontSize: 22, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: -0.5
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          station.artist,
                          style: const TextStyle(
                            color: AppColors.glassTextMuted, 
                            fontSize: 14, 
                            fontWeight: FontWeight.w600, 
                            letterSpacing: 1.0
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.radio_rounded, size: 100, color: AppColors.glassShell),
                      const SizedBox(height: 24),
                      const Text(
                        "NO SIGNAL", 
                        style: TextStyle(
                          color: AppColors.glassTextMuted, 
                          fontSize: 18, 
                          letterSpacing: 4.0, 
                          fontWeight: FontWeight.w900
                        )
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingCircleDisplay extends StatefulWidget {
  final String albumArt;
  final bool isPlaying;
  final Color glowColor;

  const _BreathingCircleDisplay({
    required this.albumArt, 
    required this.isPlaying, 
    required this.glowColor
  });

  @override
  State<_BreathingCircleDisplay> createState() => _BreathingCircleDisplayState();
}

class _BreathingCircleDisplayState extends State<_BreathingCircleDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    if (!widget.isPlaying) _controller.stop();
  }

  @override
  void didUpdateWidget(covariant _BreathingCircleDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
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
        final scale = 1.0 + (_controller.value * 0.05);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 240, 
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hardwareBorder, width: 6),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: widget.isPlaying ? 0.6 : 0.2),
                  blurRadius: 40 + (_controller.value * 20), 
                  spreadRadius: 5 + (_controller.value * 10),
                )
              ],
              image: widget.albumArt.isNotEmpty 
                  ? DecorationImage(
                      image: widget.albumArt.startsWith('http') 
                          ? NetworkImage(widget.albumArt) as ImageProvider 
                          : FileImage(File(widget.albumArt)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.albumArt.isEmpty 
                ? const Icon(Icons.radio_rounded, size: 60, color: AppColors.glassTextMuted) 
                : null,
          ),
        );
      },
    );
  }
}