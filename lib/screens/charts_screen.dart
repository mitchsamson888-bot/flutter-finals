import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/roblox_game.dart';
import '../widgets/review_modal.dart';
import '../widgets/game_banner.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  String _selectedGenre = 'All';

  // Created once so the stream isn't re-subscribed on every rebuild.
  final Stream<QuerySnapshot> _customGames = FirebaseFirestore.instance
      .collection('custom_games')
      .orderBy('createdAt', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ROBLOX CHARTS')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _customGames,
        builder: (context, snapshot) {
          // Games users added from the Home "+" button come first.
          final added = (snapshot.data?.docs ?? [])
              .map((d) => RobloxGame.fromFirestore(d.data() as Map<String, dynamic>))
              .toList();
          final all = [...added, ...kRobloxCatalog];

          final filtered = _selectedGenre == 'All'
              ? all
              : all.where((g) => g.genre == _selectedGenre).toList();

          return Column(
            children: [
              // Genre filters stay horizontal; the game cards scroll vertically.
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: kGenres.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final genre = kGenres[index];
                    return ChoiceChip(
                      label: Text(genre),
                      selected: genre == _selectedGenre,
                      selectedColor: const Color(0xFF00E054),
                      onSelected: (_) => setState(() => _selectedGenre = genre),
                    );
                  },
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No games found.'))
                    : ListView.separated(
                        scrollDirection: Axis.vertical,
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final game = filtered[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => showReviewModal(context: context, preselectedGame: game),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F262E),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                    child: GameBanner(game: game, height: 170, radius: 0, iconSize: 56),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          game.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          game.genre,
                                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                        ),
                                        if (game.description.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            game.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.thumb_up_alt, size: 13, color: Colors.grey[400]),
                                            const SizedBox(width: 4),
                                            Text(game.likes, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                            const SizedBox(width: 14),
                                            Icon(Icons.person, size: 14, color: Colors.grey[400]),
                                            const SizedBox(width: 3),
                                            Text(game.players, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
