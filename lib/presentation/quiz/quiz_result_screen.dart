import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/quiz_session.dart';
import '../../domain/providers/quiz_provider.dart';
import '../../widgets/app_decorated_scaffold.dart';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({
    required this.session,
    required this.onRestart,
    super.key,
  });

  final QuizSession session;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = session.score;
    final total = session.totalQuestions;
    final highscore = ref
        .watch(quizHighscoreProvider)
        .maybeWhen(data: (int value) => value, orElse: () => score);

    return AppDecoratedScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: <Widget>[
          Container(
            color: AppColors.red,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'ERGEBNIS',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.redOnRed,
                letterSpacing: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '$score/$total',
            style: GoogleFonts.playfairDisplay(
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _rating(score, total),
            style: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          Text(
            'Bester: $highscore/$total',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              color: AppColors.inkLight,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'AUFLÖSUNG',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.red,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          ...session.questions.asMap().entries.map(
            (MapEntry<int, QuizQuestion> entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ReviewRow(number: entry.key + 1, question: entry.value),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.paper,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('NOCHMAL'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/archive'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.ink),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('ZUM ARCHIV ->'),
            ),
          ),
        ],
      ),
    );
  }

  String _rating(int score, int total) {
    if (total == 0) {
      return 'Kein Ergebnis.';
    }

    final ratio = score / total;
    if (ratio <= 0.3) {
      return 'Mehr lesen.';
    }
    if (ratio <= 0.6) {
      return 'Solide Basis.';
    }
    if (ratio < 1) {
      return 'Guter Genosse.';
    }
    return 'Proletarisches Klassenbewusstsein.';
  }
}

/// One line per question: what it was, and — when the guess was wrong — what the
/// user picked versus who actually said it.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.number, required this.question});

  final int number;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final wasCorrect = question.isCorrect;
    final accent = wasCorrect ? AppColors.saved : AppColors.red;

    final String? wrongPick;
    if (wasCorrect) {
      wrongPick = null;
    } else if (question.timedOut || question.selectedIndex == null) {
      wrongPick = 'keine Antwort';
    } else {
      wrongPick = question.options[question.selectedIndex!];
    }

    return InkWell(
      onTap: () => context.push('/detail/${question.quote.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.rule, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 16,
              color: accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$number. „${question.quote.textDe}“',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.correctOption,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (wrongPick != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      'Deine Antwort: $wrongPick',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
