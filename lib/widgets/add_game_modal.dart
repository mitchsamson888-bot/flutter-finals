import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/roblox_game.dart';

/// "Add a game" sheet: pick a picture, title, genre, description.
/// Saved to the `custom_games` collection, which the Charts tab streams.
Future<void> showAddGameModal({required BuildContext context}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final messenger = ScaffoldMessenger.of(context);
  final titleController = TextEditingController();
  final descController = TextEditingController();
  String selectedGenre = 'Adventure';
  Uint8List? imageBytes;
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1F262E),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> pickImage() async {
            try {
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                maxWidth: 600, // keep the base64 well under Firestore's 1 MB doc limit
                imageQuality: 70,
              );
              if (picked == null) return;
              final bytes = await picked.readAsBytes();
              setModalState(() => imageBytes = bytes);
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(content: Text('Could not pick image: $e'), backgroundColor: Colors.redAccent),
              );
            }
          }

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
                    const Text('Add a Game', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B3440),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: imageBytes == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF00E054)),
                                  SizedBox(height: 6),
                                  Text('Tap to add a picture', style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : Image.memory(imageBytes!, fit: BoxFit.cover, width: double.infinity),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Game Title', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedGenre,
                      decoration: const InputDecoration(labelText: 'Genre', border: OutlineInputBorder()),
                      items: kGenres
                          .where((g) => g != 'All')
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setModalState(() => selectedGenre = v ?? 'Adventure'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
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
                          'creatorEmail': user.email ?? 'Community',
                          'title': titleController.text.trim(),
                          'genre': selectedGenre,
                          'description': descController.text.trim(),
                          'imageBase64': imageBytes == null ? null : base64Encode(imageBytes!),
                          'createdAt': FieldValue.serverTimestamp(),
                        };

                        FirebaseFirestore.instance
                            .collection('custom_games')
                            .add(payload)
                            .then<void>((_) {})
                            .catchError((e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Could not add game: $e'), backgroundColor: Colors.redAccent),
                          );
                        });

                        Navigator.of(ctx).pop();
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Game added! Find it in Charts.'),
                              backgroundColor: Color(0xFF00E054),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                      },
                      child: const Text('ADD GAME'),
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
