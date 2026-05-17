import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  String? _vaultPath;

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
}