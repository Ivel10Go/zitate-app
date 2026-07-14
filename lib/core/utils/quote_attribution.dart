import '../../data/models/quote.dart';

/// The person a quote is attributed to, for display and for quiz answers.
///
/// Prefers the authoritative `author` field. Rows seeded before schema v6 have
/// it empty, so we keep deriving the name from `series` ("person_karl_marx") as
/// a fallback — that derivation loses punctuation ("Jean Jacques Rousseau"),
/// which is why the real field wins whenever it is present.
///
/// Never falls back to [Quote.source]: that is the work title, not a person.
String quoteAuthorLabel(Quote quote) {
  final author = quote.author.trim();
  if (author.isNotEmpty) {
    return author;
  }

  final series = quote.series.trim().toLowerCase();

  if (series.startsWith('person_')) {
    final personKey = series.substring('person_'.length);
    final words = personKey
        .split('_')
        .where((part) => part.isNotEmpty)
        .toList();
    if (words.isNotEmpty) {
      const particles = <String>{'von', 'van', 'de', 'der', 'di', 'da', 'la'};
      return List<String>.generate(words.length, (index) {
        final part = words[index];
        if (index > 0 && particles.contains(part)) {
          return part;
        }
        return part[0].toUpperCase() + part.substring(1);
      }).join(' ');
    }
  }

  if (series == 'manifest') {
    return 'Karl Marx & Friedrich Engels';
  }

  return quote.source;
}
