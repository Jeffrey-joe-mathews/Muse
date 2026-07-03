import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse/features/root/pages/root_page.dart';
import 'package:vibration/vibration.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/song.dart';
import '../../player/controllers/player_controller.dart';
import '../controllers/collection_controller.dart';

import '../../../core/theme/app_colors.dart';

final activeFolderProvider = StateProvider<String?>((ref) => null);

class CollectionPage extends ConsumerStatefulWidget {
  const CollectionPage({super.key});

  @override
  ConsumerState<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends ConsumerState<CollectionPage> {
  bool _isGridView = false;
  final Set<String> _hiddenGhosts = {};

  final ScrollController _scrollController = ScrollController();
  bool? _dragSelectIntent;
  int _lastDragIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _applySelection(String itemId, bool select) {
    final currentSet = Set<String>.from(ref.read(selectedItemsProvider));
    if (select) {
      currentSet.add(itemId);
    } else {
      currentSet.remove(itemId);
    }
    ref.read(selectedItemsProvider.notifier).state = currentSet;
  }

  void _handleSelectionToggle(String itemId) {
    final selected = Set<String>.from(ref.read(selectedItemsProvider));
    final isCurrentlySelected = selected.contains(itemId);
    _applySelection(itemId, !isCurrentlySelected);
  }

  int _calculateIndex(double dy, double dx, BuildContext context) {
    if (!_scrollController.hasClients) return -1;
    final scrollOffset = _scrollController.offset;
    final totalY = dy + scrollOffset - 8; // Account for top padding

    if (totalY < 0) return -1;

    if (!_isGridView) {
      // ListView: Approx 70px per row (62px container + 8px padding)
      return (totalY / 70).floor();
    } else {
      // GridView Math
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = (screenWidth - 32 - 16) / 2; // 16px screen padding on sides + 16px center gap
      final itemHeight = itemWidth / 1.1; // aspect ratio 1.1
      final row = (totalY / (itemHeight + 16)).floor();
      final col = (dx > (16 + itemWidth + 8)) ? 1 : 0;
      return (row * 2) + col;
    }
  }

  String? _getItemIdForSelection(int index, int backButtonCount, List<String> subFolders, List<Song> directSongs) {
    if (index < backButtonCount) return null;
    int folderIndex = index - backButtonCount;
    if (folderIndex < subFolders.length) {
      return subFolders[folderIndex];
    }
    int songIndex = folderIndex - subFolders.length;
    if (songIndex < directSongs.length) {
      return directSongs[songIndex].audioURL;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final collectionState = ref.watch(collectionControllerProvider);
    final playerState = ref.watch(playerControllerProvider);

    final activeFolder = ref.watch(activeFolderProvider);
    final isVaultMenuOpen = ref.watch(vaultMenuProvider);

    final isMultiSelect = ref.watch(multiSelectProvider);
    final selectedItems = ref.watch(selectedItemsProvider);

    final String? currentSongId =
        (playerState.queue.isNotEmpty &&
            playerState.currentIndex >= 0 &&
            playerState.currentIndex < playerState.queue.length)
        ? playerState.queue[playerState.currentIndex].id
        : null;

    return PopScope(
      canPop: activeFolder == null && !isVaultMenuOpen && !isMultiSelect,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (isMultiSelect) {
            ref.read(multiSelectProvider.notifier).state = false;
            ref.read(selectedItemsProvider.notifier).state = {};
            return;
          }

          if (isVaultMenuOpen) {
            ref.read(vaultMenuProvider.notifier).state = false;
            return;
          }

          if (activeFolder == "Cloud Streams" || !activeFolder!.contains('/')) {
            ref.read(activeFolderProvider.notifier).state = null;
          } else {
            ref.read(activeFolderProvider.notifier).state = activeFolder
                .substring(0, activeFolder.lastIndexOf('/'));
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isMultiSelect
                          ? Row(
                              key: const ValueKey('multiselect_header'),
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${selectedItems.length} Selected",
                                  style: const TextStyle(
                                    color: AppColors.pureWhite,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              key: const ValueKey('vault_header'),
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
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () =>
                                          ref
                                                  .read(
                                                    vaultMenuProvider.notifier,
                                                  )
                                                  .state =
                                              !isVaultMenuOpen,
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16.0,
                                          bottom: 8.0,
                                        ),
                                        child: Icon(
                                          isVaultMenuOpen
                                              ? Icons.close_rounded
                                              : Icons
                                                    .add_circle_outline_rounded,
                                          color: isVaultMenuOpen
                                              ? AppColors.pureWhite
                                              : AppColors.glassTextMuted,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _isGridView = !_isGridView,
                                      ),
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16.0,
                                          bottom: 8.0,
                                        ),
                                        child: Icon(
                                          _isGridView
                                              ? Icons.view_list_rounded
                                              : Icons.grid_view_rounded,
                                          color: AppColors.glassTextMuted,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 6),

                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        activeFolder == null
                            ? "~/Music/MuseVault"
                            : "~/Music/MuseVault/$activeFolder",
                        style: const TextStyle(
                          color: AppColors.glassTextMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: collectionState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.pureWhite,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      "Error: $err",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  data: (rawSongs) {
                    final songs = rawSongs
                        .where((s) => !_hiddenGhosts.contains(s.id))
                        .toList();
                    final vaultPath = StorageService().vaultPath;
                    final rootDir = Directory(vaultPath);
                    final hasPhysicalFolders =
                        rootDir.existsSync() &&
                        rootDir
                            .listSync(recursive: false)
                            .whereType<Directory>()
                            .isNotEmpty;

                    if (songs.isEmpty &&
                        activeFolder == null &&
                        !hasPhysicalFolders) {
                      return const Center(
                        child: Text(
                          "Vault is empty, use + to add music.",
                          style: TextStyle(
                            color: AppColors.glassTextMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    List<String> subFolders = [];
                    List<Song> directSongs = [];
                    Map<String, int> folderItemCounts = {};
                    bool isRoot = activeFolder == null;

                    if (activeFolder == "Cloud Streams") {
                      directSongs = songs
                          .where((s) => s.source != SongSource.local)
                          .toList();
                    } else {
                      String currentDirPath = isRoot
                          ? vaultPath
                          : '$vaultPath/$activeFolder';
                      Set<String> subFolderSet = {};
                      int cloudCount = 0;

                      // read the directories so that empty folders can also be displayed
                      final currentDir = Directory(currentDirPath);
                      if (currentDir.existsSync()) {
                        for (var entity in currentDir.listSync(
                          recursive: false,
                        )) {
                          if (entity is Directory) {
                            final folderName = entity.path.split('/').last;
                            if (!folderName.startsWith('.')) {
                              subFolderSet.add(folderName);
                            }
                          }
                        }
                      }

                      for (var song in songs) {
                        if (song.source != SongSource.local) {
                          if (isRoot) cloudCount++;
                        } else {
                          if (song.audioURL.startsWith('$currentDirPath/')) {
                            String relPath = song.audioURL.substring(
                              currentDirPath.length + 1,
                            );
                            List<String> segments = relPath.split('/');

                            if (segments.length == 1) {
                              directSongs.add(song);
                            } else {
                              String subDir = segments.first;
                              subFolderSet.add(subDir);
                              folderItemCounts[subDir] =
                                  (folderItemCounts[subDir] ?? 0) + 1;
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

                    final int backButtonCount = (isRoot || isMultiSelect)
                        ? 0
                        : 1;
                    final int totalItems =
                        backButtonCount +
                        subFolders.length +
                        directSongs.length;

                    return GestureDetector(
                      // Only intercept LongPress if we are in MultiSelect mode
                      onLongPressStart: isMultiSelect ? (details) {
                        final index = _calculateIndex(details.localPosition.dy, details.localPosition.dx, context);
                        if (index >= backButtonCount && index < totalItems) {
                          final itemId = _getItemIdForSelection(index, backButtonCount, subFolders, directSongs);
                          if (itemId != null) {
                            final isCurrentlySelected = selectedItems.contains(itemId);
                            _dragSelectIntent = !isCurrentlySelected; 
                            _lastDragIndex = index;
                            _applySelection(itemId, _dragSelectIntent!);
                            Vibration.vibrate(duration: 30); 
                          }
                        }
                      } : null,
                      onLongPressMoveUpdate: isMultiSelect ? (details) {
                        if (_dragSelectIntent == null) return;
                        final index = _calculateIndex(details.localPosition.dy, details.localPosition.dx, context);
                        
                        // Only apply selection if we crossed into a new valid index boundary
                        if (index >= backButtonCount && index < totalItems && index != _lastDragIndex) {
                          final itemId = _getItemIdForSelection(index, backButtonCount, subFolders, directSongs);
                          if (itemId != null) {
                            _applySelection(itemId, _dragSelectIntent!);
                          }
                          _lastDragIndex = index;
                        }
                      } : null,
                      onLongPressEnd: isMultiSelect ? (_) {
                        _dragSelectIntent = null;
                        _lastDragIndex = -1;
                      } : null,
                      child: _isGridView
                          ? GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                                bottom: 120,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.1,
                                  ),
                              itemCount: totalItems,
                              itemBuilder: (context, index) => _buildUnifiedItem(
                                index,
                                backButtonCount,
                                subFolders,
                                folderItemCounts,
                                directSongs,
                                currentSongId,
                                activeFolder,
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                                bottom: 120,
                              ),
                              itemCount: totalItems,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildUnifiedItem(
                                  index,
                                  backButtonCount,
                                  subFolders,
                                  folderItemCounts,
                                  directSongs,
                                  currentSongId,
                                  activeFolder,
                                ),
                              ),
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

  Widget _buildSelectionBox(
    bool isMultiSelect,
    bool isSelected,
    Widget normalIcon,
  ) {
    if (!isMultiSelect) return normalIcon;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.pureWhite : AppColors.glassShell,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.pureWhite : AppColors.glassBorder,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: Colors.black, size: 24)
          : null,
    );
  }

  Widget _buildUnifiedItem(
    int index,
    int backButtonCount,
    List<String> subFolders,
    Map<String, int> counts,
    List<Song> directSongs,
    String? currentSongId,
    String? activeFolder,
  ) {
    if (index < backButtonCount) {
      return _buildUnixBackButton(activeFolder);
    }

    int folderIndex = index - backButtonCount;
    if (folderIndex < subFolders.length) {
      String folderName = subFolders[folderIndex];
      bool isCloud = folderName == "Cloud Streams";
      int count = counts[folderName] ?? 0;
      return _buildFolderItem(folderName, count, isCloud, activeFolder);
    }

    int songIndex = folderIndex - subFolders.length;
    final song = directSongs[songIndex];
    final isPlaying = song.id == currentSongId;

    return _buildSongItem(song, directSongs, songIndex, isPlaying);
  }

  Widget _buildFolderItem(
    String folderName,
    int count,
    bool isCloud,
    String? activeFolder,
  ) {
    final isMultiSelect = ref.watch(multiSelectProvider);
    final selectedItems = ref.watch(selectedItemsProvider);

    final isSelected = selectedItems.contains(folderName) && !isCloud;
    final icon = isCloud ? Icons.cloud_outlined : Icons.folder_open_rounded;

    final onTap = () async {
      if (isMultiSelect) {
        if (!isCloud) _handleSelectionToggle(folderName);
        return;
      }
      if (!isCloud) {
        final targetPath = activeFolder == null
            ? folderName
            : '$activeFolder/$folderName';
        final targetDir = Directory(
          '${StorageService().vaultPath}/$targetPath',
        );

        if (!targetDir.existsSync()) {
          setState(() => _hiddenGhosts.add(folderName));
          ref.read(collectionControllerProvider.notifier).syncVault();
          return;
        }
        ref.read(activeFolderProvider.notifier).state = targetPath;
      } else {
        ref.read(activeFolderProvider.notifier).state = "Cloud Streams";
      }
    };

    final onLongPress = isMultiSelect ? null : () {
      if (!isCloud) {
        ref.read(multiSelectProvider.notifier).state = true;
        _handleSelectionToggle(folderName);
        Vibration.vibrate(duration: 30);
      }
    };

    if (_isGridView) {
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.pureWhite.withOpacity(0.1)
                : AppColors.glassShell,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: AppColors.pureWhite.withOpacity(0.5))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSelectionBox(
                isMultiSelect && !isCloud,
                isSelected,
                Icon(icon, size: 48, color: AppColors.pureWhite),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  folderName,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "$count items",
                style: const TextStyle(
                  color: AppColors.glassTextMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _buildSelectionBox(
              isMultiSelect && !isCloud,
              isSelected,
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.glassShell,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: AppColors.pureWhite),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folderName,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$count items",
                    style: const TextStyle(
                      color: AppColors.glassTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMultiSelect)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.glassTextMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnixBackButton(String? activeFolder) {
    final onTap = () {
      if (activeFolder == "Cloud Streams" || !activeFolder!.contains('/')) {
        ref.read(activeFolderProvider.notifier).state = null;
      } else {
        ref.read(activeFolderProvider.notifier).state = activeFolder.substring(
          0,
          activeFolder.lastIndexOf('/'),
        );
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
              Icon(
                Icons.drive_folder_upload,
                size: 48,
                color: AppColors.glassTextMuted,
              ),
              SizedBox(height: 12),
              Text(
                "..",
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.glassShell,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.drive_folder_upload,
                size: 24,
                color: AppColors.glassTextMuted,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                "..",
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem(
    Song song,
    List<Song> queue,
    int index,
    bool isPlaying,
  ) {
    final isMultiSelect = ref.watch(multiSelectProvider);
    final selectedItems = ref.watch(selectedItemsProvider);
    final isSelected = selectedItems.contains(song.audioURL);

    final bool hasArt = song.albumArt.isNotEmpty;
    final imageProvider = hasArt
        ? (song.albumArt.startsWith('http')
                  ? NetworkImage(song.albumArt)
                  : FileImage(File(song.albumArt)))
              as ImageProvider
        : null;

    final onTap = () async {
      if (isMultiSelect) {
        _handleSelectionToggle(song.audioURL);
        return;
      }

      if (song.source == SongSource.local &&
          !File(song.audioURL).existsSync()) {
        setState(() => _hiddenGhosts.add(song.id));
        ref.read(collectionControllerProvider.notifier).syncVault();
        return;
      }
      ref.read(playerControllerProvider.notifier).playQueue(queue, index);
    };

    final onLongPress = isMultiSelect ? null : () {
      ref.read(multiSelectProvider.notifier).state = true;
      _handleSelectionToggle(song.audioURL);
      Vibration.vibrate(duration: 30);
    };

    if (_isGridView) {
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.pureWhite.withOpacity(0.1)
                : AppColors.glassShell,
            borderRadius: BorderRadius.circular(16),
            border: isPlaying || isSelected
                ? Border.all(
                    color: AppColors.pureWhite.withOpacity(0.5),
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildSelectionBox(
                  isMultiSelect,
                  isSelected,
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      image: hasArt
                          ? DecorationImage(
                              image: imageProvider!,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasArt
                        ? null
                        : const Icon(
                            Icons.audio_file_outlined,
                            size: 48,
                            color: AppColors.glassTextMuted,
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 14,
                        fontWeight: isPlaying
                            ? FontWeight.bold
                            : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: const TextStyle(
                        color: AppColors.glassTextMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (isPlaying && !isMultiSelect)
              ? AppColors.glassShell
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: (isPlaying && !isMultiSelect)
              ? Border.all(color: AppColors.glassBorder)
              : null,
        ),
        child: Row(
          children: [
            _buildSelectionBox(
              isMultiSelect,
              isSelected,
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.glassShell,
                  borderRadius: BorderRadius.circular(10),
                  image: hasArt
                      ? DecorationImage(
                          image: imageProvider!,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasArt
                    ? null
                    : const Icon(
                        Icons.audio_file_outlined,
                        size: 20,
                        color: AppColors.glassTextMuted,
                      ),
              ),
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
                      fontWeight: isPlaying ? FontWeight.w800 : FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: const TextStyle(
                      color: AppColors.glassTextMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isPlaying && !isMultiSelect)
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: _AnimatedPlayingIndicator(),
              )
            else if (!isMultiSelect)
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.glassTextMuted,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedPlayingIndicator extends StatefulWidget {
  const _AnimatedPlayingIndicator();

  @override
  State<_AnimatedPlayingIndicator> createState() =>
      _AnimatedPlayingIndicatorState();
}

class _AnimatedPlayingIndicatorState extends State<_AnimatedPlayingIndicator>
    with SingleTickerProviderStateMixin {
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
