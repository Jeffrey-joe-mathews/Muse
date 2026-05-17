import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:muse/core/services/storage_service.dart';
import 'package:muse/features/player/controllers/player_controller.dart';
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
              // 1. Get the public vault from your StorageService
              final vaultPath = StorageService().vaultPath;
              final vaultDir = Directory(vaultPath);

              // 2. Copy the cached file to the permanent public folder
              final permanentFile = await File(pickedPath).copy('${vaultDir.path}/$name');

              // 3. Send the public path to Isar
              ref.read(collectionControllerProvider.notifier).addSong(permanentFile.path);
              
              // Optional: Clean up the cache so we don't waste storage
              File(pickedPath).delete().ignore();
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