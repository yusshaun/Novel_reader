// Firebase is temporarily disabled for Windows builds
import '../models/reading_progress.dart';

class FirebaseSync {
  final String _userId;

  FirebaseSync(this._userId);

  // Stub methods for Windows build compatibility
  Future<void> syncReadingProgress(List<ReadingProgress> progressList) async {
    // Firebase disabled for Windows builds
    return;
  }

  Future<List<ReadingProgress>> downloadReadingProgress() async {
    // Firebase disabled for Windows builds
    return [];
  }

  Future<void> uploadReadingProgress(ReadingProgress progress) async {
    // Firebase disabled for Windows builds
    return;
  }

  Stream<List<ReadingProgress>> streamReadingProgress() {
    // Firebase disabled for Windows builds
    return Stream.value([]);
  }

  Future<void> deleteReadingProgress(String bookId) async {
    // Firebase disabled for Windows builds
    return;
  }

  Future<void> enableOfflineSupport() async {
    // Firebase disabled for Windows builds
    return;
  }

  Future<void> disableNetwork() async {
    // Firebase disabled for Windows builds
    return;
  }

  Future<void> enableNetwork() async {
    // Firebase disabled for Windows builds
    return;
  }
}
