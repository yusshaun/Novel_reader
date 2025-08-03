import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

class CoverImageService {
  /// 從文件選擇圖片
  static Future<Uint8List?> pickImageFromFile() async {
    try {
      debugPrint('開始文件選擇...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      debugPrint('文件選擇結果: ${result != null ? '成功' : '失敗'}');
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        debugPrint('選擇的文件: ${file.name}, 大小: ${file.size} bytes');

        if (file.path != null) {
          debugPrint('使用文件路徑處理圖片: ${file.path}');
          return await _processImage(file.path!);
        } else if (file.bytes != null) {
          debugPrint('使用字節數據處理圖片');
          return await _processImageBytes(file.bytes!);
        }
      } else {
        debugPrint('未選擇任何文件');
      }
    } catch (e) {
      debugPrint('Error picking image from file: $e');
    }
    return null;
  }

  /// 處理圖片文件路徑
  static Future<Uint8List?> _processImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      return await _processImageBytes(bytes);
    } catch (e) {
      debugPrint('Error processing image: $e');
    }
    return null;
  }

  /// 處理圖片字節數據（壓縮和調整大小）
  static Future<Uint8List?> _processImageBytes(Uint8List bytes) async {
    try {
      debugPrint('開始處理圖片字節數據，原始大小: ${bytes.length} bytes');
      final image = img.decodeImage(bytes);

      if (image != null) {
        debugPrint('圖片解碼成功，原始尺寸: ${image.width}x${image.height}');

        // 計算新的尺寸，保持書籍封面的比例 (約 2:3)
        int newWidth = 400;
        int newHeight = 600;

        // 如果原圖比例不是 2:3，則調整尺寸以適應
        final aspectRatio = image.width / image.height;
        if (aspectRatio > 2 / 3) {
          // 圖片太寬，以高度為準
          newWidth = (newHeight * aspectRatio).round();
        } else {
          // 圖片太高，以寬度為準
          newHeight = (newWidth / aspectRatio).round();
        }

        debugPrint('調整後尺寸: ${newWidth}x${newHeight}');

        // 調整圖片大小
        final resized = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
        );

        debugPrint('圖片縮放完成: ${resized.width}x${resized.height}');

        // 如果需要裁剪到標準比例
        final cropped = img.copyCrop(
          resized,
          (resized.width - 400) ~/ 2,
          (resized.height - 600) ~/ 2,
          400,
          600,
        );

        debugPrint('圖片裁剪完成: ${cropped.width}x${cropped.height}');

        // 壓縮圖片
        final compressed = img.encodeJpg(cropped, quality: 85);
        debugPrint('圖片壓縮完成，最終大小: ${compressed.length} bytes');
        return Uint8List.fromList(compressed);
      } else {
        debugPrint('圖片解碼失敗');
      }
    } catch (e) {
      debugPrint('Error processing image bytes: $e');
    }
    return null;
  }

  /// 顯示選擇圖片的對話框
  static Future<Uint8List?> showImagePickerDialog(BuildContext context) async {
    return await showDialog<Uint8List?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.image, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('選擇封面圖片'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '支持 JPG、PNG、GIF 等格式\n圖片將自動調整為書籍封面比例',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.folder, color: Colors.purple),
                title: const Text('從文件選擇'),
                subtitle: const Text('瀏覽文件夾選擇圖片'),
                onTap: () async {
                  try {
                    final imageData = await pickImageFromFile();
                    if (context.mounted) {
                      if (imageData != null) {
                        Navigator.pop(context, imageData);
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('未選擇圖片或圖片處理失敗'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('選擇圖片時發生錯誤：$e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 確認移除封面的對話框
  static Future<bool> showRemoveCoverDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              const SizedBox(width: 8),
              const Text('移除封面'),
            ],
          ),
          content: const Text('確定要移除這本書的封面圖片嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                '取消',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('移除'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
