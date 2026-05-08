import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muse/features/player/widgets/orb.dart';

import '../controllers/search_controller.dart';
import '../widgets/search_tile.dart';

import '../../player/controllers/player_controller.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
      ),

      body: Column(
        children: [

          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,

              decoration: InputDecoration(
                hintText: "Search songs...",
                prefixIcon: const Icon(Icons.search),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              onSubmitted: (value) {
                ref
                    .read(searchControllerProvider.notifier)
                    .search(value);
              },
            ),
          ),

          /// RESULTS
          Expanded(
            child: searchState.when(
              data: (songs) {

                if (songs.isEmpty) {
                  return const Center(
                    child: Text("Search something"),
                  );
                }

                return ListView.builder(
                  itemCount: songs.length,

                  itemBuilder: (context, index) {
                    final song = songs[index];

                    return SearchTile(
                      song: song,

                      onTap: () async {

                        await ref
                            .read(playerControllerProvider.notifier)
                            // .playSong(song);
                            .playQueue(songs, index);
                      },
                    );
                  },
                );
              },

              loading: () {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },

              error: (e, _) {
                return Center(
                  child: Text(
                    e.toString(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MuseOrb(),
      // floatingActionButtonLocation:
    // FloatingActionButtonLocation.endFloat,
      // bottomNavigationBar: Container(
      //   height: 80,
      //   color: Colors.red,
      // ),
    );
  }
}