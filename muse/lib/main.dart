import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:muse/app.dart';
import 'package:muse/core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the background audio OS
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.muse.app.channel.audio',
    androidNotificationChannelName: 'Muse Playback',
    androidNotificationOngoing: true,
  );

  await StorageService().initVault();

  runApp(
    const ProviderScope(
      child: MuseApp(),
    ),
  );
}

class MuseApp extends StatelessWidget {

  const MuseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MyApp();
  }
}