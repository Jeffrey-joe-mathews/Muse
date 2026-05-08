import 'package:flutter/material.dart';
import 'package:muse/models/song.dart';

class SearchTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SearchTile({
    super.key,
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,

      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          song.albumArt,
          width: 55,
          height: 55,
          fit: BoxFit.cover,

          errorBuilder: (_, __, ___) {
            return Container(
              width: 55,
              height: 55,
              color: Colors.grey.shade800,
              child: const Icon(Icons.music_note),
            );
          },
        ),
      ),

      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      trailing: const Icon(Icons.play_arrow),
    );
  }
}