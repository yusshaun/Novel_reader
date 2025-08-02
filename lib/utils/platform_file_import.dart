import 'package:flutter/material.dart';

class PlatformFileImport {
  static Future<List<String>?> pickEpubFiles() async {
    // For web platform, this would use different implementation
    throw UnimplementedError('Platform-specific file import not implemented for this platform');
  }

  static bool get supportsDragDrop => false;
  
  static Widget? buildDragDropWidget({
    required Widget child,
    required Function(List<String>) onFilesDropped,
  }) {
    return null; // Default implementation
  }
}