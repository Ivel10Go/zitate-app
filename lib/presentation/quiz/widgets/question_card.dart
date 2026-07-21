import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/quote.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({required this.quote, this.hint, super.key});

  final Quote quote;

  /// Era nudge on the easier questions. Null on advanced ones, where the card
  /// shows the quote and nothing else.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final hintLabel = hint;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(
          left: BorderSide(color: AppColors.ink, width: 1),
          right: BorderSide(color: AppColors.ink, width: 1),
          bottom: BorderSide(color: AppColors.ink, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '„${quote.textDe}“',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontStyle: FontStyle.italic,
              color: AppColors.ink,
              height: 1.45,
            ),
          ),
          if (hintLabel != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.rule, width: 1),
              ),
              child: Text(
                'HINWEIS · $hintLabel',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkLight,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
