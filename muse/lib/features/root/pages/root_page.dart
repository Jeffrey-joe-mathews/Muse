import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:muse/core/services/storage_service.dart';
import 'package:muse/core/theme/app_colors.dart';
import 'package:muse/features/library/controllers/collection_controller.dart';
import 'package:muse/features/radio_player/pages/radio_dashboard_page.dart';
import 'dart:ui';

// Pages
import '../../search/pages/search_page.dart'; 
import 'package:muse/features/player/widgets/orb.dart';
import 'package:muse/features/flow/pages/flow_page.dart';
import 'package:muse/features/library/pages/collection_page.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);
final vaultMenuProvider = StateProvider<bool>((ref) => false);
final multiSelectProvider = StateProvider<bool>((ref) => false);
final selectedItemsProvider = StateProvider<Set<String>>((ref) => {});

class RootPage extends ConsumerWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);
    final isMenuOpen = ref.watch(vaultMenuProvider);
    final isMultiSelect = ref.watch(multiSelectProvider);

    final pages = [
      const FlowPage(),
      const SearchPage(), 
      const CollectionPage(),
      const RadioDashboardPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: pages,
          ),

          AnimatedOpacity(
            duration: const Duration(milliseconds: 550),
            opacity: isMenuOpen ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !isMenuOpen,
              child: GestureDetector(
                onTap:() => ref.read(vaultMenuProvider.notifier).state = false,
                behavior: HitTestBehavior.opaque,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: AppColors.glassBlur,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isMenuOpen ? 0.0 : 1.0,
            child: isMenuOpen ? SizedBox(height: 20,) : MuseOrb(),
          ),
          const FloatingDock(),
        ],
      ),
    );
  }
}

class FloatingDock extends ConsumerWidget {
  const FloatingDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);
    final isMenuOpen = ref.watch(vaultMenuProvider);
    final isMultiSelect = ref.watch(multiSelectProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 32.0, right: 32.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMenuOpen ? 26 : 30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutExpo,
              height: isMenuOpen ? 350 : 65,
              decoration: BoxDecoration(
                color: (isMenuOpen || isMultiSelect) ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(isMenuOpen ? 24 : 30),
                border: Border.all(color: Colors.white.withOpacity((isMenuOpen || isMultiSelect) ? 0.09 : 0.05)),
              ),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 0),
                crossFadeState: isMenuOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                alignment: Alignment.bottomCenter,
                
                firstChild: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: !isMultiSelect 
                  ? 
                  SizedBox(
                    height: 65,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _DockItem(icon: Icons.waves_rounded, label: "Flow", index: 0, currentIndex: currentIndex, ref: ref),
                        _DockItem(icon: Icons.explore, label: "Explore", index: 1, currentIndex: currentIndex, ref: ref),
                        _DockItem(icon: Icons.library_music, label: "Library", index: 2, currentIndex: currentIndex, ref: ref),
                        _DockItem(icon: Icons.radio, label: "Radio", index: 3, currentIndex: currentIndex, ref: ref),
                      ],
                    ),
                  )
                  :
                  SizedBox(
                    key: const ValueKey('selection_dock'),
                    height: 65,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _DockAction( label: "Cancel",
                          icon: Icons.close_rounded,
                          onTap:() {
                            ref.read(multiSelectProvider.notifier).state = false;
                            ref.read(selectedItemsProvider.notifier).state = {};
                          },
                        ),
                        _DockAction( label: "Share",
                        icon: Icons.ios_share_rounded,
                        onTap: () {
                          // TODO
                        },
                        ),
                        _DockAction ( label: "Delete",
                        icon: Icons.delete_outline_rounded,
                        isDestructive: true,
                        onTap: () {
                          // TODO
                        },
                        )
                      ],
                    ),
                  )
                ),
                
                secondChild: SizedBox(
                  height: 360,
                  width: double.infinity,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
                          child: Text(
                            "VAULT OPERATIONS", 
                            style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)
                          ),
                        ),
                        _VaultMenuAction(
                          icon: Icons.audio_file_outlined, 
                          label: "Add Song", 
                          onTap: () async {
                            ref.read(vaultMenuProvider.notifier).state = false; // Auto-close menu
                            FilePickerResult? result = await FilePicker.pickFiles(type: FileType.audio);
                            if (result != null && result.files.isNotEmpty) {
                              final pickedPath = result.files.first.path;
                              final name = result.files.first.name;
                              if (pickedPath != null) {
                                final activeFolder = ref.read(activeFolderProvider);
                                final vaultPath = StorageService().vaultPath;
                                final targetDir = (activeFolder == null || activeFolder == "Cloud Streams") 
                                    ? Directory('$vaultPath/Inbox') 
                                    : Directory('$vaultPath/$activeFolder');
                                
                                if (!targetDir.existsSync()) targetDir.createSync();
                                final permanentFile = await File(pickedPath).copy('${targetDir.path}/$name');
                                ref.read(collectionControllerProvider.notifier).addSong(permanentFile.path);
                                File(pickedPath).delete().ignore();
                              }
                            }
                          }
                        ),

                        _VaultMenuAction(
                          icon: Icons.create_new_folder_outlined, 
                          label: "Create Folder", 
                          onTap: () async {
                            ref.read(vaultMenuProvider.notifier).state = false;
                            
                            String? folderName = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                String input = '';
                                return AlertDialog(
                                  backgroundColor: AppColors.hardwareSurface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: AppColors.glassBorder),
                                  ),
                                  title: const Text("CREATE FOLDER", style: TextStyle(color: AppColors.pureWhite, fontSize: 14, letterSpacing: 1.0, fontWeight: FontWeight.w800)),
                                  content: TextField(
                                    autofocus: true,
                                    style: const TextStyle(color: AppColors.pureWhite),
                                    decoration: InputDecoration(
                                      hintText: "Folder Name",
                                      hintStyle: const TextStyle(color: AppColors.glassTextMuted),
                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
                                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.pureWhite)),
                                    ),
                                    onChanged: (val) => input = val,
                                    onSubmitted: (val) => Navigator.pop(context, val),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("CANCEL", style: TextStyle(color: AppColors.glassTextMuted)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, input),
                                      child: const Text("CREATE", style: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              }
                            );

                            if (folderName != null && folderName.trim().isNotEmpty) {
                              final activeFolder = ref.read(activeFolderProvider);
                              final vaultPath = StorageService().vaultPath;
                              final targetPath = (activeFolder == null || activeFolder == "Cloud Streams")
                                  ? '$vaultPath/${folderName.trim()}'
                                  : '$vaultPath/$activeFolder/${folderName.trim()}';

                              final newDir = Directory(targetPath);
                              if (!newDir.existsSync()) {
                                newDir.createSync(recursive: true);
                                ref.read(collectionControllerProvider.notifier).syncVault();
                              }
                            }
                          }
                        ),

                        
                        _VaultMenuAction(
                          icon: Icons.drive_folder_upload_outlined, 
                          label: "Import Folder", 
                          onTap: () async {
                            ref.read(vaultMenuProvider.notifier).state = false;
                            
                            // Ask OS to let user pick a folder
                            String? selectedDirectory = await FilePicker.getDirectoryPath();

                            if (selectedDirectory != null) {
                              final sourceDir = Directory(selectedDirectory);
                              final folderName = sourceDir.path.split('/').last;

                              final activeFolder = ref.read(activeFolderProvider);
                              final vaultPath = StorageService().vaultPath;
                              
                              // Determine where this folder should go in the Vault
                              final targetDirPath = (activeFolder == null || activeFolder == "Cloud Streams")
                                  ? '$vaultPath/$folderName'
                                  : '$vaultPath/$activeFolder/$folderName';

                              final targetDir = Directory(targetDirPath);
                              if (!targetDir.existsSync()) targetDir.createSync(recursive: true);

                              // Perform a recursive copy of the folder, but ONLY grab audio files to prevent garbage data
                              await for (var entity in sourceDir.list(recursive: true, followLinks: false)) {
                                if (entity is File) {
                                  final ext = entity.path.split('.').last.toLowerCase();
                                  if (['mp3', 'flac', 'wav', 'm4a', 'aac', 'ogg', 'mpga'].contains(ext)) {
                                    // Preserve the inner folder structure
                                    final relativePath = entity.path.substring(sourceDir.path.length + 1);
                                    final newFile = File('${targetDir.path}/$relativePath');
                                    
                                    if (!newFile.parent.existsSync()) newFile.parent.createSync(recursive: true);
                                    await entity.copy(newFile.path);
                                  }
                                }
                              }
                              ref.read(collectionControllerProvider.notifier).syncVault();
                            }
                          }
                        ),


                        _VaultMenuAction(
                          icon: Icons.checklist_rounded, 
                          label: "Multi-Select", 
                          onTap: () {
                            ref.read(vaultMenuProvider.notifier).state = false;
                            ref.read(multiSelectProvider.notifier).state = true;
                          }
                        ),
                        _VaultMenuAction(
                          icon: Icons.sync_rounded, 
                          label: "Sync Vault", 
                          onTap: () {
                            ref.read(vaultMenuProvider.notifier).state = false;
                            ref.read(collectionControllerProvider.notifier).syncVault();
                          }
                        ),
                      ],
                    ),
                  ),
                ),

                
              ),
            ),

          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final WidgetRef ref;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => ref.read(navIndexProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white54, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _DockAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _DockAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: isDestructive ? Colors.redAccent : AppColors.pureWhite, size: 22,),
            const SizedBox(height: 6,),
            Text(label, style: TextStyle( color: isDestructive ? Colors.redAccent : AppColors.pureWhite, fontSize: 10, fontWeight: FontWeight.bold),),
          ],
        ),
      ),
    );
  }
}

class _VaultMenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _VaultMenuAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}