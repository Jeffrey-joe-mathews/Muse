import 'package:flutter/material.dart';
import 'package:muse/core/theme/app_theme.dart';
import 'package:muse/features/search/pages/search_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SearchPage(),
    );
  }
}