import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/radio_controller.dart';
import '../models/radio_presets_provider.dart';
import '../models/tuner_search_provider.dart';

// 1. IMPORTING THE GLOBAL PRIMITIVES
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primitives/muse_glass.dart';
import '../../../core/widgets/primitives/muse_tactile_button.dart';

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
      backgroundColor: AppColors.background, // Standardized pitch black baseline
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // 1. GLASSMORPHIC SEARCH BAR (Using MuseGlass)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.glassTextMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: MuseGlass(
                          borderRadius: 12.0,
                          blurSigma: 10.0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: AppColors.pureWhite),
                            decoration: const InputDecoration(
                              hintText: "Tune frequency...",
                              hintStyle: TextStyle(color: AppColors.glassTextMuted, letterSpacing: 2),
                              border: InputBorder.none,
                              icon: Icon(Icons.sensors_rounded, color: AppColors.glassTextMuted),
                            ),
                            onSubmitted: (query) {
                              ref.read(tunerSearchProvider.notifier).searchMusic(query);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. SEARCH RESULTS (Standardized to 46x46 Anchor Boxes)
                Expanded(
                  child: searchState.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.pureWhite)),
                    error: (err, stack) => Center(child: Text("Static interference: $err", style: const TextStyle(color: Colors.red))),
                    data: (resultsMap) {
                      if (resultsMap.isEmpty) {
                        return const Center(
                          child: Text(
                            "Enter genre to scan",
                            style: TextStyle(color: AppColors.glassTextMuted, letterSpacing: 3, fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      final stations = resultsMap.values.expand((list) => list).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120), // Padding for the dock
                        itemCount: stations.length,
                        itemBuilder: (context, index) {
                          final station = stations[index];
                          final isPlaying = radioState.currentStation?.id == station.id;

                          return InkWell(
                            onTap: () {
                              ref.read(radioControllerProvider.notifier).tuneToStation(station);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46, height: 46, // Standardized anchor box
                                    decoration: BoxDecoration(
                                      color: AppColors.glassShell,
                                      borderRadius: BorderRadius.circular(10),
                                      image: station.albumArt.isNotEmpty
                                          ? DecorationImage(image: NetworkImage(station.albumArt), fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: station.albumArt.isEmpty
                                        ? const Icon(Icons.radio, color: AppColors.glassTextMuted, size: 20)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          station.title,
                                          style: TextStyle(
                                            color: AppColors.pureWhite, // Stripped the red accent
                                            fontSize: 14,
                                            fontWeight: isPlaying ? FontWeight.w800 : FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          station.artist,
                                          style: const TextStyle(color: AppColors.glassTextMuted, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPlaying && radioState.isPlaying)
                                    const Icon(Icons.graphic_eq_rounded, color: AppColors.pureWhite, size: 20)
                                  else
                                    const Icon(Icons.play_arrow_rounded, color: AppColors.glassTextMuted, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 3. THE MECHANICAL PRESET DOCK (Using Primitives)
          Align(
            alignment: Alignment.bottomCenter,
            child: MuseGlass(
              borderRadius: 0, // Docks flush to the bottom
              blurSigma: 20.0,
              backgroundColor: Colors.black.withOpacity(0.6), // Deeper contrast for the dock
              padding: const EdgeInsets.only(top: 16, bottom: 32, left: 16, right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    radioState.currentStation != null 
                        ? "HOLD BUTTON TO BURN PRESET" 
                        : "SELECT A STATION TO PREVIEW",
                    style: const TextStyle(
                      color: AppColors.glassTextMuted, // Stripped the red accent
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

                      // Replaced the entire custom class with the Master Widget
                      return MuseTactileButton(
                        width: 48,
                        height: 36,
                        isPrimaryRecord: index == 0,
                        isActive: isActive,
                        onTap: () {
                          if (preset != null) {
                            ref.read(radioControllerProvider.notifier).tuneToStation(preset);
                          }
                        },
                        onLongPress: () {
                          if (radioState.currentStation != null) {
                            ref.read(radioPresetsProvider.notifier)
                                .assignStationToSlot(index, radioState.currentStation!);
                          }
                        },
                        // Absolute Minimalism: Show a faint '+' if empty, otherwise show absolutely nothing.
                        child: preset == null 
                            ? Icon(Icons.add_rounded, color: AppColors.pureWhite.withOpacity(0.1), size: 20)
                            : const SizedBox.shrink(), 
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}