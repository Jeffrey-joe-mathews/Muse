import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muse/features/radio_player/controller/radio_controller.dart';
import 'package:muse/features/radio_player/models/radio_presets_provider.dart';
import 'package:muse/features/radio_player/pages/radio_listen_page.dart';

class RadioDashboardWidget extends ConsumerWidget {
  const RadioDashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioState = ref.watch(radioControllerProvider);
    final presets = ref.watch(radioPresetsProvider);
    
    final currentRadio = radioState.currentStation;
    final isPlayingRadio = radioState.isPlaying;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, 
          useSafeArea: false,
          backgroundColor: Colors.transparent, 
          builder: (context) => const RadioListenPage(),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08), // Frosted glass shell
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. BRANDING & STATUS LED
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "MUSE // RADIO DECK MK-I", 
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)
                      ),
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: isPlayingRadio ? Colors.redAccent : Colors.red.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: isPlayingRadio ? [BoxShadow(color: Colors.redAccent, blurRadius: 6, spreadRadius: 1)] : [],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 2. THE TAPE WINDOW Recess
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4), 
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black87, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.white.withValues(alpha: 0.05), offset: const Offset(0, 1)), 
                      ]
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTapeReel(),
                              
                              // The paper sticker label
                              Container(
                                width: 140,
                                height: 50,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDED9C4), 
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.black87, width: 1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch, 
                                  children: [
                                    Text(
                                      "TYPE I / NORMAL BIAS",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 7, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    // BINDING THE SAFE SCROLL MARQUEE
                                    _MarqueeText(
                                      text: (currentRadio?.title ?? "A MIXTAPE").toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.black87, 
                                        fontFamily: 'monospace', 
                                        fontSize: 12, 
                                        fontWeight: FontWeight.w900
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              _buildTapeReel(),
                            ],
                          ),
                        ),
                        
                        // Glass Reflection Overlay
                        IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                ],
                                stops: const [0.0, 0.3, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 3. PIANO-KEY CONTROLS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      final preset = presets[index];
                      final isActive = currentRadio?.id == preset?.id && preset != null;

                      return _MechanicalButton(
                        isFirstButton: index == 0, 
                        isActive: isActive,
                        isEmpty: preset == null,
                        onTap: () {
                          if (preset != null) {
                            ref.read(radioControllerProvider.notifier).tuneToStation(preset);
                          } else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true, 
                              useSafeArea: false,
                              backgroundColor: Colors.transparent, 
                              builder: (context) => const RadioListenPage(),
                            );
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
    );
  }

  Widget _buildTapeReel() {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade600, width: 2),
      ),
      child: Center(
        child: Container(
          width: 14, height: 14,
          decoration: const BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle, 
          ),
        ),
      ),
    );
  }
}

class _MechanicalButton extends StatefulWidget {
  final bool isFirstButton;
  final bool isActive;
  final bool isEmpty;
  final VoidCallback onTap;

  const _MechanicalButton({
    required this.isFirstButton, 
    required this.isActive, 
    required this.isEmpty, 
    required this.onTap
  });

  @override
  State<_MechanicalButton> createState() => _MechanicalButtonState();
}

class _MechanicalButtonState extends State<_MechanicalButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isFirstButton 
        ? (widget.isActive ? Colors.red.shade900 : Colors.red.shade700)
        : (widget.isActive ? const Color(0xFF1E2124) : const Color(0xFF3E4249));

    final isDown = _isPressed || widget.isActive;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 46,
        height: 28,
        margin: EdgeInsets.only(top: isDown ? 4.0 : 0.0, bottom: isDown ? 0.0 : 4.0),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(4), 
          border: Border.all(color: Colors.black87, width: 1.5), 
          boxShadow: isDown ? [] : [
            const BoxShadow(color: Colors.black87, offset: Offset(0, 4), blurRadius: 0) 
          ],
        ),
        child: widget.isEmpty 
            ? const Center(child: Icon(Icons.add_rounded, color: Colors.white24, size: 14))
            : const SizedBox.shrink(), 
      ),
    );
  }
}

// BULLETPROOF MARQUEE: Uses standard async loop and SingleChildScrollView. NO layout loops!
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  late ScrollController _scrollController;
  bool _isScrolling = false;
  bool _needsInitialDelay = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _needsInitialDelay = true;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  void _startScrolling() async {
    if (_isScrolling) return;
    _isScrolling = true;

    while (mounted) {
      if (!_scrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      if (_needsInitialDelay) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) break;
        _needsInitialDelay = false;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      
      if (maxScroll > 0) {
        final duration = Duration(milliseconds: (maxScroll * 1000 / 30).round());

        try {
          await _scrollController.animateTo(
            maxScroll,
            duration: duration,
            curve: Curves.linear,
          );
        } catch (e) {
          // Ignored if user switches stations mid-scroll
        }

        if (!mounted) break;
        
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    _isScrolling = false;
  }

  @override
  void dispose() {
    _isScrolling = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure the text safely to see if it overflows
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        if (textPainter.width > constraints.maxWidth) {
          return SizedBox(
            height: 18,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(), 
              child: Row(
                children: [
                  Text(widget.text, style: widget.style),
                  SizedBox(width: constraints.maxWidth), // Space before loop
                  Text(widget.text, style: widget.style), // The loop copy
                  SizedBox(width: constraints.maxWidth), // Trailing space
                ],
              ),
            ),
          );
        } else {
          // It fits perfectly! Center it and don't scroll.
          return SizedBox(
            height: 18,
            child: Center(
              child: Text(
                widget.text,
                style: widget.style,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          );
        }
      },
    );
  }
}