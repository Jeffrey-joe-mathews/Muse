import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'; 
import 'package:muse/models/song.dart';
import 'package:muse/providers/archive/archive_provider.dart';
import 'package:muse/providers/audius/audius_provider.dart';
import 'package:muse/providers/base/music_provider.dart';
import 'package:muse/providers/jamendo/jamendo_provider.dart';
import 'package:muse/providers/local/local_provider.dart';
import 'package:muse/providers/soundcloud/soundcloud_provider.dart';
import 'package:muse/providers/youtube/youtube_provider.dart'; 

class AudioService {

  // SINGLETON
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  final Map<SongSource, MusicProvider> _providers = {
    SongSource.local: LocalMusicProvider(),
    SongSource.youtube: YouTubeProvider(),
    SongSource.soundcloud: SoundCloudProvider(),
    SongSource.jamendo: JamendoProvider(),
    SongSource.audius: AudiusProvider(),
    SongSource.archive: ArchiveProvider(),
  };

  // PLAY SONG (Upgraded to handle Local Files & Background OS)
  Future<void> play(Song song) async {
    String finalUrl = song.audioURL;

    // THE FIX: Only fetch a fresh URL if it is a network stream!
    if (song.source != SongSource.local) {
      final provider = _providers[song.source];
      if (provider != null) {
        final freshUrl = await provider.getStreamUrl(song.id);
        if (freshUrl != null && freshUrl.isNotEmpty) {
          finalUrl = freshUrl;
        }
      }
    }
    
    // THE SAFEGUARD: Stop if the extraction failed completely
    if (finalUrl.isEmpty) {
      debugPrint("Playback Aborted: URL is empty.");
      return;
    }

    final mediaItem = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: song.albumArt.isNotEmpty 
          ? (song.albumArt.startsWith('http') ? Uri.parse(song.albumArt) : Uri.file(song.albumArt)) 
          : null,
    );

    final audioSource = AudioSource.uri(
      finalUrl.startsWith('http') ? Uri.parse(finalUrl) : Uri.file(finalUrl), 
      tag: mediaItem,          
    );

    await _player.setAudioSource(audioSource);
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
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
}