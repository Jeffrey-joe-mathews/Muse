// TODO
// - folder addition
// - song addition
// - sync vault
// - selection
// - creation of folder



// TwT
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse_local_db/muse_local_db.dart';
import 'package:path_provider/path_provider.dart';
import '../../../models/song.dart'; 
import '../../../providers/local/local_provider.dart'; 
import '../../../core/services/storage_service.dart';

class SyncLog {
  int foldersAdded = 0;
  int foldersRemoved = 0;
  int tracksAdded = 0;
  int tracksRemoved = 0;

  bool get hasChanges => 
      foldersAdded > 0 || foldersRemoved > 0 || tracksAdded > 0 || tracksRemoved > 0;

  String get summary => 
      "Sync Complete: +$tracksAdded tracks, -$tracksRemoved tracks | +$foldersAdded folders, -$foldersRemoved folders.";
}

final databaseProvider = Provider((ref) => DatabaseService());

final collectionControllerProvider =
    StateNotifierProvider<CollectionController, AsyncValue<List<Song>>>((ref) {
  return CollectionController(ref.read(databaseProvider));
});

class CollectionController extends StateNotifier<AsyncValue<List<Song>>> {
  final DatabaseService _db;
  final LocalMusicProvider _localProvider = LocalMusicProvider();

  CollectionController(this._db) : super(const AsyncValue.loading()) {
    _init(); 
  }

  Future<void> _init() async {
    await loadSongs();
    final logs = await syncVault();
    if (logs.hasChanges) {
      debugPrint("⚠️ SYSTEM : ${logs.summary}");
    }
  }

  Future<SyncLog> syncVault() async {
    final logs = SyncLog();
    final vaultPath = StorageService().vaultPath;
    final vaultDirectory = Directory(vaultPath);
    if (!vaultDirectory.existsSync()) return logs;

    // Enforce folder only at the base folder MuseVault
    final rootItems = vaultDirectory.listSync(recursive: false);
    final strayDirectory = Directory('$vaultPath/Stray');

    // Clean stray files files at root directory
    for (var item in rootItems) {
      if (item is File) {
        final ext = item.path.split('.').last.toLowerCase();
        if (['mp3', 'flac', 'wav', 'm4a', 'aac', 'ogg', 'mpga'].contains(ext)) {
          if (!strayDirectory.existsSync()) strayDirectory.createSync();
          final fileName = item.path.split('/').last;
          item.renameSync('${strayDirectory.path}/$fileName');
          debugPrint("⚠️ TRIAGE : Swept stray/loose file into STRAY directory");
        }
      }
    }

    final List<Directory> physicalDirectories = vaultDirectory.listSync(recursive: true).whereType<Directory>().toList();
    physicalDirectories.add(vaultDirectory);
    // Now we have a list of all directories and subdirectories in MuseVault inclusing itself extracted recursively

    final Set<String> activeFolderIds = {};
    final Map<String, FolderEntity> folderEntityCaxhe = {};

    // we sync all existing physicalDirectories with the ones we have in the db (handles renaming, moving, etc)

    for (var directory in physicalDirectories) {
      final String folderId = StorageService().getOrGenerateFolderId(directory);
      activeFolderIds.add(folderId);

      FolderEntity? entity = await _db.getFolderById(folderId);

      if (entity == null) {
        entity = FolderEntity()
        ..folderId = folderId
        ..createdAt = DateTime.now();
        logs.foldersAdded++;
      }

      // Always update path/name in case it was physically moved/renamed
      entity.name = directory.path == vaultPath ? "MuseVault" : directory.path.split('/').last;
      entity.path = directory.path;
      entity.isPhysical = true;

      await _db.saveFolder(entity);
      folderEntityCaxhe[directory.path] = entity;
    }

    // establishing the adjacency list (pseudo-dynamic graph)
    for (var node in physicalDirectories) {
      if (node.path == vaultPath) continue; // ROOT has no parent, literally adam fr

      final childNode = folderEntityCaxhe[node.path];
      final parentNode = folderEntityCaxhe[node.parent.path];

      if (childNode != null && parentNode != null) {
        await _db.saveFolder(childNode, parentFolder: parentNode);
      }
    }

    // GHOSTBUSTERS
    final allDBFolders = await _db.getAllFolders();
    for (var folder in allDBFolders) {
      if (folder.isPhysical && !activeFolderIds.contains(folder.folderId)) {
        await _db.deleteFolderById(folder.folderId);
        logs.foldersRemoved++;
      }
    }

    // No Alarms and No Discrete Math, No Alarms and No Discrete Math, Please
    final physicalFiles = vaultDirectory.listSync(recursive: true)
      .whereType<File>()
      .where((f) => ['mp3', 'flac', 'wav', 'm4a', 'aac', 'ogg', 'mpga'].contains(f.path.split('.').last.toLowerCase()))
      .toList();

    final Set<String> physicalPaths = physicalFiles.map((f) => f.path).toSet();       // Set P

    final dbSongs = await _db.getAllSongs();
    final Set<String> localDbPaths = dbSongs
      .where((s) => s.source =="local")
      .map((s) => s.filePath)
      .toSet();                                                                       // Set L

    final filesToAdd = physicalPaths.difference(localDbPaths);        // Added = P - L
    final filesToRemove = localDbPaths.difference(physicalPaths);     // Rewmoved = L - P

    // File Sync after Folder Sync to establish proper structure and coherence
    if (filesToRemove.isNotEmpty) {
      debugPrint("GHOST SYNC : Removing ${filesToRemove.length} orphaned songs");
      await _db.deleteSongByPath(filesToRemove.toList());
      logs.tracksRemoved += filesToRemove.length;
    }

    if (filesToAdd.isNotEmpty) {
      debugPrint("NEW SYNC : Found ${filesToAdd.length} unindexed physical files");
      for (var filePath in filesToAdd) {
        final parentDirectoryPath = Directory(filePath).parent.path;
        final parentFolder = folderEntityCaxhe[parentDirectoryPath];

        if (parentFolder != null) {
          await _addSongToGraph(filePath, parentFolder);
          logs.tracksAdded++;
        }
      }
    }

    if (logs.hasChanges) await loadSongs();
    return logs;
  }

  Future<void> loadSongs() async {
    try {
      final entities = await _db.getAllSongs();

      SongSource parseSource(String src) {
        switch (src) {
          case 'soundcloud': return SongSource.soundcloud;
          case 'jamendo': return SongSource.jamendo;
          case 'youtube': return SongSource.youtube;
          case 'audius': return SongSource.audius;
          case 'archive': return SongSource.archive;
          case 'radio': return SongSource.radio;
          default: return SongSource.local;
        }
      }
      
      final songs = entities.where((e) => e.isSavedToVault == true).map((entity) {
        return Song(
          id: entity.networkId ?? entity.id.toString(),
          title: entity.title,
          artist: entity.artist, 
          duration: entity.durationMs != null ? Duration(milliseconds: entity.durationMs!) : null,
          albumArt: entity.albumArtPath, 
          audioURL: (entity.streamUrl != null && entity.streamUrl!.isNotEmpty) 
              ? entity.streamUrl! 
              : entity.filePath,
          source: parseSource(entity.source),
        );
      }).toList();

      state = AsyncValue.data(songs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _addSongToGraph(String path, FolderEntity parentFolder) async {
    final Song normalizedSong = await _localProvider.normalizeTrack(path);

    final newSong = SongEntity()
      ..title = normalizedSong.title
      ..artist = normalizedSong.artist
      ..albumArtPath = normalizedSong.albumArt
      ..filePath = normalizedSong.audioURL
      ..source = 'local'
      ..durationMs = normalizedSong.duration?.inMilliseconds
      ..isSavedToVault = true
      ..lastPlayed = DateTime.now();
    
    await _db.saveSong(newSong, parentFolder: parentFolder);
  }

  Future<void> addSong(String path) async {
    final parentDirPath = Directory(path).parent.path;
    final parentId = StorageService().getOrGenerateFolderId(Directory(parentDirPath));
    
    FolderEntity? folder = await _db.getFolderById(parentId);
    if (folder == null) {
      // If UI adds a song in a folder that doesnt exist , Autoheal.
      await syncVault();
      return;
    }
    
    await _addSongToGraph(path, folder);
    await loadSongs(); 
  }

  Future<String?> createZipArchive(
    Set<String> selectedPaths, {
    void Function(int count, int total)? onProgress,
  }) async {
    try {
      debugPrint("\n=== 📦 ZIP COMPILATION INITIATED ===");
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}/Muse_Export_${DateTime.now().millisecondsSinceEpoch}.zip';
      
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      List<Map<String, dynamic>> packTasks = [];

      for (var path in selectedPaths) {
        if (path == "Cloud Streams" || path.startsWith('stream://')) {
          debugPrint("🚫 SKIPPING NETWORK STREAM: $path");
          continue;
        }

        final entityType = FileSystemEntity.typeSync(path);

        if (entityType == FileSystemEntityType.file) {
          final file = File(path);
          final fileName = file.path.split('/').last;
          if (fileName == '.muse_id') continue; 
          
          packTasks.add({'file': file, 'zipPath': fileName});
          
        } else if (entityType == FileSystemEntityType.directory) {
          final dir = Directory(path);
          final dirName = dir.path.split('/').last;
          
          final contents = dir.listSync(recursive: true).whereType<File>();
          
          for (var item in contents) {
            final fileName = item.path.split('/').last;
            if (fileName == '.muse_id') continue; // 🚫 DROP HIDDEN FILES
            
            final relativePath = '$dirName/${item.path.substring(dir.path.length + 1)}';
            packTasks.add({'file': item, 'zipPath': relativePath});
          }
        }
      }

      final totalFiles = packTasks.length;
      for (int i = 0; i < totalFiles; i++) {
        final file = packTasks[i]['file'] as File;
        final targetZipPath = packTasks[i]['zipPath'] as String;

        debugPrint("   ↳ 🎵 Packing File: $targetZipPath");
        
        final bytes = file.readAsBytesSync();
        encoder.addArchiveFile(ArchiveFile(targetZipPath, bytes.length, bytes));

        onProgress?.call(i + 1, totalFiles);
        await Future.delayed(const Duration(milliseconds: 5)); 
      }

      encoder.close();
      final finalZip = File(zipPath);
      final sizeMb = (finalZip.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
      
      debugPrint("✅ COMPILATION SUCCESS: Generated $sizeMb MB archive at $zipPath");
      debugPrint("=====================================\n");
      
      return zipPath;
    } catch (e) {
      debugPrint("❌ ZIP COMPILATION FAILED: $e");
      return null;
    }
  }

  Future<void> deleteItems(Set<String> selectedPaths) async {
    try {
      debugPrint("\n=== 🗑️ DELETION INITIATED ===");
      bool physicalChanges = false;
      List<String> streamIdsToRemove = [];

      for (var path in selectedPaths) {
        // Prevent deleting the root virtual folder
        if (path == "Cloud Streams") {
          debugPrint("🚫 SKIPPING: Cannot delete the root Cloud Streams folder.");
          continue;
        }

        // Handle Virtual/Network Streams
        if (path.startsWith('stream://')) {
          streamIdsToRemove.add(path);
          debugPrint("   ↳ ☁️ Queued stream for removal: $path");
          continue;
        }

        // Handle Physical Files & Folders
        final entityType = FileSystemEntity.typeSync(path);

        if (entityType == FileSystemEntityType.file) {
          final file = File(path);
          if (file.existsSync()) {
            file.deleteSync();
            physicalChanges = true;
            debugPrint("   ↳ 🎵 Deleted File: $path");
          }
        } else if (entityType == FileSystemEntityType.directory) {
          final dir = Directory(path);
          if (dir.existsSync()) {
            dir.deleteSync(recursive: true); // recursive: true deletes all contents inside
            physicalChanges = true;
            debugPrint("   ↳ 📁 Deleted Directory: $path");
          }
        }
      }

      // 1. Clean up network streams directly from the DB
      if (streamIdsToRemove.isNotEmpty) {
        await _db.deleteSongByPath(streamIdsToRemove);
        debugPrint("✅ Removed ${streamIdsToRemove.length} streams from vault.");
        // We need to reload songs explicitly since syncVault ignores network streams
        await loadSongs(); 
      }

      if (physicalChanges) {
        debugPrint("✅ Physical files wiped. Triggering syncVault to clean database...");
        await syncVault();
      }
      
      debugPrint("=====================================\n");
    } catch (e) {
      debugPrint("❌ DELETION FAILED: $e");
    }
  }

  // Saves a network stream to the Vault. 
  Future<void> addStreamShortcut(Song networkSong, {String? targetFolderId}) async {
    final dummyPath = "stream://${networkSong.source.name}/${networkSong.id}";
    
    FolderEntity? targetFolder;

    // Did the user choose a specific folder?
    if (targetFolderId != null) {
      targetFolder = await _db.getFolderById(targetFolderId);
    }
    
    // Use the physical Inbox directory
    if (targetFolder == null) {
      final vaultPath = StorageService().vaultPath;
      final inboxDir = Directory('$vaultPath/Inbox');
      
      // Ensure the physical folder actually exists on the drive
      if (!inboxDir.existsSync()) {
         inboxDir.createSync();
      }
      
      // Grab its UUID (this generates the .muse_id if it's a brand new Inbox)
      final inboxId = StorageService().getOrGenerateFolderId(inboxDir);
      
      targetFolder = await _db.getFolderById(inboxId);
      
      // If the database doesn't know about it yet
      if (targetFolder == null) {
        targetFolder = FolderEntity()
          ..folderId = inboxId
          ..name = "Inbox"
          ..path = inboxDir.path
          ..isPhysical = true;
        await _db.saveFolder(targetFolder);
      }
    }

    final newShortcut = SongEntity()
      ..title = networkSong.title
      ..artist = networkSong.artist
      ..albumArtPath = networkSong.albumArt
      ..filePath = dummyPath 
      ..streamUrl = networkSong.audioURL 
      ..source = networkSong.source.name 
      ..networkId = networkSong.id
      ..isSavedToVault = true 
      ..lastPlayed = DateTime.now();

    // Connect the stream to the physical folder
    await _db.saveSong(newShortcut, parentFolder: targetFolder);
    await loadSongs();
  }
}