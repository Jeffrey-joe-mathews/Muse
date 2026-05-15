import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class MetadataService {
  
  Future<Map<String, dynamic>> extractLocalMetadata(String filePath) async {
    debugPrint("=== METADATA X-RAY ===");
    debugPrint("1. Received File Path: $filePath");
    
    try {
      // Use the native Android/iOS media retriever
      final metadata = await MetadataRetriever.fromFile(File(filePath));
      debugPrint("2. Metadata read successfully!");

      String title = metadata.trackName ?? filePath.split('/').last.split('.').first;
      String artist = metadata.trackArtistNames?.first ?? metadata.albumArtistName ?? "Unknown Artist";
      int durationMs = metadata.trackDuration ?? 0;
      String albumArtPath = "";

      debugPrint("3. Extracted -> Title: $title | Artist: $artist");

      // Extract artwork if it exists
      if (metadata.albumArt != null && metadata.albumArt!.isNotEmpty) {
        debugPrint("4. Found Artwork bytes! Size: ${metadata.albumArt!.length}");
        albumArtPath = await _cacheArtwork(metadata.albumArt!, artist, title);
        debugPrint("5. Artwork saved successfully to: $albumArtPath");
      } else {
        debugPrint("4. NO ARTWORK found inside this MP3 file.");
      }

      debugPrint("======================");

      return {
        'title': title,
        'artist': artist,
        'duration': Duration(milliseconds: durationMs),
        'albumArt': albumArtPath,
      };
    } catch (e) {
      debugPrint("!!! METADATA CRASH: $e !!!");
      
      return {
        'title': filePath.split('/').last.split('.').first,
        'artist': "Unknown Artist",
        'duration': Duration.zero,
        'albumArt': "",
      };
    }
  }

  Future<String> _cacheArtwork(Uint8List bytes, String artist, String title) async {
    final dir = await getApplicationDocumentsDirectory();
    final coversDir = Directory('${dir.path}/covers');
    
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    final hash = sha1.convert(utf8.encode('$artist$title')).toString();
    final file = File('${coversDir.path}/$hash.jpg');

    if (!await file.exists()) {
      await file.writeAsBytes(bytes);
    }

    return file.path;
  }
}