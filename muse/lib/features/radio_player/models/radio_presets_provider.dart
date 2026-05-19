import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse/models/song.dart';
import 'package:muse_local_db/muse_local_db.dart';

// Create a provider for your DatabaseService so the Notifier can access it
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final radioPresetsProvider = StateNotifierProvider<RadioPresetsNotifier, List<Song?>>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  return RadioPresetsNotifier(dbService);
});

class RadioPresetsNotifier extends StateNotifier<List<Song?>> {
  final DatabaseService _dbService;

  RadioPresetsNotifier(this._dbService) : super(List.generate(6, (index) => null)) {
    _loadPresetsFromDatabase();
  }

  Future<void> _loadPresetsFromDatabase() async {
    final savedEntities = await _dbService.getAllRadioPresets();

    if (savedEntities.isEmpty) {
      // FIRST BOOT: No presets saved yet. Load defaults.
      final defaultStations = [
        const Song(id: "def_1", title: "Lofi Chill", artist: "Live FM", albumArt: "", audioURL: "https://stream.ecm.haus/lofi", source: SongSource.archive),
        const Song(id: "def_2", title: "Synthwave Night", artist: "Live FM", albumArt: "", audioURL: "https://radio.streemlion.com:3320/stream", source: SongSource.archive),
        const Song(id: "def_3", title: "SomaFM Groove", artist: "Live FM", albumArt: "", audioURL: "https://ice1.somafm.com/groovesalad-128-mp3", source: SongSource.archive),
        const Song(
          id: "def_4", 
          title: "SomaFM Secret Agent - The Soundtrack For Your Stylish, Mysterious, And Dangerous Life", 
          artist: "Live FM", 
          albumArt: "", 
          audioURL: "https://ice1.somafm.com/secretagent-128-mp3", 
          source: SongSource.archive
        ), 
        null, 
        null,
      ];
      
      state = defaultStations;

      // Silently burn these defaults into the Isar database
      for (int i = 0; i < defaultStations.length; i++) {
        if (defaultStations[i] != null) {
          _saveToDatabase(i, defaultStations[i]!);
        }
      }
    } else {
      // NORMAL BOOT: Map the database entities back into Flutter Song models
      List<Song?> loadedPresets = List.generate(6, (index) => null);
      
      for (var entity in savedEntities) {
        if (entity.slotIndex >= 0 && entity.slotIndex < 6) {
          loadedPresets[entity.slotIndex] = Song(
            id: entity.stationId,
            title: entity.title,
            artist: entity.artist,
            albumArt: entity.albumArt,
            audioURL: entity.audioURL,
            source: SongSource.values.firstWhere((e) => e.name == entity.source, orElse: () => SongSource.archive),
          );
        }
      }
      state = loadedPresets;
    }
  }

  void assignStationToSlot(int index, Song station) {
    if (index < 0 || index >= 6) return;

    // 1. Update the UI State immediately (so it feels instant)
    final updatedList = List<Song?>.from(state);
    updatedList[index] = station;
    state = updatedList;

    // 2. Burn it into the Isar Database persistently
    _saveToDatabase(index, station);
  }

  Future<void> _saveToDatabase(int index, Song station) async {
    final entity = RadioPresetEntity()
      ..stationId = station.id
      ..title = station.title
      ..artist = station.artist
      ..albumArt = station.albumArt
      ..audioURL = station.audioURL
      ..source = station.source.name;

    await _dbService.saveRadioPreset(index, entity);
  }
}