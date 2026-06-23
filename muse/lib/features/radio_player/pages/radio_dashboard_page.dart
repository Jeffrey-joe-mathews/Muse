import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'package:palette_generator/palette_generator.dart';

import '../controller/radio_controller.dart';
import '../models/radio_presets_provider.dart';
import 'radio_search_page.dart';

final radioAuraProvider = FutureProvider.family<List<Color>, String>((ref, artPath) async {
  if (artPath.isEmpty) return [Colors.red.shade900, Colors.black, Colors.grey.shade800];
  try {
    final imageProvider = artPath.startsWith('http') 
        ? NetworkImage(artPath) as ImageProvider 
        : FileImage(File(artPath));
    final palette = await PaletteGenerator.fromImageProvider(imageProvider);
    return [
      palette.dominantColor?.color ?? Colors.red.shade900,
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. BACKGROUND AURA
          _LivingAuraBackground(colors: auraColors),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. TOP COMMAND BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "LIVE DECK MK-I",
                        style: TextStyle(
                          color: Colors.white54, 
                          fontSize: 12, 
                          letterSpacing: 3.0, 
                          fontWeight: FontWeight.w900
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const RadioSearchPage())
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.sensors_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                "TUNE", 
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12, 
                                  letterSpacing: 1.5
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. THE 3x2 WALKMAN COMMAND DECK
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        station != null ? "HOLD PRESET TO BURN" : "SELECT PRESET",
                        style: TextStyle(
                          color: station != null ? Colors.redAccent : Colors.white38, 
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

                          return _HardwarePresetButton(
                            index: index,
                            isFirstButton: index == 0,
                            isActive: isActive,
                            isEmpty: preset == null,
                            onTap: () async {
                              if (preset != null) {
                                (await Vibration.hasVibrator() == true) 
                                    ? Vibration.vibrate(duration: 30) 
                                    : HapticFeedback.selectionClick();
                                ref.read(radioControllerProvider.notifier).tuneToStation(preset);
                              }
                            },
                            onLongPress: () async {
                              if (station != null) {
                                ref.read(radioPresetsProvider.notifier).assignStationToSlot(index, station);
                                if (await Vibration.hasVibrator() == true) {
                                  (await Vibration.hasCustomVibrationsSupport() == true) 
                                      ? Vibration.vibrate(duration: 50, amplitude: 255) 
                                      : Vibration.vibrate(duration: 50);
                                }
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

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
                                color: Colors.white, 
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
                                color: Colors.white54, 
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
                          const Icon(Icons.radio_rounded, size: 100, color: Colors.white10),
                          const SizedBox(height: 24),
                          const Text(
                            "NO SIGNAL", 
                            style: TextStyle(
                              color: Colors.white38, 
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
        ],
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
        // Breathes seamlessly between scale 1.0 and 1.05
        final scale = 1.0 + (_controller.value * 0.05);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 240, 
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 6),
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
                ? const Icon(Icons.radio_rounded, size: 60, color: Colors.white24) 
                : null,
          ),
        );
      },
    );
  }
}

class _HardwarePresetButton extends StatefulWidget {
  final int index;
  final bool isFirstButton;
  final bool isActive;
  final bool isEmpty;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _HardwarePresetButton({
    required this.index, 
    required this.isFirstButton, 
    required this.isActive, 
    required this.isEmpty, 
    required this.onTap, 
    required this.onLongPress
  });

  @override
  State<_HardwarePresetButton> createState() => _HardwarePresetButtonState();
}

class _HardwarePresetButtonState extends State<_HardwarePresetButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Red for the first Walkman button, tactical dark grey for the rest
    final baseColor = widget.isFirstButton
        ? (widget.isActive ? Colors.red.shade500 : Colors.red.shade900)
        : (widget.isActive ? const Color(0xFF4A4E54) : const Color(0xFF2E3136));

    final isDown = _isPressed || widget.isActive;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) { 
        setState(() => _isPressed = false); 
        widget.onTap(); 
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: () { 
        setState(() => _isPressed = false); 
        widget.onLongPress(); 
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: isDown ? 4.0 : 0.0, bottom: isDown ? 0.0 : 4.0),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black87, width: 2),
          boxShadow: isDown ? [] : [const BoxShadow(color: Colors.black87, offset: Offset(0, 4))],
        ),
        child: Center(
          child: Text(
            "${widget.index + 1}",
            style: TextStyle(
              color: widget.isEmpty ? Colors.white24 : Colors.white70, 
              fontSize: 18, 
              fontWeight: FontWeight.w900
            ),
          ),
        ),
      ),
    );
  }
}


class _LivingAuraBackground extends StatefulWidget {
  final List<Color> colors;
  const _LivingAuraBackground({required this.colors});

  @override
  State<_LivingAuraBackground> createState() => _LivingAuraBackgroundState();
}

class _LivingAuraBackgroundState extends State<_LivingAuraBackground> with SingleTickerProviderStateMixin {
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
        return AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.5 + _controller.value, -0.5 + (_controller.value * 0.5)),
              radius: 1.5,
              colors: [
                widget.colors[0].withValues(alpha: 0.8), 
                widget.colors[1].withValues(alpha: 0.5), 
                widget.colors[2].withValues(alpha: 0.3), 
                Colors.black
              ],
              stops: const [0.0, 0.4, 0.8, 1.0],
            ),
          ),
        );
      },
    );
  }
}