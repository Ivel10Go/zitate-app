import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/quote_attribution.dart';
import '../data/models/quote.dart';
import 'category_chip.dart';

class CompactQuoteCard extends StatelessWidget {
  const CompactQuoteCard({super.key, required this.quote, this.onTap});

  final Quote quote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = quote.textDe.trim().isNotEmpty
        ? quote.textDe
        : quote.textOriginal;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outline, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            color: scheme.onSurface,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Text(
                              '— ${quoteAuthorLabel(quote)}',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 11,
                                color: scheme.onSurface.withAlpha(
                                  (0.9 * 255).round(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              quote.year.toString(),
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 10,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: quote.category
                              .take(2)
                              .map((String item) => CategoryChip(label: item))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: scheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
