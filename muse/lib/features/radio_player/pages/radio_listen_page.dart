import 'dart:io';
import 'dart:ui';
import 'dart:math' as math; // Needed for the rotation
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muse/features/radio_player/pages/radio_search_page.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:vibration/vibration.dart';

import '../controller/radio_controller.dart';
import '../models/radio_presets_provider.dart';

final radioAuraProvider = FutureProvider.family<List<Color>, String>((ref, artPath) async {
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

class RadioListenPage extends ConsumerStatefulWidget {
  const RadioListenPage({super.key});

  @override
  ConsumerState<RadioListenPage> createState() => _RadioListenPageState();
}

class _RadioListenPageState extends ConsumerState<RadioListenPage> {
  double _hardwareVolume = 0.5;

  @override
  void initState() {
    super.initState();
    _initVolumeControl();
  }

  Future<void> _initVolumeControl() async {
    await FlutterVolumeController.updateShowSystemUI(false);
    
    final initialVolume = await FlutterVolumeController.getVolume();
    if (mounted && initialVolume != null) {
      setState(() => _hardwareVolume = initialVolume);
    }
    
    FlutterVolumeController.addListener((volume) {
      if (mounted) setState(() => _hardwareVolume = volume);
    });
  }

  @override
  void dispose() {
    FlutterVolumeController.updateShowSystemUI(true);
    FlutterVolumeController.removeListener();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final radioState = ref.watch(radioControllerProvider);
  final presets = ref.watch(radioPresetsProvider);
  final station = radioState.currentStation;

  if (station == null) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Text("No radio playing", style: TextStyle(color: Colors.white54))),
    );
  }

  final auraColors = ref.watch(radioAuraProvider(station.albumArt)).value
      ?? [Colors.grey.shade900, Colors.black, Colors.grey.shade800];

  final screenHeight = MediaQuery.of(context).size.height;
  final spacerH = (screenHeight * 0.025).clamp(6.0, 24.0);

  return Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        LivingAuraBackground(colors: auraColors),

        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.black.withValues(alpha: 0.2)),
        ),

        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  // Never shorter than the available safe area
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 18.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                "LIVE BROADCAST",
                                style: TextStyle(color: Colors.redAccent, fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.w900),
                              ),
                              IconButton(
                                icon: const Icon(Icons.search, color: Colors.white, size: 28),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RadioSearchPage()),
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),

                          SizedBox(height: spacerH),

                          // DECK + PRESET BUTTONS
                          // clamp the deck height so it never overflows on tiny screens
                          SizedBox(
                            height: (screenHeight * 0.38).clamp(180.0, 340.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                                // LEFT: 6 Mechanical Preset Buttons
                                SizedBox(
                                  width: 28,
                                  child: Column(
                                    children: List.generate(6, (index) {
                                      final preset = presets[index];
                                      final isActive = radioState.currentStation?.id == preset?.id && preset != null;
                                      return Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(bottom: index == 5 ? 0 : 6.0),
                                          child: _SidePresetButton(
                                            isFirstButton: index == 0,
                                            isActive: isActive,
                                            isEmpty: preset == null,
                                            onTap: () async {
                                              if (preset != null) {
                                                bool? hasVibrator = await Vibration.hasVibrator();
                                                if (hasVibrator == true) {
                                                  Vibration.vibrate(duration: 30, amplitude: 150);
                                                } else {
                                                  HapticFeedback.selectionClick();
                                                }
                                                ref.read(radioControllerProvider.notifier).tuneToStation(preset);
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                                const SizedBox(width: 24),

                                // RIGHT: Spinning vinyl deck
                                Expanded(
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
                                    ),
                                    child: Center(
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: SpinningRecord(
                                          albumArt: station.albumArt,
                                          isPlaying: radioState.isPlaying,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: spacerH),

                          // TRACK TITLE & ARTIST
                          Text(
                            station.title,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            station.artist,
                            style: const TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: spacerH),

                          // PLAY/STOP BUTTON
                          Container(
                            width: 85, height: 85,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                radioState.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 45,
                              ),
                              onPressed: () {
                                if (radioState.isPlaying) {
                                  ref.read(radioControllerProvider.notifier).stopRadio();
                                } else {
                                  ref.read(radioControllerProvider.notifier).tuneToStation(station);
                                }
                              },
                            ),
                          ),

                          SizedBox(height: spacerH),

                          // VOLUME SLIDER
                          Row(
                            children: [
                              const Icon(Icons.volume_down_rounded, color: Colors.white54, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    min: 0.0,
                                    max: 1.0,
                                    value: _hardwareVolume,
                                    onChanged: (val) {
                                      setState(() => _hardwareVolume = val);
                                      FlutterVolumeController.setVolume(val);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.volume_up_rounded, color: Colors.white54, size: 20),
                            ],
                          ),

                          SizedBox(height: spacerH),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

}

// -------------------------------------------------------------
// The Spinning Vinyl Record
// -------------------------------------------------------------
class SpinningRecord extends StatefulWidget {
  final String albumArt;
  final bool isPlaying;
  const SpinningRecord({super.key, required this.albumArt, required this.isPlaying});

  @override
  State<SpinningRecord> createState() => _SpinningRecordState();
}

class _SpinningRecordState extends State<SpinningRecord> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Spins slowly (10 seconds per rotation)
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant SpinningRecord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat();
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
      builder: (_, child) => Transform.rotate(angle: _controller.value * 2 * math.pi, child: child),
      child: Container(
        margin: const EdgeInsets.all(12), // Breathing room inside the rectangle
        decoration: BoxDecoration(
          shape: BoxShape.circle, // Forces the image to clip into a circle!
          border: Border.all(color: Colors.black87, width: 4), // Black vinyl edge
          color: Colors.black54,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
            ? const Icon(Icons.radio_rounded, size: 50, color: Colors.white24)
            : Center(
                // The physical hole in the center of the vinyl
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black87,
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                ),
              ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Side-Mounted Mechanical Button
// -------------------------------------------------------------
class _SidePresetButton extends StatefulWidget {
  final bool isFirstButton;
  final bool isActive;
  final bool isEmpty;
  final VoidCallback onTap;

  const _SidePresetButton({
    required this.isFirstButton,
    required this.isActive,
    required this.isEmpty,
    required this.onTap,
  });

  @override
  State<_SidePresetButton> createState() => _SidePresetButtonState();
}

class _SidePresetButtonState extends State<_SidePresetButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isFirstButton
        ? (widget.isActive ? Colors.red.shade500 : Colors.red.shade900)
        : (widget.isActive ? const Color(0xFF4A4E54) : const Color(0xFF2E3136));

    final isDown = _isPressed || widget.isActive;

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isEmpty) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (!widget.isEmpty) {
          setState(() => _isPressed = false);
          widget.onTap();
        }
      },
      onTapCancel: () {
        if (!widget.isEmpty) setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity, 
        margin: EdgeInsets.only(
          left: isDown ? 4.0 : 0.0,
          right: isDown ? 0.0 : 4.0,
        ),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black87, width: 1.5),
          boxShadow: isDown
              ? []
              : [const BoxShadow(color: Colors.black87, offset: Offset(3, 0), blurRadius: 0)],
        ),
        child: Center(
          child: Container(
            width: 8, height: 2, 
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(2)
            )
          )
        ),
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