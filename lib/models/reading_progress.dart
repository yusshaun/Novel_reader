import 'package:hive/hive.dart';

part 'reading_progress.g.dart';

@HiveType(typeId: 3)
class ReadingProgress extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String bookId;

  @HiveField(2)
  int lastPage;

  @HiveField(3)
  double scrollPosition;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  String? chapterId;

  @HiveField(6)
  String? chapterTitle;

  @HiveField(7)
  double progressPercentage;

  @HiveField(8)
  int totalPages;

  @HiveField(9)
  Duration readingTime;

  @HiveField(10)
  String? lastReadText;

  @HiveField(11)
  bool isSynced;

  ReadingProgress({
    required this.id,
    required this.bookId,
    this.lastPage = 0,
    this.scrollPosition = 0.0,
    required this.timestamp,
    this.chapterId,
    this.chapterTitle,
    this.progressPercentage = 0.0,
    this.totalPages = 0,
    this.readingTime = Duration.zero,
    this.lastReadText,
    this.isSynced = false,
  });

  ReadingProgress copyWith({
    String? id,
    String? bookId,
    int? lastPage,
    double? scrollPosition,
    DateTime? timestamp,
    String? chapterId,
    String? chapterTitle,
    double? progressPercentage,
    int? totalPages,
    Duration? readingTime,
    String? lastReadText,
    bool? isSynced,
  }) {
    return ReadingProgress(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      lastPage: lastPage ?? this.lastPage,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      timestamp: timestamp ?? this.timestamp,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      totalPages: totalPages ?? this.totalPages,
      readingTime: readingTime ?? this.readingTime,
      lastReadText: lastReadText ?? this.lastReadText,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  void updateProgress({
    int? page,
    double? scroll,
    String? chapterId,
    String? chapterTitle,
    Duration? additionalReadingTime,
    String? lastText,
  }) {
    if (page != null) {
      lastPage = page;
      if (totalPages > 0) {
        progressPercentage = (page / totalPages) * 100;
      }
    }

    if (scroll != null) {
      scrollPosition = scroll;
    }

    if (chapterId != null) {
      this.chapterId = chapterId;
    }

    if (chapterTitle != null) {
      this.chapterTitle = chapterTitle;
    }

    if (additionalReadingTime != null) {
      readingTime += additionalReadingTime;
    }

    if (lastText != null) {
      lastReadText = lastText;
    }

    timestamp = DateTime.now();
    isSynced = false;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'lastPage': lastPage,
      'scrollPosition': scrollPosition,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'progressPercentage': progressPercentage,
      'totalPages': totalPages,
      'readingTimeInSeconds': readingTime.inSeconds,
      'lastReadText': lastReadText,
    };
  }

  static ReadingProgress fromFirestore(String id, Map<String, dynamic> data) {
    return ReadingProgress(
      id: id,
      bookId: data['bookId'] ?? '',
      lastPage: data['lastPage'] ?? 0,
      scrollPosition: (data['scrollPosition'] ?? 0.0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      chapterId: data['chapterId'],
      chapterTitle: data['chapterTitle'],
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
      totalPages: data['totalPages'] ?? 0,
      readingTime: Duration(seconds: data['readingTimeInSeconds'] ?? 0),
      lastReadText: data['lastReadText'],
      isSynced: true,
    );
  }

  @override
  String toString() {
    return 'ReadingProgress(bookId: $bookId, page: $lastPage/$totalPages, progress: ${progressPercentage.toStringAsFixed(1)}%)';
  }
}
