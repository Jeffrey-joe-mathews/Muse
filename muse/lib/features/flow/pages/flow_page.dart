import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/controllers/player_controller.dart';
import '../../../models/song.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primitives/muse_glass.dart'; 

class FlowPage extends ConsumerStatefulWidget {
  const FlowPage({super.key});

  @override
  ConsumerState<FlowPage> createState() => _FlowPageState();
}

class _FlowPageState extends ConsumerState<FlowPage> {

  String _calculateQueueRuntime(List<Song> queue) {
    Duration total = Duration.zero;
    for (final song in queue) {
      if (song.duration != null) {
        total += song.duration!;
      }
    }
    if (total == Duration.zero) return "Runtime Unknown";

    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60);
    
    return hours > 0 ? "$hours hr $minutes min" : "$minutes min";
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final queue = playerState.queue; 
    final currentIndex = playerState.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background, // Standardized Baseline
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "The Flow",
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                    ),
                    Text(
                      "v1.0 // SESSION",
                      style: TextStyle(
                        color: AppColors.glassTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (queue.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: MuseGlass(
                    borderRadius: 12.0,
                    blurSigma: 20.0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.layers_rounded, size: 14, color: AppColors.glassTextMuted),
                            const SizedBox(width: 8),
                            Text(
                              "${queue.length} TRACKS",
                              style: TextStyle(
                                color: AppColors.glassTextMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _calculateQueueRuntime(queue),
                          style: TextStyle(
                            color: AppColors.glassTextMuted,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            if (queue.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.queue_music_rounded, size: 48, color: AppColors.glassTextMuted),
                      const SizedBox(height: 16),
                      Text(
                        "No tracks loaded into playback.",
                        style: TextStyle(color: AppColors.glassTextMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                // sliver: SliverList(
                //   delegate: SliverChildBuilderDelegate(
                //     (context, index) {
                //       final song = queue[index];
                //       final isPlaying = index == currentIndex;

                //       return _QueueTile(
                //         song: song,
                //         isPlaying: isPlaying,
                //         onTap: () {
                //           ref.read(playerControllerProvider.notifier).playQueue(queue, index);
                //         },
                //         onDismissed: () {
                //           ref.read(playerControllerProvider.notifier).removeFromQueue(index);
                //         },
                //       );
                //     },
                //     childCount: queue.length,
                //   ),
                // ),

                sliver: SliverReorderableList(
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    final isPlaying = index == currentIndex;

                    return _QueueTile(
                      key: ValueKey(song.id),
                      index: index,
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
                  onReorder: (oldIndex, newIndex) {
                    ref.read(playerControllerProvider.notifier).reorderQueue(oldIndex, newIndex);
                  },
                ),

              ),
          ],
        ),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final int index;
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _QueueTile({
    super.key,
    required this.index,
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
          color: AppColors.glassShell, // Standardized
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.pureWhite),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPlaying ? AppColors.glassShell : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isPlaying ? Border.all(color: AppColors.glassBorder) : null,
          ),
          child: Row(
            children: [
              // ALBUM ART
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.glassShell,
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
                    ? Icon(Icons.music_note_rounded, color: AppColors.glassTextMuted, size: 20)
                    : null,
              ),
              const SizedBox(width: 14),

              // TRACK INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 14,
                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _SourceBadge(source: song.source),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            song.artist,
                            style: TextStyle(color: AppColors.glassTextMuted, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (isPlaying)
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: _AnimatedPlayingIndicator(),
                )
              else
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    // padding: EdgeInsetsGeometry.fromLTRB(16, 8, 8, 8), 
                    padding: EdgeInsetsGeometry.only(left: 16),
                    child: Icon(
                      Icons.drag_handle_rounded, 
                      color: AppColors.glassTextMuted, 
                      size: 24,),))
            ],
          ),
        ),
      ),
    );
  }
}

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
      duration: const Duration(milliseconds: 3500),
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
      width: 16,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _EqBar(animation: _controller, offset: 0.0),
          _EqBar(animation: _controller, offset: 2.0), 
          _EqBar(animation: _controller, offset: 4.0),
          _EqBar(animation: _controller, offset: 1.0),
        ],
      ),
    );
  }
}

class _EqBar extends StatelessWidget {
  final Animation<double> animation;
  final double offset;

  const _EqBar({required this.animation, required this.offset});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final sineValue = math.sin((animation.value * 2 * math.pi) + offset);
        final heightPercent = 0.3 + (sineValue.abs() * 0.7);

        return Container(
          width: 2.5,
          height: 16 * heightPercent,
          decoration: BoxDecoration(
            color: AppColors.pureWhite, // Standardized
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final SongSource source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    String label = source.name.toUpperCase();
    if (source == SongSource.soundcloud) label = "SC";
    if (source == SongSource.youtube) label = "YT";
    if (source == SongSource.jamendo) label = "JM";
    if (source == SongSource.archive) label = "ARC";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.glassShell,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.glassTextMuted,
          fontSize: 8,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}