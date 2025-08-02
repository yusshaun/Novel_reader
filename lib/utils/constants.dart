class AppConstants {
  // App information
  static const String appName = 'Novel Reader';
  static const String appVersion = '1.0.0';
  
  // File formats
  static const String epubExtension = 'epub';
  static const List<String> supportedFormats = ['epub'];
  
  // Reading settings
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;
  static const double defaultFontSize = 16.0;
  static const double defaultLineHeight = 1.5;
  static const int wordsPerMinute = 200; // Average reading speed
  
  // Pagination
  static const int wordsPerPage = 250; // Rough estimation
  static const int charsPerWord = 5; // Average characters per word
  
  // UI
  static const double bookCoverAspectRatio = 0.7;
  static const int maxBooksPerRow = 3;
  static const double bookGridSpacing = 16.0;
  
  // Storage
  static const String booksDirectory = 'books';
  static const String coversDirectory = 'covers';
  static const String backupDirectory = 'backups';
  
  // Database
  static const String booksBoxName = 'books';
  static const String bookshelvesBoxName = 'bookshelves';
  static const String readerThemeBoxName = 'reader_theme';
  static const String readingProgressBoxName = 'reading_progress';
  
  // Sync
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxSyncRetries = 3;
  
  // Performance
  static const int pageBufferSize = 3; // Number of pages to preload
  static const Duration debounceDelay = Duration(milliseconds: 300);
  
  // Firebase collections
  static const String usersCollection = 'users';
  static const String readingProgressCollection = 'reading_progress';
  static const String bookmarksCollection = 'bookmarks';
}