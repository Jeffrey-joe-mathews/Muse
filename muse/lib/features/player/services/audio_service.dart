import 'package:just_audio/just_audio.dart';

class AudioService {

  // SINGLETON
  static final AudioService _instance =
      AudioService._internal();

  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  // PLAY SONG
  Future<void> play(String url) async {
    await _player.setUrl(url);
    await _player.play();
  }

  // PAUSE
  Future<void> pause() async {
    await _player.pause();
  }

  // RESUME
  Future<void> resume() async {
    await _player.play();
  }

  // SEEK
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // STOP
  Future<void> stop() async {
    await _player.stop();
  }

  // DISPOSE
  Future<void> dispose() async {
    await _player.dispose();
  }

  // STREAMS

  Stream<Duration?> get durationStream =>
      _player.durationStream;

  Stream<Duration> get positionStream =>
      _player.positionStream;

  Stream<PlayerState> get playerStateStream =>
      _player.playerStateStream;
}