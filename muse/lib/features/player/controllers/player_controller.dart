// lib/features/player/controllers/player_controller.dart
import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muse/features/player/services/audio_service.dart';
import 'package:muse/models/song.dart';

// GLOBAL PROVIDER
final playerControllerProvider =
    StateNotifierProvider<PlayerController, PlayerStateModel>(
  (ref) => PlayerController(),
);

// PLAYER STATE MODEL
class PlayerStateModel {
  final Song? currentSong;
  final List<Song> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;

  const PlayerStateModel({
    this.currentSong,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
  });

  PlayerStateModel copyWith({
    Song? currentSong,
    List<Song>? queue,
    int? currentIndex,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
  }) {
    return PlayerStateModel(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}

// CONTROLLER
class PlayerController extends StateNotifier<PlayerStateModel> {
  PlayerController() : super(const PlayerStateModel()) {
    _listenToPlayerStreams();
  }

  final AudioService _audioService = AudioService();

  // PLAY SONG
  Future<void> playSong(Song song) async {
    state = state.copyWith(
      currentSong: song,
      isPlaying: true,
    );

    await _audioService.play(song);
  }

  Future<void> playQueue(List<Song> songs, int startIndex) async {
    final song = songs[startIndex];

    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      currentSong: song,
      isPlaying: true,
    );

    await _audioService.play(song);
  }

  // PAUSE / RESUME
  Future<void> pauseOrResume() async {
    if (state.isPlaying) {
      await _audioService.pause();
      state = state.copyWith(isPlaying: false);
    } else {
      await _audioService.resume();
      state = state.copyWith(isPlaying: true);
    }
  }

  // SEEK
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> playNextSong() async {
    if (state.queue.isEmpty) return;

    final nextIndex = (state.currentIndex + 1) % state.queue.length;
    final nextSong = state.queue[nextIndex];

    state = state.copyWith(
      currentSong: nextSong,
      currentIndex: nextIndex,
      isPlaying: true,
    );

    await _audioService.play(nextSong);
  }

  Future<void> playPreviousSong() async {
    if (state.queue.isEmpty) return;

    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = state.queue.length - 1;
    }

    final prevSong = state.queue[prevIndex];

    state = state.copyWith(
      currentSong: prevSong,
      currentIndex: prevIndex,
      isPlaying: true,
    );

    await _audioService.play(prevSong);
  }

  // PLAYER STREAM LISTENERS
  void _listenToPlayerStreams() {
    _audioService.positionStream.listen((position) {
      state = state.copyWith(currentPosition: position);
    });

    _audioService.durationStream.listen((duration) {
      state = state.copyWith(totalDuration: duration ?? Duration.zero);
    });

    _audioService.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      state = state.copyWith(isPlaying: playing);
      
      if (playerState.processingState == ProcessingState.completed) {
        playNextSong();
      }
    });
  }

  // CLEANUP
  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}