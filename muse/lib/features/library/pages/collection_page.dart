import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/song.dart';
import '../../player/controllers/player_controller.dart';
import '../controllers/collection_controller.dart';

class CollectionPage extends ConsumerStatefulWidget {
  const CollectionPage({super.key});

  @override
  ConsumerState<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends ConsumerState<CollectionPage> {
  String? _activeFolder;
  bool _isGridView = true; // Toggle between List and Grid View
  
  // THE UI MASK: Instantly hides deleted items while Isar cleans up in the background.
  final Set<String> _hiddenGhosts = {};

  // Reusable Frosted Glass Wrapper
  Widget _buildFrostedGlass({required Widget child, double borderRadius = 16.0}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.0),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionState = ref.watch(collectionControllerProvider);

    return PopScope(
      canPop: _activeFolder == null,
      onPopInvoked: (didPop) {
        if (!didPop) {
          setState(() => _activeFolder = null);
        }
      },
      child: Stack(
        children: [
          // ─── ABSTRACT VIBRANT BACKGROUND ──────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ─── MAIN UI LAYER ────────────────────────────────────────────────
          Scaffold(
            backgroundColor: Colors.transparent, // Let the background bleed through
            appBar: AppBar(
              backgroundColor: Colors.black.withOpacity(0.2),
              elevation: 0,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
              title: Text(
                _activeFolder == null ? "MuseVault" : "MuseVault / $_activeFolder", 
                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2, fontFamily: 'monospace')
              ),
              actions: [
                IconButton(
                  icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: Colors.white),
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                  tooltip: "Toggle View",
                ),
              ],
            ),
            
            // ─── FLOATING ACTION BUTTON ─────────────────────────────────────
            floatingActionButton: _buildFrostedGlass(
              borderRadius: 30,
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.pickFiles(type: FileType.audio);

                  if (result != null && result.files.isNotEmpty) {
                    final pickedPath = result.files.first.path;
                    final name = result.files.first.name;
                    
                    if (pickedPath != null) {
                      final vaultPath = StorageService().vaultPath;
                      final targetDir = _activeFolder == null 
                          ? Directory('$vaultPath/Inbox') 
                          : Directory('$vaultPath/$_activeFolder');
                      
                      if (!targetDir.existsSync()) targetDir.createSync();

                      final permanentFile = await File(pickedPath).copy('${targetDir.path}/$name');
                      ref.read(collectionControllerProvider.notifier).addSong(permanentFile.path);
                      File(pickedPath).delete().ignore();
                    }
                  }
                },
              ),
            ),

            // ─── BODY CONTENT ───────────────────────────────────────────────
            body: collectionState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
              error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.redAccent))),
              data: (rawSongs) {
                final songs = rawSongs.where((s) => !_hiddenGhosts.contains(s.id)).toList();

                if (songs.isEmpty && _activeFolder == null) {
                  return const Center(child: Text("Vault is empty. Tap + to add music.", style: TextStyle(color: Colors.white54, fontFamily: 'monospace')));
                }

                // ─── ROOT VIEW: FOLDERS ONLY ────────────────────────────────
                if (_activeFolder == null) {
                  final Map<String, List<Song>> folders = {};
                  final List<Song> cloudStreams = [];

                  for (var song in songs) {
                    if (song.source == SongSource.local) {
                      final parentFolderName = Directory(song.audioURL).parent.path.split('/').last;
                      if (!folders.containsKey(parentFolderName)) folders[parentFolderName] = [];
                      folders[parentFolderName]!.add(song);
                    } else {
                      cloudStreams.add(song);
                    }
                  }

                  final folderNames = folders.keys.where((f) => !_hiddenGhosts.contains(f)).toList()..sort();
                  final totalItems = folderNames.length + (cloudStreams.isNotEmpty ? 1 : 0);

                  return _isGridView 
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1,
                        ),
                        itemCount: totalItems,
                        itemBuilder: (context, index) => _buildRootItem(index, folderNames, cloudStreams, folders),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: totalItems,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRootItem(index, folderNames, cloudStreams, folders),
                        ),
                      );
                }

                // ─── FOLDER VIEW: '..' + SONGS ──────────────────────────────
                final List<Song> folderSongs = _activeFolder == "Cloud Streams"
                    ? songs.where((s) => s.source != SongSource.local).toList()
                    : songs.where((s) => s.source == SongSource.local && Directory(s.audioURL).parent.path.split('/').last == _activeFolder).toList();

                return _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
                      ),
                      // +1 for the '..' back directory
                      itemCount: folderSongs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) return _buildUnixBackButton();
                        return _buildSongItem(folderSongs[index - 1], folderSongs, index - 1);
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                      itemCount: folderSongs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) return Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildUnixBackButton());
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSongItem(folderSongs[index - 1], folderSongs, index - 1),
                        );
                      },
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── WIDGET BUILDERS ──────────────────────────────────────────────────────

  Widget _buildRootItem(int index, List<String> folderNames, List<Song> cloudStreams, Map<String, List<Song>> folders) {
    final isCloud = index == folderNames.length;
    final folderName = isCloud ? "Cloud Streams" : folderNames[index];
    final count = isCloud ? cloudStreams.length : folders[folderName]!.length;
    final icon = isCloud ? Icons.cloud_outlined : Icons.folder_open_rounded;
    final accentColor = isCloud ? Colors.tealAccent : Colors.blueGrey.shade200;

    return _buildFrostedGlass(
      child: InkWell(
        onTap: () async {
          if (!isCloud) {
            final targetDir = Directory('${StorageService().vaultPath}/$folderName');
            if (!targetDir.existsSync()) {
              setState(() => _hiddenGhosts.add(folderName));
              ref.read(collectionControllerProvider.notifier).syncVault();
              return;
            }
          }
          setState(() => _activeFolder = folderName);
        },
        child: _isGridView 
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: accentColor),
                const SizedBox(height: 12),
                Text(folderName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                Text("$count items", style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            )
          : ListTile(
              leading: Icon(icon, size: 36, color: accentColor),
              title: Text(folderName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              subtitle: Text("$count items", style: const TextStyle(color: Colors.white54)),
            ),
      ),
    );
  }

  Widget _buildUnixBackButton() {
    return _buildFrostedGlass(
      child: InkWell(
        onTap: () => setState(() => _activeFolder = null),
        child: _isGridView
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.drive_folder_upload, size: 48, color: Colors.white54),
                SizedBox(height: 12),
                Text("..", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'monospace')),
              ],
            )
          : const ListTile(
              leading: Icon(Icons.drive_folder_upload, size: 36, color: Colors.white54),
              title: Text("..", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'monospace')),
            ),
      ),
    );
  }

  Widget _buildSongItem(Song song, List<Song> queue, int index) {
    final bool hasArt = song.albumArt.isNotEmpty;
    final imageProvider = hasArt 
        ? (song.albumArt.startsWith('http') ? NetworkImage(song.albumArt) : FileImage(File(song.albumArt))) as ImageProvider
        : null;

    final onTap = () async {
      if (song.source == SongSource.local && !File(song.audioURL).existsSync()) {
        setState(() => _hiddenGhosts.add(song.id));
        ref.read(collectionControllerProvider.notifier).syncVault();
        return;
      }
      ref.read(playerControllerProvider.notifier).playQueue(queue, index);
    };

    if (_isGridView) {
      return _buildFrostedGlass(
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    image: hasArt ? DecorationImage(image: imageProvider!, fit: BoxFit.cover) : null,
                  ),
                  child: hasArt ? null : const Icon(Icons.audio_file_outlined, size: 48, color: Colors.white30),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(song.artist, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // List View Song Item
    return _buildFrostedGlass(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Colors.black26, 
            borderRadius: BorderRadius.circular(8),
            image: hasArt ? DecorationImage(image: imageProvider!, fit: BoxFit.cover) : null,
          ),
          child: hasArt ? null : const Icon(Icons.audio_file_outlined, color: Colors.white54),
        ),
        title: Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: onTap,
      ),
    );
  }
}