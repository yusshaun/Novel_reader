import 'dart:convert';

class EpubContentProcessor {
  static String htmlToText(String html) {
    // More sophisticated HTML to text conversion
    String text = html;
    
    // Remove script and style content
    text = text.replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>', caseSensitive: false), '');
    
    // Convert common HTML entities
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&mdash;', '—');
    text = text.replaceAll('&ndash;', '–');
    text = text.replaceAll('&hellip;', '…');
    text = text.replaceAll('&lsquo;', ''');
    text = text.replaceAll('&rsquo;', ''');
    text = text.replaceAll('&ldquo;', '"');
    text = text.replaceAll('&rdquo;', '"');
    
    // Convert paragraph tags to double line breaks
    text = text.replaceAll(RegExp(r'<\/p>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');
    
    // Convert br tags to line breaks
    text = text.replaceAll(RegExp(r'<br[^>]*>', caseSensitive: false), '\n');
    
    // Convert div tags to line breaks
    text = text.replaceAll(RegExp(r'<\/div>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '');
    
    // Handle headings
    text = text.replaceAll(RegExp(r'<\/h[1-6]>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n\n');
    
    // Remove all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Clean up whitespace
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n'); // Replace multiple newlines with double newlines
    text = text.replaceAll(RegExp(r'[ \t]+'), ' '); // Replace multiple spaces/tabs with single space
    text = text.trim();
    
    return text;
  }

  static List<String> paginateText(String text, {
    required double fontSize,
    required double screenWidth,
    required double screenHeight,
    required double paddingHorizontal,
    required double paddingVertical,
    required double lineHeight,
  }) {
    if (text.isEmpty) return [''];
    
    // Calculate available space
    final availableWidth = screenWidth - (paddingHorizontal * 2);
    final availableHeight = screenHeight - (paddingVertical * 2);
    
    // Estimate characters per line and lines per page
    final avgCharWidth = fontSize * 0.6; // Rough estimation
    final charsPerLine = (availableWidth / avgCharWidth).floor();
    final linesPerPage = (availableHeight / (fontSize * lineHeight)).floor();
    final charsPerPage = charsPerLine * linesPerPage;
    
    if (charsPerPage <= 0) return [text];
    
    final pages = <String>[];
    final words = text.split(' ');
    var currentPage = StringBuffer();
    var currentLength = 0;
    
    for (final word in words) {
      final wordLength = word.length + 1; // +1 for space
      
      if (currentLength + wordLength > charsPerPage && currentPage.isNotEmpty) {
        pages.add(currentPage.toString().trim());
        currentPage.clear();
        currentLength = 0;
      }
      
      if (currentPage.isNotEmpty) {
        currentPage.write(' ');
      }
      currentPage.write(word);
      currentLength += wordLength;
    }
    
    if (currentPage.isNotEmpty) {
      pages.add(currentPage.toString().trim());
    }
    
    return pages.isEmpty ? [''] : pages;
  }

  static String extractTextSnippet(String text, {int maxLength = 200}) {
    if (text.length <= maxLength) return text;
    
    final snippet = text.substring(0, maxLength);
    final lastSpace = snippet.lastIndexOf(' ');
    
    if (lastSpace > maxLength - 50) {
      return snippet.substring(0, lastSpace) + '...';
    }
    
    return snippet + '...';
  }

  static int estimateReadingTime(String text, {int wordsPerMinute = 200}) {
    final wordCount = text.split(RegExp(r'\s+')).length;
    return (wordCount / wordsPerMinute).ceil();
  }
}