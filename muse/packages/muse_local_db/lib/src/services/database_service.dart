import 'package:isar/isar.dart';
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
      return await Isar.open(
        [SongEntitySchema],
        directory: dir.path,
      );
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
}