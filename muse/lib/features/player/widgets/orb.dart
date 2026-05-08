import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/player_controller.dart';

class MuseOrb extends ConsumerStatefulWidget {
  const MuseOrb({super.key});

  @override
  ConsumerState<MuseOrb> createState() =>
      _MuseOrbState();
}

class _MuseOrbState
    extends ConsumerState<MuseOrb>
    with SingleTickerProviderStateMixin {

  bool expanded = false;

  late AnimationController glowController;

  @override
  void initState() {
    super.initState();

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final playerState =
        ref.watch(playerControllerProvider);

    final currentSong =
        playerState.currentSong;

    if (currentSong == null) {
      return const SizedBox();
    }

    return GestureDetector(

      /// TAP → OPEN PLAYER PAGE
      onTap: () {

        HapticFeedback.lightImpact();

        // TODO:
        // open full player page
      },

      /// SWIPE UP → NEXT SONG
      onVerticalDragEnd: (details) {

        final velocity =
            details.primaryVelocity ?? 0;

        if (velocity < 0) {

          ref
              .read(
                playerControllerProvider.notifier,
              )
              .playNextSong();

        } else {

          ref
              .read(
                playerControllerProvider.notifier,
              )
              .playPreviousSong();
        }

        HapticFeedback.mediumImpact();
      },

      /// LONG PRESS → EXPAND
      onLongPress: () {

        setState(() {
          expanded = !expanded;
        });

        HapticFeedback.heavyImpact();
      },

      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 350,
        ),

        width: expanded ? 260 : 78,

        height: expanded ? 240 : 78,

        decoration: BoxDecoration(

          shape: expanded
              ? BoxShape.rectangle
              : BoxShape.circle,

          borderRadius:
              expanded
                  ? BorderRadius.circular(28)
                  : null,

          image: DecorationImage(
            image: NetworkImage(
              currentSong.albumArt,
            ),

            fit: BoxFit.cover,

            opacity: expanded ? 0.25 : 1,
          ),

          boxShadow: [

            BoxShadow(
              color: Colors.white.withOpacity(
                glowController.value * 0.25,
              ),

              blurRadius:
                  30 + glowController.value * 20,

              spreadRadius:
                  1 + glowController.value * 2,
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(28),

          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 15,
              sigmaY: 15,
            ),

            child: expanded
                ? _buildExpandedContent(
                    currentSong.title,
                    currentSong.artist,
                  )
                : const SizedBox(),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
    String title,
    String artist,
  ) {

    return Padding(
      padding: const EdgeInsets.all(18),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Spacer(),

          Text(
            title,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            artist,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          const Spacer(),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,

            children: [

              IconButton(
                onPressed: () {

                  ref
                      .read(
                        playerControllerProvider
                            .notifier,
                      )
                      .playPreviousSong();
                },

                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              IconButton(
                onPressed: () {

                  ref
                      .read(
                        playerControllerProvider
                            .notifier,
                      )
                      .pauseOrResume();
                },

                icon: const Icon(
                  Icons.pause_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),

              IconButton(
                onPressed: () {

                  ref
                      .read(
                        playerControllerProvider
                            .notifier,
                      )
                      .playNextSong();
                },

                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}