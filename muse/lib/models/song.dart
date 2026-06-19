enum SongSource {
  local, 
  archive,
  youtube,
  jamendo,
  soundcloud,
  audius,
  radio,
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String albumArt;
  final String audioURL;
  final Duration? duration;
  final SongSource source;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArt,
    required this.audioURL,
    required this.source,
    this.duration
  });


  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArt,
    String? audioUrl,
    Duration? duration,
    SongSource? source,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArt: albumArt ?? this.albumArt,
      audioURL: audioUrl ?? this.audioURL,
      duration: duration ?? this.duration,
      source: source ?? this.source,
    );
  }

}