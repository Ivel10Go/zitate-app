import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/quiz_session.dart';
import '../services/personalization_service.dart';
import '../services/quiz_builder.dart';
import 'repository_providers.dart';
import 'user_profile_provider.dart';

class QuizNotifier extends StateNotifier<QuizSession> {
  QuizNotifier(this._ref) : super(QuizSession.empty()) {
    _initialize();
  }

  final Ref _ref;
  final QuizBuilder _builder = QuizBuilder();

  Future<void> _initialize() async {
    state = await _generateSession();
  }

  Future<QuizSession> _generateSession() async {
    await _ref.read(initialSeedProvider.future);
    final profile = _ref.read(userProfileProvider);
    final candidates = await _ref
        .read(quoteRepositoryProvider)
        .watchAllQuotes()
        .first;

    if (candidates.isEmpty) {
      return QuizSession.empty();
    }

    // Expands each quote once per unit of weight — a draw pool, not a set.
    final drawPool = PersonalizationService().getWeightedQuotes(
      candidates,
      profile,
    );

    return _builder.build(
      candidates: candidates,
      drawPool: drawPool.isEmpty ? candidates : drawPool,
    );
  }

  void answer(int selectedIndex) {
    final current = state.currentQuestion;
    if (state.isComplete || current == null || current.isAnswered) {
      return;
    }

    final questions = List<QuizQuestion>.from(state.questions);
    questions[state.currentIndex] = current.copyWith(
      selectedIndex: selectedIndex,
    );

    state = state.copyWith(questions: questions);
  }

  void answerTimeout() {
    final current = state.currentQuestion;
    if (state.isComplete || current == null || current.isAnswered) {
      return;
    }

    final questions = List<QuizQuestion>.from(state.questions);
    questions[state.currentIndex] = current.copyWith(timedOut: true);

    state = state.copyWith(questions: questions);
  }

  Future<void> nextQuestion() async {
    if (state.isComplete) {
      return;
    }

    if (state.isLastQuestion) {
      state = state.copyWith(isComplete: true);
      await _recordCompletedRun();
      return;
    }

    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  /// Discards the current run and builds a fresh one.
  Future<void> restart() async {
    state = QuizSession.empty();
    state = await _generateSession();
  }

  Future<void> _recordCompletedRun() async {
    final prefs = await SharedPreferences.getInstance();
    final highscore = prefs.getInt('quiz_highscore') ?? 0;
    if (state.score > highscore) {
      await prefs.setInt('quiz_highscore', state.score);
    }
    await prefs.setString('quiz_last_played', DateTime.now().toIso8601String());

    _ref.invalidate(quizHighscoreProvider);
    _ref.invalidate(quizPlayedTodayProvider);
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizSession>(
  (Ref ref) => QuizNotifier(ref),
);

final quizHighscoreProvider = FutureProvider<int>((Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('quiz_highscore') ?? 0;
});

/// Whether a quiz was already completed today. Free users are limited to one
/// quiz per day; Pro users play without limit (checked at the UI gate).
final quizPlayedTodayProvider = FutureProvider<bool>((Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('quiz_last_played');
  if (raw == null) {
    return false;
  }
  final lastPlayed = DateTime.tryParse(raw);
  if (lastPlayed == null) {
    return false;
  }
  final now = DateTime.now();
  return lastPlayed.year == now.year &&
      lastPlayed.month == now.month &&
      lastPlayed.day == now.day;
});
