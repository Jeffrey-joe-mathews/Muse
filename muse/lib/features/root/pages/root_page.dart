// lib/features/root/pages/root_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:ui';

// Dummy pages for now
import '../../search/pages/search_page.dart'; // We'll repurpose this for Explore
import '../../library/pages/collection_page.dart'; // Create this
import '../../player/pages/listen_page.dart'; // Create this

final navIndexProvider = StateProvider<int>((ref) => 0);

class RootPage extends ConsumerWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);

    final pages = [
      const ListenPage(),
      const SearchPage(), // Will become Explore
      const CollectionPage(),
      const Scaffold(body: Center(child: Text("Intelligence / AI"))), // Placeholder
    ];

    return Scaffold(
      backgroundColor: Colors.black, // Dark space
      extendBody: true, // Crucial for floating dock
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: const FloatingDock(),
    );
  }
}

class FloatingDock extends ConsumerWidget {
  const FloatingDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 32.0, right: 32.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DockItem(icon: Icons.play_circle_fill, label: "Listen", index: 0, currentIndex: currentIndex, ref: ref),
                  _DockItem(icon: Icons.explore, label: "Explore", index: 1, currentIndex: currentIndex, ref: ref),
                  _DockItem(icon: Icons.library_music, label: "Collection", index: 2, currentIndex: currentIndex, ref: ref),
                  _DockItem(icon: Icons.auto_awesome, label: "Intel", index: 3, currentIndex: currentIndex, ref: ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final WidgetRef ref;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => ref.read(navIndexProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white54, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ]
          ],
        ),
      ),
    );
  }
}