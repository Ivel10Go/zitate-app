import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/quiz_session.dart';

/// Counts down the seconds left on the current question.
///
/// The ticker is paused whenever the quiz is not on screen (see the lifecycle
/// handling in QuizScreen), so backgrounding the app cannot silently burn
/// through questions.
class QuizTimerNotifier extends StateNotifier<int> {
  QuizTimerNotifier() : super(kQuizQuestionDuration.inSeconds);

  Timer? _ticker;
  VoidCallback? _onDone;

  bool get isRunning => _ticker != null;

  void start({required VoidCallback onDone}) {
    _onDone = onDone;
    state = kQuizQuestionDuration.inSeconds;
    _tick();
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Resumes from the remaining seconds. No-op unless a question is in flight.
  void resume() {
    if (_ticker != null || _onDone == null || state <= 0) {
      return;
    }
    _tick();
  }

  void reset() {
    pause();
    _onDone = null;
    state = kQuizQuestionDuration.inSeconds;
  }

  void _tick() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (state <= 1) {
        pause();
        state = 0;
        final onDone = _onDone;
        _onDone = null;
        onDone?.call();
        return;
      }
      state = state - 1;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final quizTimerProvider = StateNotifierProvider<QuizTimerNotifier, int>(
  (Ref ref) => QuizTimerNotifier(),
);
