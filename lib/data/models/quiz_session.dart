import 'quote.dart';

/// Number of questions in a full quiz run.
const int kQuizQuestionCount = 10;

/// Answer options per question. Fewer are shown only if the quote pool does not
/// contain enough distinct authors to fill them.
const int kQuizOptionCount = 4;

/// Time budget per question.
const Duration kQuizQuestionDuration = Duration(seconds: 15);

class QuizSession {
  const QuizSession({
    required this.questions,
    required this.currentIndex,
    required this.isComplete,
  });

  factory QuizSession.empty() {
    return const QuizSession(
      questions: <QuizQuestion>[],
      currentIndex: 0,
      isComplete: false,
    );
  }

  final List<QuizQuestion> questions;
  final int currentIndex;
  final bool isComplete;

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
  }) {
    return QuizSession(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.quote,
    required this.options,
    required this.correctIndex,
    this.selectedIndex,
    this.timedOut = false,
  });

  final Quote quote;

  /// Author names. Exactly one of them is the quote's author.
  final List<String> options;
  final int correctIndex;

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
      selectedIndex: selectedIndex ?? this.selectedIndex,
      timedOut: timedOut ?? this.timedOut,
    );
  }
}
