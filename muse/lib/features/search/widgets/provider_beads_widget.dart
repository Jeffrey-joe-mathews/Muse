import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../controllers/search_controller.dart';

// 1. THE STATE LIVES HERE NOW (Encapsulated!)
final activeSearchFiltersProvider = StateProvider.autoDispose<Set<String>>((ref) {
  final controller = ref.read(searchControllerProvider.notifier);
  return controller.avilableSourceNames.toSet();
});

// 2. THE WIDGET
class ProviderBeadsWidget extends ConsumerWidget {
  const ProviderBeadsWidget({super.key});

  // Helper for colors
  Color _getBrandColor(String sourceName) {
    switch (sourceName.toLowerCase()) {
      case 'soundcloud': return Colors.orange;
      case 'jamendo': return Colors.purpleAccent;
      case 'local': return Colors.tealAccent; 
      case 'youtube': return Colors.red;
      case 'audius': return Colors.deepPurpleAccent;
      case 'archive': return Colors.blueGrey;
      case 'radiobrowser': return Colors.greenAccent;
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilters = ref.watch(activeSearchFiltersProvider);
    final availableSources = ref.read(searchControllerProvider.notifier).avilableSourceNames;

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: availableSources.map((source) {
        final isActive = activeFilters.contains(source);
        final brandColor = _getBrandColor(source);

        return GestureDetector(
          onTap: () {
            final current = ref.read(activeSearchFiltersProvider);
            if (current.contains(source)) {
              ref.read(activeSearchFiltersProvider.notifier).state = current.difference({source});
            } else {
              ref.read(activeSearchFiltersProvider.notifier).state = current.union({source});
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? brandColor.withOpacity(0.08) : Colors.transparent,
              border: Border.all(
                color: isActive ? brandColor.withOpacity(0.6) : Colors.white24,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              source.toUpperCase(),
              style: TextStyle(
                color: isActive ? brandColor : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}