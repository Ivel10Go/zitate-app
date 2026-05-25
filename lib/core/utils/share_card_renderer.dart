import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';
import 'quote_attribution.dart';
import '../../data/models/history_fact.dart';
import '../../data/models/quote.dart';
import '../../widgets/adaptive_quote_text.dart';

class ShareCardRenderer {
  final ScreenshotController _controller = ScreenshotController();

  Future<void> shareQuote(Quote quote, BuildContext context) async {
    final fallbackText = _quoteShareText(quote);
    try {
      final image = await _controller.captureFromWidget(
        _ShareCanvas.quote(quote: quote),
      );

      await _shareBytes(
        image,
        fallbackText: fallbackText,
        filePrefix: 'quote_share',
      );
    } catch (error, stackTrace) {
      debugPrint('[ShareCardRenderer] quote share failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await Share.share(fallbackText);
    }
  }

  Future<void> shareFact(HistoryFact fact, BuildContext context) async {
    final fallbackText = _factShareText(fact);
    try {
      final image = await _controller.captureFromWidget(
        _ShareCanvas.fact(fact: fact),
      );

      await _shareBytes(
        image,
        fallbackText: fallbackText,
        filePrefix: 'fact_share',
      );
    } catch (error, stackTrace) {
      debugPrint('[ShareCardRenderer] fact share failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await Share.share(fallbackText);
    }
  }

  Future<void> _shareBytes(
    Uint8List bytes, {
    required String fallbackText,
    required String filePrefix,
  }) async {
    if (bytes.isEmpty) {
      await Share.share(fallbackText);
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/${filePrefix}_${DateTime.now().microsecondsSinceEpoch}.png',
    );

    try {
      await file.writeAsBytes(bytes, flush: true);
      if (await file.length() == 0) {
        await Share.share(fallbackText);
        return;
      }

      await Share.shareXFiles(<XFile>[XFile(file.path)]);
    } catch (error, stackTrace) {
      debugPrint('[ShareCardRenderer] file share failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await Share.share(fallbackText);
    }
  }

  String _quoteShareText(Quote quote) {
    final text = (quote.textEn ?? quote.textDe).trim().isNotEmpty
        ? (quote.textEn ?? quote.textDe).trim()
        : quote.textOriginal.trim();
    return '"$text"\n— ${quote.source}, ${quote.year}\n${quote.explanationShort}';
  }

  String _factShareText(HistoryFact fact) {
    return '${fact.funFact ?? fact.headline}\n${fact.headline}\n${fact.dateDisplay}';
  }
}

class _ShareCanvas extends StatelessWidget {
  const _ShareCanvas._({
    required this.kind,
    required this.kicker,
    required this.title,
    required this.source,
    required this.headerRight,
    this.tagline,
    this.body,
  });

  factory _ShareCanvas.quote({required Quote quote}) {
    return _ShareCanvas._(
      kind: _ShareCanvasKind.quote,
      kicker: '${quoteAuthorLabel(quote).toUpperCase()} · ${quote.year}',
      title: quote.textEn ?? quote.textDe,
      source: '— ${quoteAuthorLabel(quote)}',
      headerRight: quote.chapter,
      tagline: quote.category.take(3).join(' · '),
    );
  }

  factory _ShareCanvas.fact({required HistoryFact fact}) {
    return _ShareCanvas._(
      kind: _ShareCanvasKind.fact,
      kicker: 'WORLD HISTORY · ${fact.dateDisplay.toUpperCase()}',
      title: fact.funFact ?? (fact.headlineEn ?? fact.headline),
      body: fact.bodyEn ?? fact.body,
      source: fact.connectionToMarxEn ?? fact.connectionToMarx,
      headerRight: fact.category.isNotEmpty
          ? fact.category.first.toUpperCase()
          : 'FACT',
      tagline: fact.category.take(3).join(' · '),
    );
  }

  final _ShareCanvasKind kind;
  final String kicker;
  final String title;
  final String source;
  final String headerRight;
  final String? tagline;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 720,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                color: AppColors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        kicker,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.redOnRed,
                          letterSpacing: 1.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      headerRight.toUpperCase(),
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.redOnRed,
                        letterSpacing: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  border: Border(
                    left: BorderSide(color: AppColors.ink, width: 1),
                    right: BorderSide(color: AppColors.ink, width: 1),
                    bottom: BorderSide(color: AppColors.ink, width: 1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AdaptiveQuoteText(
                        text: title,
                        minFontSize: kind == _ShareCanvasKind.quote ? 22 : 20,
                        maxFontSize: kind == _ShareCanvasKind.quote ? 34 : 30,
                        maxLines: kind == _ShareCanvasKind.quote ? 7 : 5,
                        style: GoogleFonts.playfairDisplay(
                          fontStyle: FontStyle.italic,
                          color: AppColors.ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(width: 28, height: 2, color: AppColors.red),
                      const SizedBox(height: 10),
                      Text(
                        source,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 11,
                          color: AppColors.ink.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (body != null && body!.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        Text(
                          body!,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            height: 1.55,
                            color: AppColors.ink,
                          ),
                          maxLines: 7,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (tagline != null &&
                          tagline!.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        Text(
                          tagline!,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red,
                            letterSpacing: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          'QUOTE ATLAS',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink.withValues(alpha: 0.55),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ShareCanvasKind { quote, fact }
