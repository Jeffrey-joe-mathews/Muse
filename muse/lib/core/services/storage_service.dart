import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  String? _vaultPath;

  final _uuid = const Uuid();

  Future<void> initVault() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.audio,
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      final rootDir = Directory('/storage/emulated/0/Music');
      
      if (!await rootDir.exists()) {
        await rootDir.create(recursive: true);
      }

      final vaultDir = Directory('${rootDir.path}/MuseVault');
      
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
        debugPrint("SYSTEM: Public Vault physically created at ${vaultDir.path}");
      } else {
        debugPrint("SYSTEM: Public Vault located at ${vaultDir.path}");
      }
      
      _vaultPath = vaultDir.path;


    } catch (e) {
      debugPrint("SYSTEM ERROR: Failed to breach public storage - $e");
    }
  }

  String get vaultPath {
    if (_vaultPath == null) {
      return '/storage/emulated/0/Music/MuseVault';
    }
    return _vaultPath!;
  }

  String getOrGenerateFolderId(Directory dir) {
    try {
      final markerFile = File('${dir.path}/.muse_id');
      
      if (markerFile.existsSync()) {
        return markerFile.readAsStringSync().trim();
      } else {
        // Brand new folder detected! Generate ID and inject the hidden file.
        final newId = _uuid.v4();
        markerFile.writeAsStringSync(newId);
        
        debugPrint("SYSTEM: Injected new .muse_id [$newId] into ${dir.path}");
        return newId;
      }
    } catch (e) {
      debugPrint("SYSTEM ERROR: Failed to process .muse_id in ${dir.path} - $e");
      // Fallback: If we absolutely cannot write to the folder (e.g., weird Android permissions),
      // we generate a deterministic hash of the path so the app doesn't crash.
      return _uuid.v5(Uuid.NAMESPACE_URL, dir.path); 
    }
  }
}