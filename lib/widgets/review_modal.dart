import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/roblox_game.dart';

/// Create / edit a review.
/// The sheet closes and the snackbar shows immediately on tap. The Firestore
/// write is not awaited because it only completes once the server acknowledges
/// it, which hangs when offline or on a slow connection (that's why the card
/// seemed to "stay"). Firestore still queues and syncs the write.
Future<void> showReviewModal({
  required BuildContext context,
  RobloxGame? preselectedGame,
  DocumentSnapshot? existingDoc,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final messenger = ScaffoldMessenger.of(context);

  final existingData = existingDoc?.data() as Map<String, dynamic>?;
  final isEditing = existingDoc != null;

  final titleController = TextEditingController(
    text: isEditing ? existingData!['gameTitle'] : (preselectedGame?.title ?? ''),
  );
  final reviewController = TextEditingController(
    text: isEditing ? existingData!['reviewText'] : '',
  );

  String selectedGenre = isEditing
      ? (existingData!['genre'] ?? 'Adventure')
      : (preselectedGame?.genre ?? 'Adventure');
  if (!kGenres.contains(selectedGenre) || selectedGenre == 'All') {
    selectedGenre = 'Adventure';
  }

  double rating = isEditing ? (existingData!['rating'] as num).toDouble() : 4.0;
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1F262E),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? 'Edit Game Review' : 'Log & Rate Game',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Game Title', border: OutlineInputBorder()),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedGenre,
                      decoration: const InputDecoration(labelText: 'Genre', border: OutlineInputBorder()),
                      items: kGenres
                          .where((g) => g != 'All')
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedGenre = val ?? 'Adventure'),
                    ),
                    const SizedBox(height: 12),
                    Text('Rating: ${rating.toStringAsFixed(1)} ★'),
                    Slider(
                      value: rating,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: const Color(0xFF00E054),
                      onChanged: (val) => setModalState(() => rating = val),
                    ),
                    TextFormField(
                      controller: reviewController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Review', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00E054),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;

                        final payload = {
                          'userId': user.uid,
                          'gameTitle': titleController.text.trim(),
                          'genre': selectedGenre,
                          'rating': rating,
                          'reviewText': reviewController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        };

                        final collection = FirebaseFirestore.instance.collection('game_reviews');

                        // Fire the write (queued locally, synced when possible).
                        final Future<void> write = isEditing
                            ? collection.doc(existingDoc.id).update(payload)
                            : collection.add(payload).then((_) {});

                        write.catchError((e) {
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text('Could not save review: $e'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        });

                        // 1) Close the Post Review card right away.
                        Navigator.of(ctx).pop();

                        // 2) Show the snackbar.
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing ? 'Review updated successfully!' : 'Review posted successfully!',
                              ),
                              backgroundColor: const Color(0xFF00E054),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                      },
                      child: Text(isEditing ? 'SAVE CHANGES' : 'POST REVIEW'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
