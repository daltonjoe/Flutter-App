/// A utility class to parse raw analysis text into structured sections.
class TextSection {
  final String title;
  final String content;
  final List<String> bulletPoints;

  TextSection({
    required this.title,
    required this.content,
    this.bulletPoints = const [],
  });
}

class TextParser {
  /// Parses a raw string (potentially containing markdown-like headers) into sections.
  static List<TextSection> parse(String text) {
    if (text.isEmpty) return [];

    final sections = <TextSection>[];
    
    // Split by common header markers (###, ##, or **Title**)
    // First, let's normalize headers to a consistent format if possible
    // For now, let's split by sections that look like "### Title" or "**Title**"
    final lines = text.split('\n');
    String currentTitle = 'Analiz';
    List<String> currentContentLines = [];
    List<String> currentBulletPoints = [];

    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Detect header
      if (trimmedLine.startsWith('###') || 
          trimmedLine.startsWith('##') || 
          (trimmedLine.startsWith('**') && trimmedLine.endsWith('**') && trimmedLine.length < 100)) {
        
        // Save previous section if it exists
        if (currentContentLines.isNotEmpty || currentBulletPoints.isNotEmpty) {
          sections.add(TextSection(
            title: currentTitle,
            content: currentContentLines.join(' '),
            bulletPoints: List.from(currentBulletPoints),
          ));
          currentContentLines = [];
          currentBulletPoints = [];
        }

        // Clean up new title
        currentTitle = trimmedLine
            .replaceAll('#', '')
            .replaceAll('**', '')
            .trim();
      } 
      // Detect bullet points
      else if (trimmedLine.startsWith('-') || trimmedLine.startsWith('•') || trimmedLine.startsWith('*')) {
        currentBulletPoints.add(trimmedLine.substring(1).trim());
      }
      else {
        currentContentLines.add(trimmedLine);
      }
    }

    // Add the last section
    if (currentContentLines.isNotEmpty || currentBulletPoints.isNotEmpty) {
      sections.add(TextSection(
        title: currentTitle,
        content: currentContentLines.join(' '),
        bulletPoints: currentBulletPoints,
      ));
    }

    // If no sections were detected, return the whole thing as one section
    if (sections.isEmpty && text.isNotEmpty) {
      sections.add(TextSection(title: 'Analiz', content: text));
    }

    return sections;
  }
}
