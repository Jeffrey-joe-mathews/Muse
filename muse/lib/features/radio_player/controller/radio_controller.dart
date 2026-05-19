import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse/features/player/controllers/player_controller.dart';
import 'package:muse/features/radio_player/service/radio_audio_service.dart';
import '../../../../models/song.dart';

final radioControllerProvider = StateNotifierProvider<RadioController, RadioStateModel>((ref) {
  return RadioController(ref);
});

class RadioStateModel {
  final Song? currentStation;
  final bool isPlaying;

  const RadioStateModel({
    this.currentStation,
    this.isPlaying = false,
  });

  RadioStateModel copyWith({
    Song? currentStation,
    bool? isPlaying,
  }) {
    return RadioStateModel(
      currentStation: currentStation ?? this.currentStation,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

class RadioController extends StateNotifier<RadioStateModel> {
  final Ref _ref;
  final RadioAudioService _radioService = RadioAudioService();

  RadioController(this._ref) : super(const RadioStateModel()) {
    _listenToRadioStreams();
  }

  Future<void> tuneToStation(Song station) async {
    await _ref.read(playerControllerProvider.notifier).stopAndClear(); 
    state = state.copyWith(currentStation: station, isPlaying: true);
    await _radioService.playRadioStream(station);
  }

  Future<void> stopRadio() async {
    await _radioService.stop();
    state = state.copyWith(isPlaying: false);
  }

  void _listenToRadioStreams() {
    _radioService.playerStateStream.listen((playerState) {
      state = state.copyWith(isPlaying: playerState.playing);
    });
  }

  Future<void> setVolume(double volume) async {
    await _radioService.player.setVolume(volume);
  }

  @override
  void dispose() {
    _radioService.dispose();
    super.dispose();
  }
}