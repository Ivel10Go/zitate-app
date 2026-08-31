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

/// Store link and promo copy appended to every shared quote so recipients can
/// find the app. Keep the link in sync with the release bundle id
/// (`com.quotidian.app`).
const String _appStoreUrl =
    'https://play.google.com/store/apps/details?id=com.quotidian.app';
const String _appPromoLine =
    'Jeden Tag ein Zitat zum Nachdenken – mit Quotidian:';

class ShareCardRenderer {
  final ScreenshotController _controller = ScreenshotController();

  /// Takes no [BuildContext] on purpose: `captureFromWidget` builds its own
  /// tree off-screen, so there is nothing here that needs the caller's context —
  /// and accepting one invited callers to hold it across this await for nothing.
  Future<void> shareQuote(Quote quote) async {
    final shareText = _quoteShareText(quote);
    try {
      final image = await _controller.captureFromWidget(
        _ShareCanvas.quote(quote: quote),
      );

      await _shareBytes(
        image,
        shareText: shareText,
        filePrefix: 'quote_share',
      );
    } catch (error, stackTrace) {
      debugPrint('[ShareCardRenderer] quote share failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await Share.share(shareText);
    }
  }

  Future<void> _shareBytes(
    Uint8List bytes, {
    required String shareText,
    required String filePrefix,
  }) async {
    if (bytes.isEmpty) {
      await Share.share(shareText);
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/${filePrefix}_${DateTime.now().microsecondsSinceEpoch}.png',
    );

    try {
      await file.writeAsBytes(bytes, flush: true);
      if (await file.length() == 0) {
        await Share.share(shareText);
        return;
      }

      // Attach the caption so the full quote, attribution, promo line and store
      // link travel with the image — even if the rendered card visually
      // truncates a very long quote, the complete text is still shared.
      await Share.shareXFiles(<XFile>[XFile(file.path)], text: shareText);
    } catch (error, stackTrace) {
      debugPrint('[ShareCardRenderer] file share failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await Share.share(shareText);
    } finally {
      // Each share wrote a uniquely named PNG; without this they accumulate in
      // the temp directory for the life of the install. Only safe once
      // shareXFiles has resolved — the receiving app has read the file by then.
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // The OS reclaims the temp directory anyway; never fail a share on this.
      }
    }
  }

  String _quoteShareText(Quote quote) {
    final text = quote.textDe.trim().isNotEmpty
        ? quote.textDe.trim()
        : quote.textOriginal.trim();
    final attribution = '— ${quoteAuthorLabel(quote)}, ${quote.year}';
    return '"$text"\n$attribution\n\n$_appPromoLine\n$_appStoreUrl';
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
                        // Allow long quotes to shrink further and use more
                        // lines so they fit the card instead of being cut off.
                        minFontSize: 14,
                        maxFontSize: 34,
                        maxLines: 14,
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
