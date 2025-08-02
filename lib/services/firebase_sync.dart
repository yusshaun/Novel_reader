import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/reading_progress.dart';

class FirebaseSync {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;
  
  FirebaseSync(this._userId);

  Future<void> syncProgress() async {
    try {
      final progressBox = Hive.box<ReadingProgress>('reading_progress');
      final unsyncedProgress = progressBox.values
          .where((progress) => !progress.isSynced)
          .toList();

      // Upload local changes to Firestore
      for (final progress in unsyncedProgress) {
        await _uploadProgress(progress);
        progress.isSynced = true;
        await progressBox.put(progress.id, progress);
      }

      // Download remote changes from Firestore
      await _downloadProgress();
    } catch (e) {
      print('Error syncing progress: $e');
    }
  }

  Future<void> _uploadProgress(ReadingProgress progress) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('reading_progress')
          .doc(progress.id);

      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        // Create new document
        await docRef.set(progress.toFirestore());
      } else {
        // Check timestamp for conflict resolution
        final remoteData = docSnapshot.data()!;
        final remoteTimestamp = DateTime.fromMillisecondsSinceEpoch(
          remoteData['timestamp'] ?? 0,
        );
        
        if (progress.timestamp.isAfter(remoteTimestamp)) {
          // Local is newer, update remote
          await docRef.update(progress.toFirestore());
        } else {
          // Remote is newer, update local
          final updatedProgress = ReadingProgress.fromFirestore(
            progress.id,
            remoteData,
          );
          final progressBox = Hive.box<ReadingProgress>('reading_progress');
          await progressBox.put(progress.id, updatedProgress);
        }
      }
    } catch (e) {
      print('Error uploading progress: $e');
    }
  }

  Future<void> _downloadProgress() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('reading_progress')
          .get();

      final progressBox = Hive.box<ReadingProgress>('reading_progress');

      for (final doc in snapshot.docs) {
        final remoteProgress = ReadingProgress.fromFirestore(
          doc.id,
          doc.data(),
        );
        
        final localProgress = progressBox.get(doc.id);
        
        if (localProgress == null) {
          // New remote progress, add to local
          await progressBox.put(doc.id, remoteProgress);
        } else {
          // Check timestamp for conflict resolution
          if (remoteProgress.timestamp.isAfter(localProgress.timestamp)) {
            // Remote is newer, update local
            await progressBox.put(doc.id, remoteProgress);
          }
        }
      }
    } catch (e) {
      print('Error downloading progress: $e');
    }
  }

  Future<void> deleteProgress(String progressId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('reading_progress')
          .doc(progressId)
          .delete();
      
      final progressBox = Hive.box<ReadingProgress>('reading_progress');
      await progressBox.delete(progressId);
    } catch (e) {
      print('Error deleting progress: $e');
    }
  }

  Stream<List<ReadingProgress>> watchProgress() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('reading_progress')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReadingProgress.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> setupOfflineSync() async {
    try {
      await _firestore.enableNetwork();
      
      // Set up offline persistence settings
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      print('Error setting up offline sync: $e');
    }
  }

  Future<void> enableOfflineMode() async {
    try {
      await _firestore.disableNetwork();
    } catch (e) {
      print('Error enabling offline mode: $e');
    }
  }

  Future<void> enableOnlineMode() async {
    try {
      await _firestore.enableNetwork();
    } catch (e) {
      print('Error enabling online mode: $e');
    }
  }
}