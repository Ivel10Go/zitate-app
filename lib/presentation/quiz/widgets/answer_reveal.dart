import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/quote_attribution.dart';
import '../../../data/models/quiz_session.dart';

/// Shown once a question is answered or timed out: names the author, places the
/// quote in its work, and explains why it matters. Advancing is a deliberate tap
/// rather than a timeout, so there is time to actually read it.
class AnswerReveal extends StatelessWidget {
  const AnswerReveal({
    required this.question,
    required this.isLastQuestion,
    required this.onContinue,
    super.key,
  });

  final QuizQuestion question;
  final bool isLastQuestion;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final quote = question.quote;
    final wasCorrect = question.isCorrect;
    final accent = wasCorrect ? AppColors.saved : AppColors.red;

    final String verdict;
    if (wasCorrect) {
      verdict = 'RICHTIG';
    } else if (question.timedOut) {
      verdict = 'ZEIT ABGELAUFEN';
    } else {
      verdict = 'FALSCH';
    }

    final origin = <String>[
      if (quote.source.trim().isNotEmpty) quote.source.trim(),
      if (quote.year != 0) quote.year.toString(),
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: accent, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                verdict,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quoteAuthorLabel(quote),
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (origin.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              origin,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkLight,
              ),
            ),
          ],
          if (quote.explanationShort.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              quote.explanationShort.trim(),
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.ink,
              child: InkWell(
                onTap: onContinue,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    isLastQuestion ? 'ERGEBNIS ANZEIGEN' : 'WEITER',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.paper,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
