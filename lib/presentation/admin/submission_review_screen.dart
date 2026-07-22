import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/quote_submission.dart';
import '../../domain/providers/admin_access_provider.dart';
import '../../domain/providers/submissions_provider.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../loading/app_loading_screen.dart';

/// Prüf-Postfach für eingereichte Zitate (und Fehlerberichte).
///
/// Der Zugriff auf die Daten wird serverseitig über RLS geregelt
/// (`profiles.is_admin`); [adminAccessProvider] blendet hier nur die UI aus.
class SubmissionReviewScreen extends ConsumerWidget {
  const SubmissionReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = ref.watch(adminAccessProvider);

    if (!isAdmin) {
      return AppDecoratedScaffold(
        appBar: null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Einreichungen sind nur im Admin-Bereich einsehbar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(fontSize: 13, color: scheme.onSurface),
            ),
          ),
        ),
      );
    }

    final submissionsAsync = ref.watch(submissionsProvider);

    return AppDecoratedScaffold(
      appBar: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Header(
            onBack: () => Navigator.of(context).maybePop(),
            onRefresh: () => ref.invalidate(submissionsProvider),
          ),
          Container(height: 1, color: scheme.outline),
          const _FilterBar(),
          Container(height: 1, color: scheme.outline),
          Expanded(
            child: submissionsAsync.when(
              data: (submissions) {
                if (submissions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Keine Einreichungen mit diesem Filter.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(submissionsProvider),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spacingLarge,
                      AppTheme.spacingLarge,
                      AppTheme.spacingLarge,
                      AppTheme.spacingXl,
                    ),
                    itemCount: submissions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) =>
                        _SubmissionCard(submission: submissions[index]),
                  ),
                );
              },
              loading: () => const Center(
                child: AppInlineLoadingState(
                  title: 'Einreichungen werden geladen',
                  subtitle: 'Community-Vorschläge werden abgerufen …',
                ),
              ),
              error: (error, _) => AppInlineErrorState(
                title: 'Einreichungen konnten nicht geladen werden',
                message: 'Fehler: $error',
                onRetry: () => ref.invalidate(submissionsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final pendingAsync = ref.watch(pendingSubmissionCountProvider);

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: scheme.onSurface),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRefresh,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.refresh, color: scheme.onSurface),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'EINREICHUNGEN',
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
            pendingAsync.maybeWhen(
              data: (count) => count == 1
                  ? '1 offene Einreichung wartet auf Prüfung.'
                  : '$count offene Einreichungen warten auf Prüfung.',
              orElse: () => 'Vorschläge der Community prüfen und einordnen.',
            ),
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final activeStatus = ref.watch(submissionStatusFilterProvider);
    final activeType = ref.watch(submissionTypeFilterProvider);

    return Container(
      color: scheme.surface,
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLarge,
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FilterChip(
                label: 'Alle Typen',
                selected: activeType == null,
                onTap: () =>
                    ref.read(submissionTypeFilterProvider.notifier).state = null,
              ),
              ...SubmissionType.values.map(
                (type) => _FilterChip(
                  label: type.label,
                  selected: activeType == type,
                  onTap: () => ref
                      .read(submissionTypeFilterProvider.notifier)
                      .state = type,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FilterChip(
                label: 'Alle Status',
                selected: activeStatus == null,
                onTap: () => ref
                    .read(submissionStatusFilterProvider.notifier)
                    .state = null,
              ),
              ...SubmissionStatus.values.map(
                (status) => _FilterChip(
                  label: status.label,
                  selected: activeStatus == status,
                  onTap: () => ref
                      .read(submissionStatusFilterProvider.notifier)
                      .state = status,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? AppColors.red : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.redDark : scheme.outline,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: selected ? AppColors.redOnRed : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmissionCard extends ConsumerStatefulWidget {
  const _SubmissionCard({required this.submission});

  final QuoteSubmission submission;

  @override
  ConsumerState<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends ConsumerState<_SubmissionCard> {
  bool _expanded = false;
  bool _isSaving = false;

  Future<void> _setStatus(SubmissionStatus status) async {
    final notes = await _askForNotes(status);
    if (notes == null) return; // Abgebrochen

    setState(() => _isSaving = true);
    try {
      await ref
          .read(feedbackSubmissionServiceProvider)
          .reviewSubmission(
            id: widget.submission.id,
            status: status,
            reviewNotes: notes.isEmpty ? null : notes,
          );
      ref.invalidate(submissionsProvider);
      ref.invalidate(pendingSubmissionCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status gesetzt: ${status.label}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Gibt `null` zurück, wenn der Dialog abgebrochen wurde.
  Future<String?> _askForNotes(SubmissionStatus status) {
    final controller = TextEditingController(
      text: widget.submission.reviewNotes ?? '',
    );

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          status.label,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: GoogleFonts.ibmPlexSans(fontSize: 12),
          decoration: const InputDecoration(
            labelText: 'Prüfnotiz (optional)',
            hintText: 'z. B. Quelle bestätigt, Wortlaut geprüft …',
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: GoogleFonts.ibmPlexSans(color: AppColors.inkLight),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(
              'Speichern',
              style: GoogleFonts.ibmPlexSans(
                color: AppColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _copyAssetTemplate() async {
    await Clipboard.setData(
      ClipboardData(text: widget.submission.toAssetJsonTemplate()),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'JSON-Gerüst kopiert. Erklärungen von Hand ergänzen, dann in '
          'assets/thinkers_quotes.json einfügen.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final submission = widget.submission;
    final isQuote = submission.type == SubmissionType.quoteSubmission;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: <Widget>[
                _StatusBadge(status: submission.status),
                const SizedBox(width: 8),
                Text(
                  submission.type.label.toUpperCase(),
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(submission.createdAt),
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 9,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (isQuote && (submission.quoteText ?? '').isNotEmpty)
                    Text(
                      '„${submission.quoteText}“',
                      maxLines: _expanded ? null : 3,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        height: 1.4,
                        color: scheme.onSurface,
                      ),
                    )
                  else
                    Text(
                      submission.title,
                      maxLines: _expanded ? null : 2,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    <String>[
                      if ((submission.author ?? '').isNotEmpty)
                        submission.author!,
                      if ((submission.source ?? '').isNotEmpty)
                        submission.source!,
                    ].join(' • '),
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red,
                    ),
                  ),
                  if (_expanded) ...<Widget>[
                    const SizedBox(height: 14),
                    if (submission.message.trim().isNotEmpty)
                      _DetailRow(label: 'Notiz', value: submission.message),
                    _DetailRow(label: 'Kontakt', value: submission.contactLabel),
                    _DetailRow(
                      label: 'Gerät',
                      value: <String>[
                        submission.platform ?? '—',
                        if ((submission.appVersion ?? '').isNotEmpty)
                          'v${submission.appVersion}',
                      ].join(' • '),
                    ),
                    if ((submission.reviewNotes ?? '').isNotEmpty)
                      _DetailRow(
                        label: 'Prüfnotiz',
                        value: submission.reviewNotes!,
                      ),
                    if (submission.reviewedAt != null)
                      _DetailRow(
                        label: 'Geprüft am',
                        value: _formatDate(submission.reviewedAt!),
                      ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        _expanded ? 'Weniger' : 'Details',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: scheme.outline),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _CardAction(
                  label: 'IN PRÜFUNG',
                  onTap: _isSaving
                      ? null
                      : () => _setStatus(SubmissionStatus.reviewing),
                ),
                _CardAction(
                  label: 'ANNEHMEN',
                  filled: true,
                  onTap: _isSaving
                      ? null
                      : () => _setStatus(SubmissionStatus.accepted),
                ),
                _CardAction(
                  label: 'ABLEHNEN',
                  onTap: _isSaving
                      ? null
                      : () => _setStatus(SubmissionStatus.rejected),
                ),
                if (isQuote)
                  _CardAction(
                    label: 'JSON KOPIEREN',
                    onTap: _isSaving ? null : _copyAssetTemplate,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: GoogleFonts.ibmPlexSans(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              height: 1.45,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SubmissionStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color background;
    switch (status) {
      case SubmissionStatus.pending:
        background = AppColors.red;
      case SubmissionStatus.reviewing:
        background = AppColors.inkLight;
      case SubmissionStatus.accepted:
        background = AppColors.saved;
      case SubmissionStatus.rejected:
      case SubmissionStatus.closed:
        background = AppColors.inkMuted;
    }

    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      child: Text(
        status.label.toUpperCase(),
        style: GoogleFonts.ibmPlexSans(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: scheme.surface,
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return Container(
      decoration: BoxDecoration(
        color: filled ? AppColors.red : Colors.transparent,
        border: Border.all(
          color: filled ? AppColors.redDark : scheme.outline,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: filled
                    ? AppColors.redOnRed
                    : enabled
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
