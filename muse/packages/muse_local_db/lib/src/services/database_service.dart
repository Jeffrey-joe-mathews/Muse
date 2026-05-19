import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:muse_local_db/src/models/radio_preset_entity.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song_entity.dart';

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
          RadioPresetEntitySchema
        ],
        directory: dir.path,
      );
      
      _runGarbageCollector(isar);
      
      return isar;
    }
    return Future.value(Isar.getInstance());
  }

  Future<void> saveSong(SongEntity song) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.songEntitys.put(song);
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
    // Define the TTL (Time To Live). Adjust this to whatever you want.
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