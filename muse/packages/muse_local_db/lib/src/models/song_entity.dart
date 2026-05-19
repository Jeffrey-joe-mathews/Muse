import 'package:isar/isar.dart';

part 'song_entity.g.dart';

@collection
class SongEntity {
  Id id = Isar.autoIncrement;
  late String title;
  late String filePath;
  String artist = "Unknown Artist";
  String albumArtPath = "";
  String source = "local"; 
  String? streamUrl; 
  String? networkId;
  bool isSavedToVault = false;
  DateTime? lastPlayed;
}