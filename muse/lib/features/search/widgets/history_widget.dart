import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/history_controller.dart';
import '../../player/controllers/player_controller.dart';

class SearchHistoryWidget extends ConsumerWidget {
  final FocusNode searchFocusNode;
  
  const SearchHistoryWidget({super.key, required this.searchFocusNode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyList = ref.watch(historyControllerProvider);

    if (historyList.isEmpty) {
      return const Center(
        child: Text("No recent searches", style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      itemCount: historyList.length,
      itemBuilder: (context, index) {
        final song = historyList[index];

        return Dismissible(
          key: Key(song.audioURL), 
          direction: DismissDirection.horizontal,
          background: Container(
            color: Colors.red.shade900,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red.shade900,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            final dummyPath = "stream://${song.source.name}/${song.id}";
            ref.read(historyControllerProvider.notifier).removeFromHistory(dummyPath);
          },
          child: ListTile(
            // leading: const Icon(Icons.history, color: Colors.white54),
            leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle, // THE SHAPE SHIFT
              color: Colors.white10,
              image: song.albumArt.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(song.albumArt),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: song.albumArt.isEmpty
                ? const Icon(Icons.history, color: Colors.white54, size: 24)
                : null,
          ),
            title: Text(song.title, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {
              ref.read(playerControllerProvider.notifier).playSong(song);
              
              ref.read(historyControllerProvider.notifier).addSongToHistory(song);
              
              searchFocusNode.unfocus(); 
            },
          ),
        );
      },
    );
  }
}