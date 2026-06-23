import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muse/features/library/controllers/collection_controller.dart';
import 'package:muse/features/search/controllers/history_controller.dart';

class VaultPulseWidget extends ConsumerWidget {
  const VaultPulseWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. GATHER DATA SAFELY
    final collectionState = ref.watch(collectionControllerProvider);
    final historyList = ref.watch(historyControllerProvider);

    // Total tracks calculation
    final totalTracks = collectionState.value?.length ?? 0;

    // V1 "Intelligence": Calculate Top Artist from recent history
    String topArtist = "None";
    if (historyList.isNotEmpty) {
      final artistCounts = <String, int>{};
      for (var song in historyList) {
        artistCounts[song.artist] = (artistCounts[song.artist] ?? 0) + 1;
      }
      final sortedArtists = artistCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topArtist = sortedArtists.first.key;
    }

    // 2. THE RESPONSIVE BUILDER
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the screen is narrower than 340 pixels, we switch to single-column mode
        final isSmallScreen = constraints.maxWidth < 340;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.tealAccent.shade400, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "YOUR UNIVERSE",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),

                    // RESPONSIVE STATS GRID
                    Wrap(
                      spacing: 12, // Horizontal space between cards
                      runSpacing: 12, // Vertical space when wrapping
                      children: [
                        _buildStatCard(
                          label: "Tracks in Vault",
                          value: totalTracks.toString(),
                          icon: Icons.library_music_rounded,
                          isSmallScreen: isSmallScreen,
                        ),
                        _buildStatCard(
                          label: "Top Artist",
                          value: topArtist,
                          icon: Icons.person_rounded,
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  // The internal mini-card builder
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required bool isSmallScreen,
  }) {
    return FractionallySizedBox(
      // On small screens, take 100% width. On normal screens, take exactly half (minus spacing).
      widthFactor: isSmallScreen ? 1.0 : 0.47,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}