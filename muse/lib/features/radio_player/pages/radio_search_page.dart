import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../controller/radio_controller.dart';
import '../models/radio_presets_provider.dart';
import '../models/tuner_search_provider.dart';

class RadioSearchPage extends ConsumerStatefulWidget {
  const RadioSearchPage({super.key});

  @override
  ConsumerState<RadioSearchPage> createState() => _RadioSearchPageState();
}

class _RadioSearchPageState extends ConsumerState<RadioSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(tunerSearchProvider);
    final radioState = ref.watch(radioControllerProvider);
    final presets = ref.watch(radioPresetsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. BACKGROUND (Subtle noise/texture can go here, using dark glass for now)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey.shade900, Colors.black],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. GLASSMORPHIC SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "Tune frequency...",
                                  hintStyle: TextStyle(color: Colors.white54, letterSpacing: 2),
                                  border: InputBorder.none,
                                  icon: Icon(Icons.sensors_rounded, color: Colors.white54),
                                ),
                                onSubmitted: (query) {
                                  ref.read(tunerSearchProvider.notifier).searchMusic(query);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. SEARCH RESULTS
                Expanded(
                  child: searchState.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
                    error: (err, stack) => Center(child: Text("Static interference: $err", style: const TextStyle(color: Colors.red))),
                    data: (resultsMap) {
                      if (resultsMap.isEmpty) {
                        return const Center(
                          child: Text(
                            "Enter genre to scan",
                            style: TextStyle(color: Colors.white24, letterSpacing: 3, fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      // Assuming radio results are under a specific key, or just grab the first list
                      final stations = resultsMap.values.expand((list) => list).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120), // Padding for the dock
                        itemCount: stations.length,
                        itemBuilder: (context, index) {
                          final station = stations[index];
                          final isPlaying = radioState.currentStation?.id == station.id;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                                image: station.albumArt.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(station.albumArt), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: station.albumArt.isEmpty
                                  ? const Icon(Icons.radio, color: Colors.white54)
                                  : null,
                            ),
                            title: Text(
                              station.title,
                              style: TextStyle(
                                color: isPlaying ? Colors.redAccent : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              station.artist,
                              style: const TextStyle(color: Colors.white54),
                              maxLines: 1,
                            ),
                            trailing: isPlaying && radioState.isPlaying
                                ? const Icon(Icons.graphic_eq_rounded, color: Colors.redAccent)
                                : const Icon(Icons.play_arrow_rounded, color: Colors.white24),
                            onTap: () {
                              // Tap to preview/play the station
                              ref.read(radioControllerProvider.notifier).tuneToStation(station);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 4. THE MECHANICAL PRESET DOCK
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 16, bottom: 32, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        radioState.currentStation != null 
                            ? "HOLD BUTTON TO BURN PRESET" 
                            : "SELECT A STATION TO PREVIEW",
                        style: TextStyle(
                          color: radioState.currentStation != null ? Colors.redAccent : Colors.white54,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          final preset = presets[index];
                          final isActive = radioState.currentStation?.id == preset?.id && preset != null;

                          return _PresetBurnButton(
                            index: index,
                            isFirstButton: index == 0,
                            isActive: isActive,
                            isEmpty: preset == null,
                            onLongPress: () async {
                              if (radioState.currentStation != null) {
                                ref.read(radioPresetsProvider.notifier)
                                    .assignStationToSlot(index, radioState.currentStation!);
                                
                                // THE HARDWARE OVERRIDE
                                bool? hasVibrator = await Vibration.hasVibrator();
                                if (hasVibrator == true) {
                                  bool? hasAmplitudeControl = await Vibration.hasCustomVibrationsSupport();
                                  if (hasAmplitudeControl == true) {
                                    // A sharp, heavy 50-millisecond mechanical clunk (255 is max strength)
                                    Vibration.vibrate(duration: 50, amplitude: 255); 
                                  } else {
                                    // Fallback for older phones
                                    Vibration.vibrate(duration: 50); 
                                  }
                                }
                              }
                            },
                            onTap: () {
                              if (preset != null) {
                                ref.read(radioControllerProvider.notifier).tuneToStation(preset);
                              }
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The Tactile Button Logic
class _PresetBurnButton extends StatefulWidget {
  final int index;
  final bool isFirstButton;
  final bool isActive;
  final bool isEmpty;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _PresetBurnButton({
    required this.index,
    required this.isFirstButton,
    required this.isActive,
    required this.isEmpty,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  State<_PresetBurnButton> createState() => _PresetBurnButtonState();
}

class _PresetBurnButtonState extends State<_PresetBurnButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Walkman Homage: First button is Red. Rest are dark mechanical grey.
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
        width: 48,
        height: 36,
        margin: EdgeInsets.only(top: isDown ? 4.0 : 0.0, bottom: isDown ? 0.0 : 4.0),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black87, width: 1.5),
          boxShadow: isDown
              ? []
              : [const BoxShadow(color: Colors.black87, offset: Offset(0, 4), blurRadius: 0)],
        ),
        child: Center(
          child: Text(
            "${widget.index + 1}",
            style: TextStyle(
              color: widget.isEmpty ? Colors.white24 : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}