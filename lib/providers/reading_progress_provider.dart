import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/reading_progress.dart';

final readingProgressBoxProvider = Provider<Box<ReadingProgress>>((ref) {
  return Hive.box<ReadingProgress>('reading_progress');
});

final readingProgressProvider = StateNotifierProvider<ReadingProgressNotifier,
    Map<String, ReadingProgress>>((ref) {
  final box = ref.watch(readingProgressBoxProvider);
  return ReadingProgressNotifier(box);
});

final currentReadingSessionProvider =
    StateProvider<ReadingSession?>((ref) => null);

class ReadingProgressNotifier
    extends StateNotifier<Map<String, ReadingProgress>> {
  final Box<ReadingProgress> _box;
  final _uuid = const Uuid();

  ReadingProgressNotifier(this._box) : super(_loadProgress(_box)) {
    // Note: Hive 2.x doesn't have listenable, we'll manually refresh
  }

  static Map<String, ReadingProgress> _loadProgress(Box<ReadingProgress> box) {
    final Map<String, ReadingProgress> progressMap = {};
    for (final progress in box.values) {
      progressMap[progress.bookId] = progress;
    }
    return progressMap;
  }

  Future<void> updateProgress({
    required String bookId,
    int? page,
    double? scrollPosition,
    String? chapterId,
    String? chapterTitle,
    Duration? additionalReadingTime,
    String? lastReadText,
    int? totalPages,
  }) async {
    final existingProgress = state[bookId];
    ReadingProgress progress;

    if (existingProgress != null) {
      progress = existingProgress.copyWith();
      progress.updateProgress(
        page: page,
        scroll: scrollPosition,
        chapterId: chapterId,
        chapterTitle: chapterTitle,
        additionalReadingTime: additionalReadingTime,
        lastText: lastReadText,
      );

      if (totalPages != null) {
        progress = progress.copyWith(totalPages: totalPages);
      }
    } else {
      progress = ReadingProgress(
        id: _uuid.v4(),
        bookId: bookId,
        lastPage: page ?? 0,
        scrollPosition: scrollPosition ?? 0.0,
        timestamp: DateTime.now(),
        chapterId: chapterId,
        chapterTitle: chapterTitle,
        totalPages: totalPages ?? 0,
        readingTime: additionalReadingTime ?? Duration.zero,
        lastReadText: lastReadText,
      );
    }

    await _box.put(progress.id, progress);
    state = {...state, bookId: progress};
  }

  ReadingProgress? getProgress(String bookId) {
    return state[bookId];
  }

  Future<void> deleteProgress(String bookId) async {
    final progress = state[bookId];
    if (progress != null) {
      await _box.delete(progress.id);
      final newState = Map<String, ReadingProgress>.from(state);
      newState.remove(bookId);
      state = newState;
    }
  }

  List<ReadingProgress> getRecentlyRead({int limit = 10}) {
    final progressList = state.values.toList();
    progressList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return progressList.take(limit).toList();
  }

  Map<String, Duration> getReadingStats() {
    Duration totalTime = Duration.zero;
    Duration todayTime = Duration.zero;
    Duration weekTime = Duration.zero;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: 7));

    for (final progress in state.values) {
      totalTime += progress.readingTime;

      if (progress.timestamp.isAfter(todayStart)) {
        todayTime += progress.readingTime;
      }

      if (progress.timestamp.isAfter(weekStart)) {
        weekTime += progress.readingTime;
      }
    }

    return {
      'total': totalTime,
      'today': todayTime,
      'week': weekTime,
    };
  }
}

class ReadingSession {
  final String bookId;
  final DateTime startTime;
  late DateTime lastActivity;

  ReadingSession({
    required this.bookId,
    required this.startTime,
  }) {
    lastActivity = startTime;
  }

  Duration get duration => lastActivity.difference(startTime);

  void updateActivity() {
    lastActivity = DateTime.now();
  }
}
