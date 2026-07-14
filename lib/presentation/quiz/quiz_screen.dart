import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/purchases_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/quiz_session.dart';
import '../../domain/providers/quiz_provider.dart';
import '../../domain/providers/quiz_timer_provider.dart';
import '../../widgets/app_decorated_scaffold.dart';
import '../../widgets/app_navigation_bar.dart';
import '../loading/app_loading_screen.dart';
import 'quiz_result_screen.dart';
import 'widgets/answer_button.dart';
import 'widgets/answer_reveal.dart';
import 'widgets/countdown_display.dart';
import 'widgets/question_card.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with WidgetsBindingObserver {
  int? _timerStartedForQuestionIndex;
  bool _quizStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (!_quizStarted) {
      return;
    }

    final timer = ref.read(quizTimerProvider.notifier);
    if (lifecycleState != AppLifecycleState.resumed) {
      timer.pause();
      return;
    }

    // Only pick the countdown back up if a question is actually waiting for an
    // answer — never while the reveal is on screen.
    final session = ref.read(quizProvider);
    final question = session.currentQuestion;
    if (!session.isComplete && question != null && !question.isAnswered) {
      timer.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(quizProvider);
    final timer = ref.watch(quizTimerProvider);

    if (session.isEmpty) {
      return const AppDecoratedScaffold(
        bottomNavigationBar: AppNavigationBar(selectedIndex: -1),
        child: AppInlineLoadingState(
          title: 'Quiz wird vorbereitet',
          subtitle: 'Fragen und Antwortoptionen werden geladen ...',
        ),
      );
    }

    final isPro = ref.watch(isProProvider);
    final playedToday = ref
        .watch(quizPlayedTodayProvider)
        .maybeWhen(data: (value) => value, orElse: () => false);

    if (!_quizStarted && !isPro && playedToday) {
      return const _QuizDailyLimitScreen();
    }

    if (!_quizStarted) {
      return _QuizStartScreen(
        questionCount: session.totalQuestions,
        onStart: _startQuiz,
      );
    }

    if (session.isComplete) {
      return QuizResultScreen(session: session, onRestart: _restart);
    }

    final question = session.currentQuestion!;
    final total = session.totalQuestions;
    final progress = (session.currentIndex + 1) / total;

    if (!question.isAnswered) {
      _ensureTimerRunning(session.currentIndex);
    }

    return AppDecoratedScaffold(
      bottomNavigationBar: const AppNavigationBar(selectedIndex: -1),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Container(
                  color: AppColors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    'QUIZ · FRAGE ${session.currentIndex + 1}/$total',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.redOnRed,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CountdownDisplay(seconds: timer),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressBar(progress: progress),
          const SizedBox(height: 14),
          Text(
            'Wer hat das gesagt?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wähle innerhalb von ${kQuizQuestionDuration.inSeconds} Sekunden '
            'die richtige Autorin oder den richtigen Autor.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: AppColors.inkLight,
            ),
          ),
          const SizedBox(height: 12),
          QuestionCard(quote: question.quote),
          const SizedBox(height: 14),
          ...question.options.asMap().entries.map((MapEntry<int, String> entry) {
            final index = entry.key;
            final isCorrect = question.isAnswered && index == question.correctIndex;
            final isSelectedWrong =
                question.isAnswered &&
                index == question.selectedIndex &&
                index != question.correctIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnswerButton(
                optionIndex: index,
                label: entry.value,
                isLocked: question.isAnswered,
                isCorrect: isCorrect,
                isSelectedWrong: isSelectedWrong,
                onTap: () => _answer(index),
              ),
            );
          }),
          if (question.isAnswered) ...<Widget>[
            const SizedBox(height: 4),
            AnswerReveal(
              question: question,
              isLastQuestion: session.isLastQuestion,
              onContinue: _continue,
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// Starts the countdown for [questionIndex] after the frame that rendered it.
  void _ensureTimerRunning(int questionIndex) {
    if (_timerStartedForQuestionIndex == questionIndex) {
      return;
    }
    _timerStartedForQuestionIndex = questionIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_quizStarted) {
        return;
      }

      final session = ref.read(quizProvider);
      final question = session.currentQuestion;
      if (session.isComplete ||
          session.currentIndex != questionIndex ||
          question == null ||
          question.isAnswered) {
        return;
      }

      ref.read(quizTimerProvider.notifier).start(
        onDone: () {
          if (mounted) {
            ref.read(quizProvider.notifier).answerTimeout();
          }
        },
      );
    });
  }

  void _answer(int index) {
    ref.read(quizProvider.notifier).answer(index);
    // Freeze the countdown where it is; the reveal now waits for a tap.
    ref.read(quizTimerProvider.notifier).pause();
  }

  Future<void> _continue() async {
    ref.read(quizTimerProvider.notifier).reset();
    await ref.read(quizProvider.notifier).nextQuestion();
  }

  Future<void> _startQuiz() async {
    final session = ref.read(quizProvider);
    final isStale =
        session.isComplete ||
        session.questions.any((QuizQuestion q) => q.isAnswered);

    setState(() => _quizStarted = true);
    ref.read(quizTimerProvider.notifier).reset();
    _timerStartedForQuestionIndex = null;

    // Returning to the quiz after a finished run must not drop the user back
    // into that run's last question.
    if (isStale) {
      await ref.read(quizProvider.notifier).restart();
    }
  }

  Future<void> _restart() async {
    ref.read(quizTimerProvider.notifier).reset();
    _timerStartedForQuestionIndex = null;
    // Back to the intro, which re-applies the free-tier daily gate.
    setState(() => _quizStarted = false);
    await ref.read(quizProvider.notifier).restart();
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.rule, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Fortschritt',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkLight,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 5,
            color: AppColors.rule,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizStartScreen extends StatelessWidget {
  const _QuizStartScreen({required this.questionCount, required this.onStart});

  final int questionCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AppDecoratedScaffold(
      bottomNavigationBar: const AppNavigationBar(selectedIndex: -1),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          const _QuizKicker(label: 'QUIZ'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.rule, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'EINSTIEG',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kurzer Check, wie sicher du Denkerinnen und Denker an ihren '
                  'Sätzen erkennst. Der Timer startet erst nach deinem Startklick.',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: AppColors.inkLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.rule, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Starte das Zitat-Quiz',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Du bekommst $questionCount Zitate und rätst, von wem sie '
                  'stammen. ${kQuizQuestionDuration.inSeconds} Sekunden pro '
                  'Frage — erst nach dem Start läuft die Zeit.',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: AppColors.inkLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _QuizPrimaryButton(
                  label: 'QUIZ STARTEN',
                  onTap: onStart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown to free users who already completed today's quiz.
class _QuizDailyLimitScreen extends StatelessWidget {
  const _QuizDailyLimitScreen();

  @override
  Widget build(BuildContext context) {
    return AppDecoratedScaffold(
      bottomNavigationBar: const AppNavigationBar(selectedIndex: -1),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          const _QuizKicker(label: 'QUIZ'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.rule, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'TAGESLIMIT ERREICHT',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Du hast dein Quiz für heute gespielt.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Morgen wartet ein neues Quiz auf dich. Mit Zitate App Pro '
                  'spielst du ohne Tageslimit — so oft du willst.',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: AppColors.inkLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _QuizPrimaryButton(
                  label: 'PRO FREISCHALTEN',
                  color: AppColors.red,
                  foreground: AppColors.redOnRed,
                  onTap: () => context.push('/paywall'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizKicker extends StatelessWidget {
  const _QuizKicker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.red,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.redOnRed,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

class _QuizPrimaryButton extends StatelessWidget {
  const _QuizPrimaryButton({
    required this.label,
    required this.onTap,
    this.color = AppColors.ink,
    this.foreground = AppColors.paper,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: foreground,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
