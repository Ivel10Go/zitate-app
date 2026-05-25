import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/history_fact.dart';
import '../../data/models/quote.dart';
import 'quote_attribution.dart';

class PdfExportService {
  static final _red = PdfColor.fromInt(0xFFC41E1E);
  static final _ink = PdfColor.fromInt(0xFF1A1A1A);
  static final _muted = PdfColor.fromInt(0xFF555555);

  Future<void> exportFavorites({
    required List<Quote> quotes,
    required List<HistoryFact> facts,
  }) async {
    final doc = pw.Document();
    final fonts = await _loadFonts();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => _buildTitlePage(
          quotes: quotes.length,
          facts: facts.length,
          fonts: fonts,
        ),
      ),
    );

    for (final quote in quotes) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (_) => _buildQuotePage(quote, fonts),
        ),
      );
    }

    for (final fact in facts) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (_) => _buildFactPage(fact, fonts),
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Future<_PdfFonts> _loadFonts() async {
    Future<pw.Font?> load(String path) async {
      try {
        final data = await rootBundle.load(path);
        return pw.Font.ttf(data);
      } catch (_) {
        return null;
      }
    }

    final playfairRegular = await load(
      'assets/fonts/PlayfairDisplay-Regular.ttf',
    );
    final playfairItalic = await load(
      'assets/fonts/PlayfairDisplay-Italic.ttf',
    );
    final plexRegular = await load('assets/fonts/IBMPlexSans-Regular.ttf');
    final plexBold = await load('assets/fonts/IBMPlexSans-Bold.ttf');

    return _PdfFonts(
      serif: playfairRegular,
      serifItalic: playfairItalic,
      sans: plexRegular,
      sansBold: plexBold,
    );
  }

  pw.Widget _buildTitlePage({
    required int quotes,
    required int facts,
    required _PdfFonts fonts,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          'QUOTE ATLAS',
          style: pw.TextStyle(font: fonts.sansBold, fontSize: 28, color: _ink),
        ),
        pw.SizedBox(height: 8),
        pw.Container(width: double.infinity, height: 2, color: _red),
        pw.SizedBox(height: 22),
        pw.Text(
          'My Favorites',
          style: pw.TextStyle(font: fonts.sans, fontSize: 18, color: _ink),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Exported on ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
          style: pw.TextStyle(font: fonts.sans, fontSize: 12, color: _muted),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          '$quotes saved quotes',
          style: pw.TextStyle(font: fonts.sans, fontSize: 12, color: _ink),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          '$facts saved facts',
          style: pw.TextStyle(font: fonts.sans, fontSize: 12, color: _ink),
        ),
      ],
    );
  }

  pw.Widget _buildQuotePage(Quote quote, _PdfFonts fonts) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _ink, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Container(
            color: _red,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            child: pw.Row(
              children: <pw.Widget>[
                pw.Expanded(
                  child: pw.Text(
                    '${quoteAuthorLabel(quote).toUpperCase()} · ${quote.year}',
                    style: pw.TextStyle(
                      font: fonts.sansBold,
                      fontSize: 9,
                      color: PdfColors.white,
                      letterSpacing: 1.1,
                    ),
                    maxLines: 1,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  quote.chapter.toUpperCase(),
                  style: pw.TextStyle(
                    font: fonts.sansBold,
                    fontSize: 8,
                    color: PdfColors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  '„${quote.textEn ?? quote.textDe}"',
                  style: pw.TextStyle(
                    font: fonts.serifItalic,
                    fontSize: 22,
                    color: _ink,
                    lineSpacing: 5,
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Container(width: 56, height: 2, color: _red),
                pw.SizedBox(height: 10),
                pw.Text(
                  '— ${quoteAuthorLabel(quote)}',
                  style: pw.TextStyle(
                    font: fonts.sans,
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
                if (quote.category.isNotEmpty) ...<pw.Widget>[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    quote.category.join(' · ').toUpperCase(),
                    style: pw.TextStyle(
                      font: fonts.sansBold,
                      fontSize: 8,
                      color: _red,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
                if (quote.explanationShort.trim().isNotEmpty) ...<pw.Widget>[
                  pw.SizedBox(height: 16),
                  pw.Text(
                    quote.explanationShort,
                    style: pw.TextStyle(
                      font: fonts.sans,
                      fontSize: 10,
                      color: _muted,
                      lineSpacing: 2.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFactPage(HistoryFact fact, _PdfFonts fonts) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _ink, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Container(
            color: _red,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            child: pw.Row(
              children: <pw.Widget>[
                pw.Expanded(
                  child: pw.Text(
                    'WORLD HISTORY · ${fact.dateDisplay.toUpperCase()}',
                    style: pw.TextStyle(
                      font: fonts.sansBold,
                      fontSize: 9,
                      color: PdfColors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  fact.category.isNotEmpty
                      ? fact.category.first.toUpperCase()
                      : 'FACT',
                  style: pw.TextStyle(
                    font: fonts.sansBold,
                    fontSize: 8,
                    color: PdfColors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  fact.funFact ?? (fact.headlineEn ?? fact.headline),
                  style: pw.TextStyle(
                    font: fonts.serif,
                    fontSize: 22,
                    color: _ink,
                    lineSpacing: 4,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  fact.bodyEn ?? fact.body,
                  style: pw.TextStyle(
                    font: fonts.sans,
                    fontSize: 11,
                    color: _ink,
                    lineSpacing: 3,
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Container(width: 56, height: 2, color: _red),
                pw.SizedBox(height: 10),
                pw.Text(
                  fact.connectionToMarxEn ?? fact.connectionToMarx,
                  style: pw.TextStyle(
                    font: fonts.sans,
                    fontSize: 10,
                    color: _muted,
                    lineSpacing: 2.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfFonts {
  const _PdfFonts({this.serif, this.serifItalic, this.sans, this.sansBold});

  final pw.Font? serif;
  final pw.Font? serifItalic;
  final pw.Font? sans;
  final pw.Font? sansBold;
}
