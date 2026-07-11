import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/feedback_submission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/quote.dart';
import '../../domain/services/quote_deduplication_service.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../../widgets/android_back_guard.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/quote_repository.dart';

class QuoteSubmissionScreen extends StatelessWidget {
  const QuoteSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _QuoteSubmissionView();
  }
}

class _QuoteSubmissionView extends ConsumerStatefulWidget {
  const _QuoteSubmissionView();

  @override
  ConsumerState<_QuoteSubmissionView> createState() =>
      _QuoteSubmissionViewState();
}

class _QuoteSubmissionViewState extends ConsumerState<_QuoteSubmissionView> {
  final _textController = TextEditingController();
  final _authorController = TextEditingController();
  final _sourceController = TextEditingController();
  final _noteController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isSubmitting = false;
  bool _showAdvanced = false;
  List<Quote>? _similarQuotes;

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    _sourceController.dispose();
    _noteController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _checkForDuplicates() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bitte gib ein Zitat ein')));
      return;
    }

    try {
      final db = AppDatabase();
      final repository = QuoteRepository(db);
      final allQuotesStream = repository.watchAllQuotes();
      final allQuotes = await allQuotesStream.first;
      final similar = QuoteDeduplicationService.findSimilarQuotes(
        _textController.text,
        allQuotes,
        threshold: 0.70, // 70% - etwas lockerer für Vorschläge
      );

      setState(() {
        _similarQuotes = similar;
      });

      if (similar.isNotEmpty) {
        _showSimilarQuotesDialog(similar);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Prüfen: $e')));
      }
    }
  }

  void _showSimilarQuotesDialog(List<Quote> similar) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Ähnliche Zitate gefunden',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Folgende Zitate sind bereits in unserem Katalog:',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: AppColors.inkLight,
                  ),
                ),
                const SizedBox(height: 16),
                ...similar.map((quote) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.red, width: 1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '"${quote.textDe}"',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${quote.source} • ${quote.year}',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 10,
                            color: AppColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Text(
                  'Möchtest du dein Zitat trotzdem einreichen? Es könnte eine neue Variante oder Quelle sein.',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Abbrechen',
                style: GoogleFonts.ibmPlexSans(color: AppColors.inkLight),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitQuote(ignoreSimilar: true);
              },
              child: Text(
                'Trotzdem einreichen',
                style: GoogleFonts.ibmPlexSans(
                  color: AppColors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitQuote({bool ignoreSimilar = false}) async {
    if (_textController.text.isEmpty || _authorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zitat und Autor sind erforderlich')),
      );
      return;
    }

    // Prüfe Duplikate wenn nicht ignoriert
    if (!ignoreSimilar && _similarQuotes == null) {
      await _checkForDuplicates();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = FeedbackSubmissionService();
      await service.submitQuoteSubmission(
        quote: _textController.text,
        author: _authorController.text,
        source: _sourceController.text.isEmpty ? null : _sourceController.text,
        note: _noteController.text,
        contact: _contactController.text.isEmpty
            ? null
            : _contactController.text,
        platform: Theme.of(context).platform == TargetPlatform.iOS
            ? 'iOS'
            : 'Android',
        appVersion: '0.1.0',
        appLocale: Localizations.localeOf(context).toString(),
      );

      if (mounted) {
        _textController.clear();
        _authorController.clear();
        _sourceController.clear();
        _noteController.clear();
        _contactController.clear();
        setState(() => _similarQuotes = null);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Zitat eingereicht! Danke für deinen Beitrag. Ich überprüfe es und füge es hinzu.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Senden: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AndroidBackGuard(
      child: AppDecoratedScaffold(
        appBar: null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              color: scheme.surface,
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLarge,
                AppTheme.spacingBase,
                AppTheme.spacingLarge,
                AppTheme.spacingBase,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ZITAT EINREICHEN',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(width: 40, height: 2, color: AppColors.red),
                  const SizedBox(height: 10),
                  Text(
                    'Teile dein Lieblingszitat',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: scheme.outline),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
              const SizedBox(height: 4),
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Das Zitat *',
                  hintText: 'Gib das Zitat ein...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: GoogleFonts.ibmPlexSans(fontSize: 11),
                maxLines: 4,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorController,
                decoration: InputDecoration(
                  labelText: 'Autor *',
                  hintText: 'Karl Marx',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: GoogleFonts.ibmPlexSans(fontSize: 11),
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),
              if (_showAdvanced) ...<Widget>[
                TextField(
                  controller: _sourceController,
                  decoration: InputDecoration(
                    labelText: 'Quelle (optional)',
                    hintText: 'Das Kapital, Buch 1',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: scheme.outline),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: GoogleFonts.ibmPlexSans(fontSize: 11),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Notiz / Kontext (optional)',
                    hintText: 'Kontext oder zusätzliche Informationen...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: scheme.outline),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: GoogleFonts.ibmPlexSans(fontSize: 11),
                  maxLines: 3,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    _showAdvanced ? 'Weniger Optionen' : 'Mehr Optionen',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      color: AppColors.inkLight,
                    ),
                  ),
                  IconButton(
                    onPressed: !_isSubmitting
                        ? () => setState(() => _showAdvanced = !_showAdvanced)
                        : null,
                    icon: Icon(
                      _showAdvanced ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: 'Kontakt (optional)',
                  hintText: 'deine@email.de',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: GoogleFonts.ibmPlexSans(fontSize: 11),
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 24),
              if (_similarQuotes != null && _similarQuotes!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.paperDark,
                    border: Border.all(color: AppColors.red, width: 1),
                  ),
                  child: Text(
                    '⚠ ${_similarQuotes!.length} ähnliche(s) Zitat(e) gefunden. '
                    'Bitte prüfen vor dem Senden.',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      color: AppColors.red,
                    ),
                  ),
                ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: scheme.outline, width: 1),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSubmitting
                              ? null
                              : () => _checkForDuplicates(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'DUPLIKATE PRÜFEN',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        border: Border.all(color: AppColors.redDark, width: 1),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSubmitting ? null : () => _submitQuote(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              _isSubmitting
                                  ? 'WIRD GESENDET...'
                                  : 'ZITAT SENDEN',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: scheme.surface,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
