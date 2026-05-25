import '../../core/utils/german_text_normalizer.dart';

class ThinkerQuote {
  const ThinkerQuote({
    required this.id,
    required this.author,
    required this.authorType,
    required this.textDe,
    this.textEn,
    required this.source,
    required this.year,
    this.imageUrl,
  });

  final String id;
  final String author;

  /// Either 'philosopher' or 'politician'
  final String authorType;
  final String textDe;
  final String? textEn;
  final String source;
  final int year;
  final String? imageUrl;

  bool get isPhilosopher => authorType == 'philosopher';
  bool get isPolitician => authorType == 'politician';

  factory ThinkerQuote.fromJson(Map<String, dynamic> json) {
    // Safely handle all fields (may be missing or null in some entries)
    String getAuthorType() {
      final at = json['author_type'];
      if (at is String && at.isNotEmpty) {
        return at;
      }
      return 'philosopher';
    }

    return ThinkerQuote(
      id: (json['id'] as String?) ?? 'unknown',
      author:
          normalizeGermanDisplayText(json['author'] as String?) ?? '(Unknown)',
      authorType: getAuthorType(),
      textDe:
          normalizeGermanDisplayText(json['text_de'] as String?) ??
          '(Text not available)',
      textEn: json['text_en'] as String?,
      source:
          normalizeGermanDisplayText(json['source'] as String?) ??
          '(Source unknown)',
      year: (json['year'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }
}
