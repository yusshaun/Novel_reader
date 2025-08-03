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
    // Note: Hive 2.x doesn't have listenable, we'll manually refresh when needed
  }

  // 刷新狀態，重新載入所有進度數據
  void refresh() {
    state = _loadProgress(_box);
    print('Reading progress provider refreshed with ${state.length} records');
  }

  static Map<String, ReadingProgress> _loadProgress(Box<ReadingProgress> box) {
    final Map<String, ReadingProgress> progressMap = {};
    print('Loading reading progress from Hive box with ${box.length} items');

    // 由於我們現在使用 bookId 作為 key，可以直接使用 box 的 keys 和 values
    for (final key in box.keys) {
      final progress = box.get(key);
      if (progress != null) {
        progressMap[key.toString()] = progress;
        print(
            'Loaded progress for bookId: ${key.toString()}, page: ${progress.lastPage}');
      }
    }
    print('Total loaded progress records: ${progressMap.length}');
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
        readingTimeMs: additionalReadingTime?.inMilliseconds ?? 0,
        lastReadText: lastReadText,
      );
    }

    await _box.put(bookId, progress);
    state = {...state, bookId: progress};
  }

  // 同步版本，用於應用退出時保存
  void updateProgressSync({
    required String bookId,
    int? page,
    double? scrollPosition,
    String? chapterId,
    String? chapterTitle,
    Duration? additionalReadingTime,
    String? lastReadText,
    int? totalPages,
  }) {
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
        readingTimeMs: additionalReadingTime?.inMilliseconds ?? 0,
        lastReadText: lastReadText,
      );
    }

    // 立即保存並刷新到磁碟，用於應用關閉或銷毀時
    Future.microtask(() async {
      try {
        await _box.put(bookId, progress);
        // 立即刷新到磁碟，確保數據持久化
        await _box.flush();
        state = {...state, bookId: progress};
        print('✅ Progress saved and flushed to disk for bookId: $bookId');
      } catch (e) {
        print('❌ Failed to save and flush progress: $e');
      }
    });
  }

  ReadingProgress? getProgress(String bookId) {
    return state[bookId];
  }

  Future<void> deleteProgress(String bookId) async {
    final progress = state[bookId];
    if (progress != null) {
      await _box.delete(bookId);
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
