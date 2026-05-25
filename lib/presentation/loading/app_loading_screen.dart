import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({
    super.key,
    this.title = 'Zitatatlas lädt',
    this.subtitle = 'Inhalte werden vorbereitet …',
    this.progress,
  });

  final String title;
  final String subtitle;
  final double? progress;

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeProgress = widget.progress?.clamp(0.0, 1.0);
    final percentText = safeProgress == null
        ? 'Synchronisiere ...'
        : '${(safeProgress * 100).round()}%';
    final barProgress = safeProgress ?? 0.08;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.paper,
        child: Stack(
          children: [
            // Animated background elements
            Positioned(
              top: -50,
              right: -50,
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingAnimation.value),
                    child: child,
                  );
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_floatingAnimation.value),
                    child: child,
                  );
                },
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 80,
                          height: 80,
                          color: AppColors.red,
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Title
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Subtitle
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            color: AppColors.inkLight,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 60),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            border: Border.all(color: AppColors.rule, width: 1),
                          ),
                          child: Column(
                            children: <Widget>[
                              ClipRRect(
                                child: LinearProgressIndicator(
                                  minHeight: 4,
                                  value: safeProgress == null
                                      ? null
                                      : barProgress,
                                  backgroundColor: AppColors.rule.withValues(
                                    alpha: 0.28,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.red,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                percentText,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.ink,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppInlineLoadingState extends StatelessWidget {
  const AppInlineLoadingState({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.rule, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(width: 36, height: 2, color: AppColors.red),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  color: AppColors.inkLight,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              const LinearProgressIndicator(
                minHeight: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
                backgroundColor: AppColors.rule,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppInlineErrorState extends StatelessWidget {
  const AppInlineErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Erneut versuchen',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.ink, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(width: 36, height: 2, color: AppColors.red),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 20,
                    color: AppColors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  color: AppColors.inkLight,
                  height: 1.45,
                ),
              ),
              if (onRetry != null) ...<Widget>[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    child: Text(retryLabel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppFullscreenRecoveryScreen extends StatelessWidget {
  const AppFullscreenRecoveryScreen({
    super.key,
    required this.title,
    required this.message,
    required this.details,
    this.onRetry,
    this.retryLabel = 'Erneut versuchen',
  });

  final String title;
  final String message;
  final String details;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.ink, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(width: 44, height: 2, color: AppColors.red),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 28,
                          color: AppColors.red,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        color: AppColors.ink,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.rule.withValues(alpha: 0.14),
                        border: Border.all(color: AppColors.rule, width: 1),
                      ),
                      child: Text(
                        details,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          color: AppColors.inkLight,
                          height: 1.45,
                        ),
                      ),
                    ),
                    if (onRetry != null) ...<Widget>[
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onRetry,
                          child: Text(retryLabel),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
