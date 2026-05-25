import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../data/models/daily_content.dart';
import '../../data/models/quote.dart';
import '../../data/models/thinker_quote.dart';

abstract final class WidgetSyncService {
  static Future<void> forceRefresh() async {
    try {
      debugPrint('[WidgetSync] forceRefresh() called');
      await HomeWidget.updateWidget(
        androidName: 'QuoteWidgetProvider',
        iOSName: 'QuoteWidget',
      );
      debugPrint('[WidgetSync] forceRefresh() succeeded');
    } catch (e, st) {
      debugPrint('[WidgetSync] forceRefresh() failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  static Future<void> syncDailyContent({
    required DailyContent content,
    required int streakCount,
    String? modeLabel,
  }) async {
    try {
      debugPrint(
        '[WidgetSync.syncDailyContent] Starting sync for streak=$streakCount, mode=$modeLabel',
      );

      await content.when(
        quote: (quote) async {
          debugPrint(
            '[WidgetSync.syncDailyContent] Processing quote: ${quote.id}',
          );
          await _saveCommon(
            contentType: 'quote',
            header: 'QUOTE ATLAS',
            modeLabel: modeLabel ?? 'PUBLIC',
            author: 'Karl Marx & Friedrich Engels',
            launchRoute: '/detail/${quote.id}',
            quoteText: quote.textEn ?? quote.textDe,
            source: '${quote.source}, ${quote.year}',
            explanation: quote.explanationShort,
            categories: quote.category.join(', '),
            quoteId: quote.id,
          );
        },
        fact: (fact) async {
          debugPrint(
            '[WidgetSync.syncDailyContent] Processing fact: ${fact.id}',
          );
          final route = fact.relatedQuoteIds.isNotEmpty
              ? '/detail/${fact.relatedQuoteIds.first}'
              : '/';
          final factLead = fact.funFact?.trim().isNotEmpty == true
              ? fact.funFact!.trim()
              : (fact.headlineEn ?? fact.headline);
          await _saveCommon(
            contentType: 'fact',
            header: 'WORLD HISTORY',
            modeLabel: modeLabel ?? 'PUBLIC',
            author: 'History',
            launchRoute: route,
            quoteText: factLead,
            source: fact.dateDisplay,
            explanation: fact.headlineEn ?? fact.headline,
            categories: [
              fact.era,
              fact.region,
              ...fact.category,
            ].where((String item) => item.trim().isNotEmpty).join(', '),
          );
          await HomeWidget.saveWidgetData<String>(
            'fact_headline',
            fact.headline,
          );
          await HomeWidget.saveWidgetData<String>(
            'fact_fun_fact',
            fact.funFact ?? '',
          );
        },
        thinkerQuote: (ThinkerQuote quote) async {
          debugPrint(
            '[WidgetSync.syncDailyContent] Processing thinker quote: ${quote.id}',
          );
          await _saveCommon(
            contentType: 'thinker_quote',
            header: 'ARCHIVE',
            modeLabel: modeLabel ?? 'PUBLIC',
            author: quote.author,
            launchRoute: '/archive',
            quoteText: quote.textEn ?? quote.textDe,
            source: '${quote.author}, ${quote.year}',
            explanation: quote.authorType,
            categories: quote.author,
            quoteId: quote.id,
          );
        },
      );

      await HomeWidget.saveWidgetData<String>('streak', streakCount.toString());

      debugPrint('[WidgetSync.syncDailyContent] Calling updateWidget...');
      await HomeWidget.updateWidget(
        androidName: 'QuoteWidgetProvider',
        iOSName: 'QuoteWidget',
      );
      debugPrint('[WidgetSync.syncDailyContent] Sync completed successfully');
    } catch (e, st) {
      // Widget sync must never break the daily content flow.
      // The caller can continue startup or refresh even if widget persistence fails.
      debugPrint('[WidgetSync.syncDailyContent] SYNC FAILED: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  static Future<void> syncQuote({
    required Quote quote,
    required int streakCount,
    String? modeLabel,
  }) {
    return syncDailyContent(
      content: DailyContent.quote(quote: quote),
      streakCount: streakCount,
      modeLabel: modeLabel,
    );
  }

  static Future<void> _saveCommon({
    required String contentType,
    required String header,
    required String modeLabel,
    required String author,
    required String launchRoute,
    required String quoteText,
    required String source,
    required String explanation,
    required String categories,
    String? quoteId,
  }) async {
    try {
      debugPrint(
        '[WidgetSync._saveCommon] Starting save: type=$contentType, header=$header',
      );

      await HomeWidget.saveWidgetData<String>('content_type', contentType);
      await HomeWidget.saveWidgetData<String>('widget_header', header);
      await HomeWidget.saveWidgetData<String>('kicker', header);
      await HomeWidget.saveWidgetData<String>('widget_mode', modeLabel);
      await HomeWidget.saveWidgetData<String>('quote_author', author);
      await HomeWidget.saveWidgetData<String>('launch_route', launchRoute);
      await HomeWidget.saveWidgetData<String>('quote_text', quoteText);
      await HomeWidget.saveWidgetData<String>('quote_source', source);
      await HomeWidget.saveWidgetData<String>('source', source);
      await HomeWidget.saveWidgetData<String>('quote_explanation', explanation);
      await HomeWidget.saveWidgetData<String>('explanation', explanation);
      await HomeWidget.saveWidgetData<String>('quote_categories', categories);

      if (quoteId != null && quoteId.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('quote_id', quoteId);
      }

      debugPrint('[WidgetSync._saveCommon] All data saved successfully');
    } catch (e, st) {
      debugPrint('[WidgetSync._saveCommon] Error saving data: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }
}
