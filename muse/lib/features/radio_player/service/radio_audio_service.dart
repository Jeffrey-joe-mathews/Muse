import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../../models/song.dart';

class RadioAudioService {
 final AudioPlayer _radioPlayer = AudioPlayer();
  AudioPlayer get player => _radioPlayer;

 // PLAY LIVE STREAM
  Future<void> playRadioStream(Song station) async {
    try {
      final mediaItem = MediaItem(
        id: station.id,
        title: station.title,
        artist: station.artist,
        artUri: station.albumArt.isNotEmpty ? Uri.parse(station.albumArt) : null,
      );

      final audioSource = AudioSource.uri(
        Uri.parse(station.audioURL),
        tag: mediaItem,
      );

      await _radioPlayer.setAudioSource(audioSource);
      await _radioPlayer.play();
      
    } catch (e) {
      debugPrint("📻 Radio Engine Exception: $e");
    }
  } 

  Future<void> stop() async {
    await _radioPlayer.stop();
  }

  Future<void> dispose() async {
    await _radioPlayer.dispose();
  }

  Stream<PlayerState> get playerStateStream => _radioPlayer.playerStateStream;
}