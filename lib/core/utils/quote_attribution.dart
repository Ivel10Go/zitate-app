import '../../data/models/quote.dart';

/// The person a quote is attributed to, for **display**.
///
/// Prefers the authoritative `author` field. Rows seeded before schema v6 have
/// it empty, so we keep deriving the name from `series` ("person_karl_marx") as
/// a fallback — that derivation loses punctuation ("Jean Jacques Rousseau"),
/// which is why the real field wins whenever it is present.
///
/// As a last resort this returns [Quote.source], which is a work title rather
/// than a person — an attribution line reading "— Das Kapital" beats one
/// reading "— ". Anything that needs a *person* specifically, rather than
/// something to print, must use [quoteAuthorLabelOrEmpty] instead: offering a
/// work title as an answer to "who said this?" is simply a wrong answer.
String quoteAuthorLabel(Quote quote) {
  final person = quoteAuthorLabelOrEmpty(quote);
  return person.isNotEmpty ? person : quote.source;
}

/// The person a quote is attributed to, or `''` when none can be resolved.
///
/// The strict half of [quoteAuthorLabel]: no work-title fallback, so callers
/// can tell "we know who said this" from "we do not".
String quoteAuthorLabelOrEmpty(Quote quote) {
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

  return '';
}
