import 'package:isar/isar.dart';
import 'package:muse_local_db/src/models/folder_entity.dart';

part 'song_entity.g.dart';

@collection
class SongEntity {
  Id id = Isar.autoIncrement;

  late String title;

  @Index(unique: true, replace: true)
  late String filePath;

  String artist = "Unknown Artist";
  String albumArtPath = "";
  String source = "local"; 
  int? durationMs;
  String? streamUrl; 
  String? networkId;
  
  bool isSavedToVault = false;
  DateTime? lastPlayed;

  // similar to an edge which connects two vertices eg: Song <==> Folder, Folder <==> Folder
  final parentFolder = IsarLink<FolderEntity>();
}