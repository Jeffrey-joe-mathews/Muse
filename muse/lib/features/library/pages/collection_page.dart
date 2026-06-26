import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/song.dart';
import '../../player/controllers/player_controller.dart';
import '../controllers/collection_controller.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primitives/muse_glass.dart';

class CollectionPage extends ConsumerStatefulWidget {
  const CollectionPage({super.key});

  @override
  ConsumerState<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends ConsumerState<CollectionPage> {
  String? _activeFolder;
  bool _isGridView = false; 
  
  final Set<String> _hiddenGhosts = {};

  @override
  Widget build(BuildContext context) {
    final collectionState = ref.watch(collectionControllerProvider);
    final playerState = ref.watch(playerControllerProvider);

    // DYNAMIC GLOBAL PLAY STATE: Find out exactly which song is playing right now
    final String? currentSongId = (playerState.queue.isNotEmpty && 
                                   playerState.currentIndex >= 0 && 
                                   playerState.currentIndex < playerState.queue.length)
        ? playerState.queue[playerState.currentIndex].id
        : null;

    return PopScope(
      canPop: _activeFolder == null,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (_activeFolder == "Cloud Streams" || !_activeFolder!.contains('/')) {
            setState(() => _activeFolder = null);
          } else {
            setState(() => _activeFolder = _activeFolder!.substring(0, _activeFolder!.lastIndexOf('/')));
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background, 
        
        floatingActionButton: MuseGlass(
          borderRadius: 30, 
          blurSigma: 20.0,
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: AppColors.pureWhite, size: 28),
            onPressed: () async {
              FilePickerResult? result = await FilePicker.pickFiles(type: FileType.audio);

              if (result != null && result.files.isNotEmpty) {
                final pickedPath = result.files.first.path;
                final name = result.files.first.name;
                
                if (pickedPath != null) {
                  final vaultPath = StorageService().vaultPath;
                  final targetDir = (_activeFolder == null || _activeFolder == "Cloud Streams") 
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

        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Vault",
                          style: TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isGridView = !_isGridView),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                            child: Icon(
                              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, 
                              color: AppColors.glassTextMuted,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _activeFolder == null 
                          ? "~/Music/MuseVault" 
                          : "~/Music/MuseVault/$_activeFolder",
                      style: const TextStyle(
                        color: AppColors.glassTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: collectionState.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.pureWhite)),
                  error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.redAccent))),
                  data: (rawSongs) {
                    final songs = rawSongs.where((s) => !_hiddenGhosts.contains(s.id)).toList();
                    final vaultPath = StorageService().vaultPath;

                    if (songs.isEmpty && _activeFolder == null) {
                      return const Center(
                        child: Text(
                          "Vault is empty. Tap + to add music.", 
                          style: TextStyle(color: AppColors.glassTextMuted, fontWeight: FontWeight.w600)
                        )
                      );
                    }

                    List<String> subFolders = [];
                    List<Song> directSongs = [];
                    Map<String, int> folderItemCounts = {};
                    bool isRoot = _activeFolder == null;

                    if (_activeFolder == "Cloud Streams") {
                      directSongs = songs.where((s) => s.source != SongSource.local).toList();
                    } else {
                      String currentDirPath = isRoot ? vaultPath : '$vaultPath/$_activeFolder';
                      Set<String> subFolderSet = {};
                      int cloudCount = 0;

                      for (var song in songs) {
                        if (song.source != SongSource.local) {
                          if (isRoot) cloudCount++;
                        } else {
                          if (song.audioURL.startsWith('$currentDirPath/')) {
                            String relPath = song.audioURL.substring(currentDirPath.length + 1);
                            List<String> segments = relPath.split('/');
                            
                            if (segments.length == 1) {
                              directSongs.add(song);
                            } else {
                              String subDir = segments.first;
                              subFolderSet.add(subDir);
                              folderItemCounts[subDir] = (folderItemCounts[subDir] ?? 0) + 1;
                            }
                          }
                        }
                      }
                      
                      subFolders = subFolderSet.toList()..sort();
                      
                      if (isRoot && cloudCount > 0) {
                        subFolders.add("Cloud Streams");
                        folderItemCounts["Cloud Streams"] = cloudCount;
                      }
                    }

                    final int backButtonCount = isRoot ? 0 : 1;
                    final int totalItems = backButtonCount + subFolders.length + directSongs.length;

                    return _isGridView 
                      ? GridView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 120),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1,
                          ),
                          itemCount: totalItems,
                          itemBuilder: (context, index) => _buildUnifiedItem(index, backButtonCount, subFolders, folderItemCounts, directSongs, currentSongId),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 120),
                          itemCount: totalItems,
                          // The padding wrapper that adds vertical breathing room between list items
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0), 
                            child: _buildUnifiedItem(index, backButtonCount, subFolders, folderItemCounts, directSongs, currentSongId),
                          ),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedItem(int index, int backButtonCount, List<String> subFolders, Map<String, int> counts, List<Song> directSongs, String? currentSongId) {
    if (index < backButtonCount) {
      return _buildUnixBackButton();
    }
    
    int folderIndex = index - backButtonCount;
    if (folderIndex < subFolders.length) {
      String folderName = subFolders[folderIndex];
      bool isCloud = folderName == "Cloud Streams";
      int count = counts[folderName] ?? 0;
      return _buildFolderItem(folderName, count, isCloud);
    }
    
    int songIndex = folderIndex - subFolders.length;
    final song = directSongs[songIndex];
    // We check if this specific song's ID matches the one playing in Riverpod
    final isPlaying = song.id == currentSongId;
    
    return _buildSongItem(song, directSongs, songIndex, isPlaying);
  }

  Widget _buildFolderItem(String folderName, int count, bool isCloud) {
    final icon = isCloud ? Icons.cloud_outlined : Icons.folder_open_rounded;
    final onTap = () async {
      if (!isCloud) {
        final targetPath = _activeFolder == null ? folderName : '$_activeFolder/$folderName';
        final targetDir = Directory('${StorageService().vaultPath}/$targetPath');
        
        if (!targetDir.existsSync()) {
          setState(() => _hiddenGhosts.add(folderName));
          ref.read(collectionControllerProvider.notifier).syncVault();
          return;
        }
        setState(() => _activeFolder = targetPath);
      } else {
        setState(() => _activeFolder = "Cloud Streams");
      }
    };

    if (_isGridView) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassShell, 
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: AppColors.pureWhite), 
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(folderName, style: const TextStyle(color: AppColors.pureWhite, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Text("$count items", style: const TextStyle(color: AppColors.glassTextMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Standardized inner padding
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppColors.glassShell,
                borderRadius: BorderRadius.circular(10)
              ),
              child: Icon(icon, size: 24, color: AppColors.pureWhite),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(folderName, style: const TextStyle(color: AppColors.pureWhite, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("$count items", style: const TextStyle(color: AppColors.glassTextMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.glassTextMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUnixBackButton() {
    final onTap = () {
      if (_activeFolder == "Cloud Streams" || !_activeFolder!.contains('/')) {
        setState(() => _activeFolder = null);
      } else {
        setState(() => _activeFolder = _activeFolder!.substring(0, _activeFolder!.lastIndexOf('/')));
      }
    };

    if (_isGridView) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassShell,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.drive_folder_upload, size: 48, color: AppColors.glassTextMuted),
              SizedBox(height: 12),
              Text("..", style: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold, fontSize: 24)),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppColors.glassShell,
                borderRadius: BorderRadius.circular(10)
              ),
              child: const Icon(Icons.drive_folder_upload, size: 24, color: AppColors.glassTextMuted),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text("..", style: TextStyle(color: AppColors.pureWhite, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem(Song song, List<Song> queue, int index, bool isPlaying) {
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
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: AppColors.glassShell, 
            borderRadius: BorderRadius.circular(16),
            // Highlights the active grid item beautifully
            border: isPlaying ? Border.all(color: AppColors.pureWhite.withOpacity(0.2), width: 1.5) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: hasArt ? DecorationImage(image: imageProvider!, fit: BoxFit.cover) : null,
                  ),
                  child: hasArt ? null : const Icon(Icons.audio_file_outlined, size: 48, color: AppColors.glassTextMuted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title, 
                      style: TextStyle(color: AppColors.pureWhite, fontSize: 14, fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600), 
                      maxLines: 1, overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist, 
                      style: const TextStyle(color: AppColors.glassTextMuted, fontSize: 12), 
                      maxLines: 1, overflow: TextOverflow.ellipsis
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // List View Song Item: Flow-Style Active Highlight
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.glassShell : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isPlaying ? Border.all(color: AppColors.glassBorder) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppColors.glassShell,
                borderRadius: BorderRadius.circular(10),
                image: hasArt ? DecorationImage(image: imageProvider!, fit: BoxFit.cover) : null,
              ),
              child: hasArt ? null : const Icon(Icons.audio_file_outlined, size: 20, color: AppColors.glassTextMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title, 
                    style: TextStyle(
                      color: AppColors.pureWhite, 
                      fontSize: 14, 
                      fontWeight: isPlaying ? FontWeight.w800 : FontWeight.bold
                    ), 
                    maxLines: 1, overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist, 
                    style: const TextStyle(color: AppColors.glassTextMuted, fontSize: 12), 
                    maxLines: 1, overflow: TextOverflow.ellipsis
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
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Icon(Icons.more_vert_rounded, color: AppColors.glassTextMuted, size: 18), 
              ),
          ],
        ),
      ),
    );
  }
}

// --- TRUE ANIMATED EQUALIZER ---
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
            color: AppColors.pureWhite, 
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}