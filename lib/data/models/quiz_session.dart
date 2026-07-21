import 'quote.dart';

/// Number of questions in a full quiz run.
const int kQuizQuestionCount = 10;

/// Answer options per question. Fewer are shown only if the quote pool does not
/// contain enough distinct authors to fill them.
const int kQuizOptionCount = 4;

/// Options on the opening (beginner) questions. One distractor less, so a run
/// starts with a question that can actually be reasoned out.
const int kQuizEasyOptionCount = 3;

/// Fallback time budget. Real questions carry their own [QuizQuestion.duration],
/// which scales with difficulty and with how much text there is to read.
const Duration kQuizQuestionDuration = Duration(seconds: 30);

/// Why a session has no questions.
///
/// Without this, "still building" and "cannot be built" were both just an empty
/// question list, and the screen rendered a loading spinner for either — so a
/// pool with too few authors, or a seed failure, showed as a spinner that never
/// resolved.
enum QuizStatus {
  /// Questions are being drawn. The only state that should show a spinner.
  loading,

  /// Questions are ready to play.
  ready,

  /// The quote pool cannot support a quiz — fewer than two distinct authors.
  /// Not an error: retrying without new data will land here again.
  unavailable,

  /// Building threw. Retrying is worth offering.
  failed,
}

class QuizSession {
  const QuizSession({
    required this.questions,
    required this.currentIndex,
    required this.isComplete,
    this.status = QuizStatus.ready,
  });

  factory QuizSession.empty() {
    return const QuizSession(
      questions: <QuizQuestion>[],
      currentIndex: 0,
      isComplete: false,
      status: QuizStatus.loading,
    );
  }

  factory QuizSession.unavailable() {
    return const QuizSession(
      questions: <QuizQuestion>[],
      currentIndex: 0,
      isComplete: false,
      status: QuizStatus.unavailable,
    );
  }

  factory QuizSession.failed() {
    return const QuizSession(
      questions: <QuizQuestion>[],
      currentIndex: 0,
      isComplete: false,
      status: QuizStatus.failed,
    );
  }

  final List<QuizQuestion> questions;
  final int currentIndex;
  final bool isComplete;
  final QuizStatus status;

  /// Derived from the questions themselves, so score can never drift out of
  /// sync with the answers it is supposed to summarise.
  int get score => questions.where((QuizQuestion q) => q.isCorrect).length;

  int get totalQuestions => questions.length;

  bool get isEmpty => questions.isEmpty;

  QuizQuestion? get currentQuestion {
    if (questions.isEmpty || currentIndex >= questions.length) {
      return null;
    }
    return questions[currentIndex];
  }

  bool get isLastQuestion => currentIndex >= questions.length - 1;

  QuizSession copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    bool? isComplete,
    QuizStatus? status,
  }) {
    return QuizSession(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      isComplete: isComplete ?? this.isComplete,
      status: status ?? this.status,
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.quote,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.duration,
    this.hint,
    this.selectedIndex,
    this.timedOut = false,
  });

  final Quote quote;

  /// Author names. Exactly one of them is the quote's author.
  final List<String> options;
  final int correctIndex;

  /// Normalized bucket the question was drawn from — beginner, intermediate or
  /// advanced. Drives how far apart the distractors are and how long the clock
  /// runs, so the run gets harder as it goes instead of all at once.
  final String difficulty;

  /// Time budget for this question specifically.
  final Duration duration;

  /// Era nudge such as "Antike" or "19. Jahrhundert". Shown on the easier
  /// questions, where narrowing 200-odd authors down to a century is the
  /// difference between reasoning and pure guessing. Null on advanced ones.
  final String? hint;

  /// The option the user tapped. Null while unanswered, and null when the
  /// question ran out of time — [timedOut] tells those two apart.
  final int? selectedIndex;
  final bool timedOut;

  bool get isAnswered => selectedIndex != null || timedOut;
  bool get isCorrect => selectedIndex != null && selectedIndex == correctIndex;
  String get correctOption => options[correctIndex];

  QuizQuestion copyWith({int? selectedIndex, bool? timedOut}) {
    return QuizQuestion(
      quote: quote,
      options: options,
      correctIndex: correctIndex,
      difficulty: difficulty,
      duration: duration,
      hint: hint,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      timedOut: timedOut ?? this.timedOut,
    );
  }
}
