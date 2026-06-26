import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muse/providers/archive/archive_provider.dart';
import 'package:muse/providers/audius/audius_provider.dart';
import 'package:muse/providers/base/music_provider.dart';
import 'package:muse/providers/jamendo/jamendo_provider.dart';
import 'package:muse/providers/local/local_provider.dart';
import 'package:muse/providers/radio/radio_provider.dart';
import 'package:muse/providers/soundcloud/soundcloud_provider.dart';

const bool isPlayStoreMode = true;

final activeProviderState = Provider<List<MusicProvider>>((ref) {
  if (isPlayStoreMode) {
    return [
      RadioProvider(),
      LocalMusicProvider()
    ];
  }
  else {
    return [
      RadioProvider(),
      LocalMusicProvider(),
      SoundCloudProvider(),
      JamendoProvider(),
      AudiusProvider(),
      ArchiveProvider(),
    ];
  }
});