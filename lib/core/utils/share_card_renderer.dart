import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';
import 'quote_attribution.dart';
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
    final text = quote.textDe.trim().isNotEmpty
        ? quote.textDe.trim()
        : quote.textOriginal.trim();
    return '"$text"\n— ${quote.source}, ${quote.year}\n${quote.explanationShort}';
  }
}

class _ShareCanvas extends StatelessWidget {
  const _ShareCanvas._({
    required this.kicker,
    required this.title,
    required this.source,
    required this.headerRight,
    this.tagline,
  });

  factory _ShareCanvas.quote({required Quote quote}) {
    return _ShareCanvas._(
      kicker: '${quoteAuthorLabel(quote).toUpperCase()} · ${quote.year}',
      title: quote.textDe,
      source: '— ${quoteAuthorLabel(quote)}',
      headerRight: quote.chapter,
      tagline: quote.category.take(3).join(' · '),
    );
  }

  final String kicker;
  final String title;
  final String source;
  final String headerRight;
  final String? tagline;

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
                        minFontSize: 22,
                        maxFontSize: 34,
                        maxLines: 7,
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
                          'ZITATATLAS',
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
