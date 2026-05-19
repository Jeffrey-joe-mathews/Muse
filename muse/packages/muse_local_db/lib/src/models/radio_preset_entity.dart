import 'package:isar/isar.dart';

part 'radio_preset_entity.g.dart';

@collection
class RadioPresetEntity {
  Id slotIndex = Isar.autoIncrement; 
  
  late String stationId;
  late String title;
  late String artist;
  late String albumArt;
  late String audioURL;
  late String source;
}