import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/controllers/player_controller.dart';
import '../../../models/song.dart';
import '../../../core/theme/app_colors.dart';

class FlowPage extends ConsumerStatefulWidget {
  const FlowPage({super.key});

  @override
  ConsumerState<FlowPage> createState() => _FlowPageState();
}

class _FlowPageState extends ConsumerState<FlowPage> with SingleTickerProviderStateMixin {
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    // A slow, 8-second breathing animation for the background aura
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    
    // FIX: Removed the dead null-aware operators.
    final queue = playerState.queue; 
    final currentIndex = playerState.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // --- 1. THE "MIND" BACKGROUND AURA ---
          AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              return Positioned(
                top: -100 + (_breathController.value * 20), // Slowly drifts up and down
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // --- FROSTED GLASS OVER THE AURA ---
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.transparent),
          ),

          // --- 2. THE DASHBOARD ---
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "The Flow",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          queue.isEmpty 
                              ? "Your session is empty." 
                              : "Active Session • ${queue.length} Tracks",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // AI SESSION CONTEXT
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedSurface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Session Insight",
                                  style: TextStyle(
                                    color: AppColors.primary, 
                                    fontSize: 12, 
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "You've been listening to high-BPM Synthwave and Cyberpunk mixes for 45 minutes. Your focus is peaking.",
                                  style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // QUICK TRANSITIONS
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        children: const [
                          _TransitionChip(icon: Icons.water_drop_rounded, label: "Pivot to Lofi"),
                          _TransitionChip(icon: Icons.speed_rounded, label: "Drop the BPM"),
                          _TransitionChip(icon: Icons.nightlight_round, label: "Go Ambient"),
                          _TransitionChip(icon: Icons.mic_rounded, label: "Add Vocals"),
                        ],
                      ),
                    ),
                  ),
                ),

                // THE ACTIVE QUEUE
                if (queue.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        "Tap 'Explore' or 'Collection' to start the flow.",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = queue[index];
                          final isPlaying = index == currentIndex;

                          return _QueueTile(
                            song: song,
                            isPlaying: isPlaying,
                            onTap: () {
                              ref.read(playerControllerProvider.notifier).playQueue(queue, index);
                            },
                            onDismissed: () {
                              ref.read(playerControllerProvider.notifier).removeFromQueue(index);
                            },
                          );
                        },
                        childCount: queue.length,
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

// --- TRANSITION CHIP WIDGET ---
class _TransitionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TransitionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => debugPrint("Trigger AI Pivot: $label"),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- SWIPEABLE QUEUE TILE ---
class _QueueTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _QueueTile({
    required this.song, 
    required this.isPlaying, 
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(song.id),
      direction: isPlaying ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPlaying ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isPlaying ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
          ),
          child: Row(
            children: [
              // ALBUM ART
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
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
                    ? const Icon(Icons.music_note_rounded, color: Colors.white30, size: 20)
                    : null,
              ),
              const SizedBox(width: 16),

              // TRACK INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        color: isPlaying ? AppColors.primary : Colors.white,
                        fontSize: 15,
                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _SourceBadge(source: song.source),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            song.artist,
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // DYNAMIC PLAYING INDICATOR
              if (isPlaying)
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: _AnimatedPlayingIndicator(),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Icon(Icons.more_vert_rounded, color: Colors.white24, size: 20), 
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- TRUE ANIMATED EQUALIZER ---
class _AnimatedPlayingIndicator extends StatefulWidget {
  const _AnimatedPlayingIndicator();

  @override
  State<_AnimatedPlayingIndicator> createState() => _AnimatedPlayingIndicatorState();
}

class _AnimatedPlayingIndicatorState extends State<_AnimatedPlayingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // The offsets shift the sine wave so they don't all bounce together
          _EqBar(animation: _controller, offset: 0.0),
          _EqBar(animation: _controller, offset: 2.0), 
          _EqBar(animation: _controller, offset: 4.0),
          _EqBar(animation: _controller, offset: 1.0),
        ],
      ),
    );
  }
}

// --- INDIVIDUAL EQUALIZER BAR ---
class _EqBar extends StatelessWidget {
  final Animation<double> animation;
  final double offset;

  const _EqBar({required this.animation, required this.offset});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Calculate the sine wave position
        final sineValue = math.sin((animation.value * 2 * math.pi) + offset);
        
        // Map the sine wave from [-1, 1] to a height percentage between 30% and 100%
        final heightPercent = 0.3 + (sineValue.abs() * 0.7);

        return Container(
          width: 3.5,
          height: 22 * heightPercent,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4), // Rounded pill look
          ),
        );
      },
    );
  }
}

// --- DYNAMIC SOURCE BADGE ---
class _SourceBadge extends StatelessWidget {
  final SongSource source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String label;

    switch (source) {
      case SongSource.soundcloud:
        badgeColor = Colors.orange;
        label = "SC";
        break;
      case SongSource.jamendo:
        badgeColor = Colors.purpleAccent;
        label = "JM";
        break;
      case SongSource.local:
        badgeColor = AppColors.primary;
        label = "Local";
        break;
      case SongSource.youtube:
        badgeColor = Colors.red;
        label = "YT";
        break;
      case SongSource.audius:
        badgeColor = Colors.deepPurpleAccent;
        label = "AU";
        break;
      case SongSource.archive:
        badgeColor = Colors.blueGrey;
        label = "ARC";
        break;
      case SongSource.radio:
        badgeColor = Colors.greenAccent;
        label = "LIVE";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}