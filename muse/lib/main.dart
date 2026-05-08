import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muse/app.dart';

void main() {

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