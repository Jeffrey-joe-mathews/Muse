import 'package:isar/isar.dart';

part 'folder_entity.g.dart';

@collection

class FolderEntity {
  Id id  = Isar.autoIncrement;

  // This matches the UUID written inside the physical `.muse_id` file on the Android drive.
  // If the folder moves, this ID stays the same, preserving all stream/metadata links.
  @Index(unique:true, replace:true)
  late String folderId;

  late String name;
  late String path;

  bool isPhysical = true;
  DateTime createdAt = DateTime.now();

  final parentFolder = IsarLink<FolderEntity>();

  @Backlink(to: 'parentFolder')
  final subDirectories = IsarLinks<FolderEntity>();
}