// WHAT THIS FILE DOES:
// Handles raw reads and writes to Cloud Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save or update a document
  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final reference = _db.doc(path);
    await reference.set(data, SetOptions(merge: merge));
  }

  // Get a single document
  Future<DocumentSnapshot> getDocument(String path) async {
    return await _db.doc(path).get();
  }

  // Delete a document
  Future<void> deleteData(String path) async {
    final reference = _db.doc(path);
    await reference.delete();
  }

  // Check if a username already exists
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      // If rules block this, we'll assume it's available to let the user proceed
      return true;
    }
  }
}
