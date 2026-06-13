import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppDecoratedScaffold extends StatelessWidget {
  const AppDecoratedScaffold({
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget child;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: scheme.surface,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(child: child),
    );
  }
}

class EditorialSectionTitle extends StatelessWidget {
  const EditorialSectionTitle({
    required this.label,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.titleStyle,
    this.subtitleStyle,
    super.key,
  });

  final String label;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveTitleStyle = titleStyle ?? AppTheme.masthead;
    final effectiveSubtitleStyle =
        subtitleStyle ??
        AppTheme.mastHeadSubtitle.copyWith(color: scheme.onSurfaceVariant);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 104),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacingLarge,
          AppTheme.spacingBase,
          AppTheme.spacingLarge,
          AppTheme.spacingBase,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  style: AppTheme.labelSmall.copyWith(
                    color: scheme.primary.withValues(alpha: 0.85),
                  ),
                ),
                if (trailing != null) ...<Widget>[const Spacer(), trailing!],
              ],
            ),
            const SizedBox(height: 6),
            Text(title, style: effectiveTitleStyle),
            const SizedBox(height: 8),
            Text(subtitle, style: effectiveSubtitleStyle),
            const SizedBox(height: 12),
            Divider(color: scheme.primary.withValues(alpha: 0.25), height: 1),
          ],
        ),
      ),
    );
  }
}
