// lib/features/library/pages/collection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/collection_controller.dart';

class CollectionPage extends ConsumerWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionState = ref.watch(collectionControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("My Collection", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      
      // THE PLUS BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          // Open the device file picker looking for audio
          FilePickerResult? result = await FilePicker.pickFiles(
            type: FileType.audio,
          );

          // Cleaner, warning-free null check using isNotEmpty
          if (result != null && result.files.isNotEmpty) {
            final file = result.files.first;
            
            // Safely extract path and name
            final path = file.path;
            final name = file.name;
            
            // Only add if path exists
            if (path != null) {
              ref.read(collectionControllerProvider.notifier).addSong(path, name);
            }
          }
        },
      ),

      // THE DATABASE LIST
      body: collectionState.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text("Tap + to add local music.", style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
                title: Text(song.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54)),
                onTap: () {
                  // Replaced print() with debugPrint() to satisfy the linter
                  debugPrint("Play: ${song.filePath}");
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}