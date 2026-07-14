import '../../core/utils/german_text_normalizer.dart';

class Quote {
  const Quote({
    required this.id,
    required this.textDe,
    required this.textOriginal,
    required this.author,
    required this.source,
    required this.year,
    required this.chapter,
    required this.category,
    required this.difficulty,
    required this.series,
    required this.explanationShort,
    required this.explanationLong,
    required this.relatedIds,
    this.funFact,
    this.imageUrl,
  });

  final String id;
  final String textDe;
  final String textOriginal;

  /// Person the quote is attributed to. Empty for rows seeded before schema v6;
  /// read it through `quoteAuthorLabel()`, which falls back to [series].
  final String author;

  /// The work the quote appears in — a title, not a person.
  final String source;
  final int year;
  final String chapter;
  final List<String> category;
  final String difficulty;
  final String series;
  final String explanationShort;
  final String explanationLong;
  final List<String> relatedIds;
  final String? funFact;
  final String? imageUrl;

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: (json['id'] as String?) ?? 'unknown',
      textDe:
          normalizeGermanDisplayText(json['text_de'] as String?) ??
          '(Text nicht verfügbar)',
      textOriginal:
          normalizeGermanDisplayText(json['text_original'] as String?) ??
          '(Original text not available)',
      author: normalizeGermanDisplayText(json['author'] as String?) ?? '',
      source:
          normalizeGermanDisplayText(json['source'] as String?) ??
          '(Source unknown)',
      year: (json['year'] as num?)?.toInt() ?? 0,
      chapter: normalizeGermanDisplayText(json['chapter'] as String?) ?? '',
      category: _safeParseCategory(json['category']),
      difficulty: json['difficulty'] as String? ?? 'intermediate',
      series: normalizeGermanDisplayText(json['series'] as String?) ?? '',
      explanationShort:
          normalizeGermanDisplayText(json['explanation_short'] as String?) ??
          '',
      explanationLong:
          normalizeGermanDisplayText(json['explanation_long'] as String?) ?? '',
      relatedIds: _safeParseRelatedIds(json['related_ids']),
      funFact: normalizeGermanDisplayText(json['fun_fact'] as String?),
      imageUrl: json['image_url'] as String?,
    );
  }

  static List<String> _safeParseCategory(dynamic value) {
    if (value == null) return <String>[];
    if (value is String) return <String>[value];
    if (value is List<dynamic>) {
      return value
          .map((item) {
            final normalized = normalizeGermanDisplayText(item?.toString());
            final out = (normalized ?? item?.toString() ?? '').trim();
            return out;
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  static List<String> _safeParseRelatedIds(dynamic value) {
    if (value == null) return <String>[];
    if (value is String) return <String>[value];
    if (value is List<dynamic>) {
      return value
          .map((item) {
            final normalized = normalizeGermanDisplayText(item?.toString());
            final out = (normalized ?? item?.toString() ?? '').trim();
            return out;
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'text_de': textDe,
      'text_original': textOriginal,
      'author': author,
      'source': source,
      'year': year,
      'chapter': chapter,
      'category': category,
      'difficulty': difficulty,
      'series': series,
      'explanation_short': explanationShort,
      'explanation_long': explanationLong,
      'related_ids': relatedIds,
      'fun_fact': funFact,
      'image_url': imageUrl,
    };
  }
}
