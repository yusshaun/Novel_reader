import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class PlatformFileImport {
  static Future<List<String>?> pickEpubFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList();
      }
      return null;
    } catch (e) {
      print('Error picking files: $e');
      return null;
    }
  }

  static bool get supportsDragDrop {
    // Only Windows desktop supports drag and drop for now
    return Platform.isWindows;
  }
  
  static Widget? buildDragDropWidget({
    required Widget child,
    required Function(List<String>) onFilesDropped,
  }) {
    if (!supportsDragDrop) return child;
    
    // For now, return the child without drag-drop functionality
    // In a real implementation, you would use drag_drop_region package
    // or similar platform-specific implementation
    return DragTarget<List<String>>(
      onWillAccept: (data) => true,
      onAccept: (data) => onFilesDropped(data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: candidateData.isNotEmpty
              ? BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: child,
        );
      },
    );
  }

  static Widget buildFileImportButton({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    if (supportsDragDrop) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: const Text('Import Books'),
          ),
          const SizedBox(height: 8),
          Text(
            'Or drag EPUB files here',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    }

    return FloatingActionButton.extended(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.upload_file),
      label: const Text('Import Books'),
    );
  }
}