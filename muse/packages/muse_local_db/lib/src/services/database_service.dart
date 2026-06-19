import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// schema path
import 'package:muse_local_db/src/models/song_entity.dart';
import 'package:muse_local_db/src/models/radio_preset_entity.dart';
import 'package:muse_local_db/src/models/folder_entity.dart';

class DatabaseService {
  late Future<Isar> db;

  DatabaseService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final isar = await Isar.open(
        [
          SongEntitySchema,
          FolderEntitySchema,
          RadioPresetEntitySchema
        ],
        directory: dir.path,
      );
      
      _runGarbageCollector(isar);
      
      return isar;
    }
    return Future.value(Isar.getInstance());
  }

// SONG METHODS

  Future<void> saveSong(SongEntity song, {FolderEntity? parentFolder}) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.songEntitys.put(song);
      if (parentFolder != null) {
        song.parentFolder.value = parentFolder;
        await song.parentFolder.save();
      }
    });
  }

  Future<List<SongEntity>> getAllSongs() async {
    final isar = await db;
    return await isar.songEntitys.where().findAll();
  }

  Future<SongEntity?> getSongByPath(String path) async {
    final isar = await db;
    return await isar.songEntitys.filter().filePathEqualTo(path).findFirst();
  }

  Future<void> deleteSongByPath(List<String> paths) async {
    final isar = await db;
    await isar.writeTxn(() async {
      for (String path in paths) {
        final ghost = await isar.songEntitys.filter().filePathEqualTo(path).findFirst();
        if (ghost != null) {
          await isar.songEntitys.delete(ghost.id);
        }
      }
    });
  } 

  Future<List<SongEntity>> searchSongs(String query) async {
    final isar = await db;
    return await isar.songEntitys
      .filter()
      .group((q) => q
        .titleContains(query, caseSensitive: false)
        .or()
        .artistContains(query, caseSensitive: false))
      .limit(50)
      .findAll();
  }

  Future<List<SongEntity>> searchLocalSongs(String query) async {
    final isar = await db;
    return await isar.songEntitys
      .filter()
      .sourceContains("local")
      .and()
      .group((q) => q
        .titleContains(query, caseSensitive: false)
        .or()
        .artistContains(query, caseSensitive: false))
      .limit(50)
      .findAll();
  }

// FOLDER METHODS

  Future<void> saveFolder(FolderEntity folder, {FolderEntity? parentFolder}) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.folderEntitys.put(folder);
      if (parentFolder != null) {
        folder.parentFolder.value = parentFolder;
        await  folder.parentFolder.save();
      }
    });
  }

  Future<FolderEntity?> getFolderById(String FodlerId) async {
    final isar = await db;
    return await isar.folderEntitys.filter().folderIdEqualTo(FodlerId).findFirst();
  }

  Future<List<FolderEntity>> getAllFolders() async {
    final isar = await db;
    return await isar.folderEntitys.where().findAll();
  }

  Future<void> deleteFolderById(String folderId) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final folder = await isar.folderEntitys.filter().folderIdEqualTo(folderId).findFirst();
      if (folder != null) {
        await isar.folderEntitys.delete(folder.id);
      }
    });
  }




  Future<List<SongEntity>> getRecentHistory() async {
    final isar = await db;
    return await isar.songEntitys
        .filter()
        .lastPlayedIsNotNull()
        .sortByLastPlayedDesc()
        .limit(20)
        .findAll();
  }

  Future<void> updateLastPlayed(String path) async {
    final isar = await db;
    final song = await getSongByPath(path);
    
    if (song != null) {
      song.lastPlayed = DateTime.now();
      await isar.writeTxn(() async {
        await isar.songEntitys.put(song);
      });
    }
  }

  Future<void> removeFromHistory(String path) async {
    final isar = await db;
    final song = await getSongByPath(path);
    
    if (song != null) {
      song.lastPlayed = null;
      await isar.writeTxn(() async {
        await isar.songEntitys.put(song);
      });
    }
  }

  Future<void> _runGarbageCollector(Isar isar) async {
    // Define the TTL (Time To Live). 
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    await isar.writeTxn(() async {
      final trashCount = await isar.songEntitys
          .filter()
          .isSavedToVaultEqualTo(false)
          .and()
          .lastPlayedLessThan(sevenDaysAgo)
          .deleteAll();

      if (trashCount > 0) {
        debugPrint("SYSTEM: Garbage Collector incinerated $trashCount stale searches.");
      }
    });
  }

  Future<void> saveRadioPreset(int index, RadioPresetEntity preset) async {
    final isar = await db;
    preset.slotIndex = index;
    await isar.writeTxn(() async {
      await isar.radioPresetEntitys.put(preset);
    });
  }

  Future<List<RadioPresetEntity>> getAllRadioPresets() async {
    final isar = await db;
    return await isar.radioPresetEntitys.where().findAll(); 
  }
}