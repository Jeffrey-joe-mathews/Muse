import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:muse/features/player/controllers/player_controller.dart';
import 'package:path_provider/path_provider.dart';
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
          FilePickerResult? result = await FilePicker.pickFiles(
            type: FileType.audio,
          );

          if (result != null && result.files.isNotEmpty) {
            final pickedPath = result.files.first.path;
            final name = result.files.first.name;
            
            if (pickedPath != null) {
              // 1. Get the app's permanent vault
              final appDir = await getApplicationDocumentsDirectory();
              final musicDir = Directory('${appDir.path}/music');
              if (!await musicDir.exists()) await musicDir.create();

              // 2. Copy the file out of the volatile cache
              final permanentFile = await File(pickedPath).copy('${musicDir.path}/$name');

              // 3. Save THIS permanent path to Isar, NOT the cache path!
              ref.read(collectionControllerProvider.notifier).addSong(permanentFile.path);
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
                  decoration: BoxDecoration(
                    color: Colors.white10, 
                    borderRadius: BorderRadius.circular(8),
                    image: song.albumArt.isNotEmpty ? DecorationImage(
                      image: song.albumArt.startsWith('http') 
                      ? NetworkImage(song.albumArt) as ImageProvider 
                      : FileImage(File(song.albumArt)),
                      fit: BoxFit.cover) :
                      null
                  ),
                ),
                title: Text(song.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54)),
                onTap: () {
                  // FIX 1: Use playQueue so the player knows what the next/previous songs are!
                  ref.read(playerControllerProvider.notifier).playQueue(songs, index);
                  
                  // FIX 2: Use audioURL instead of filePath
                  debugPrint("Play: ${song.audioURL}");
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