import 'quote.dart';
import 'thinker_quote.dart';

enum AppMode { public, adminMarx }

enum ContentType { quote, thinkerQuote }

abstract class DailyContent {
  const DailyContent();

  factory DailyContent.quote({required Quote quote}) = DailyQuoteContent;
  factory DailyContent.thinkerQuote({required ThinkerQuote quote}) =
      DailyThinkerQuoteContent;

  T when<T>({
    required T Function(Quote) quote,
    required T Function(ThinkerQuote) thinkerQuote,
  }) {
    if (this is DailyQuoteContent) {
      return quote((this as DailyQuoteContent).quote);
    } else if (this is DailyThinkerQuoteContent) {
      return thinkerQuote((this as DailyThinkerQuoteContent).quote);
    }
    throw UnimplementedError();
  }
}

class DailyQuoteContent extends DailyContent {
  const DailyQuoteContent({required this.quote});
  final Quote quote;
}

class DailyThinkerQuoteContent extends DailyContent {
  const DailyThinkerQuoteContent({required this.quote});
  final ThinkerQuote quote;
}
