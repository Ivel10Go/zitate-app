import '../../data/models/quote.dart';

String quoteAuthorLabel(Quote quote) {
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
