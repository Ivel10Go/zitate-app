/// Eine Einreichung aus der Community (`public.community_submissions`).
///
/// Deckt beide Typen der Tabelle ab: Zitat-Vorschläge und Fehlerberichte.
/// Wird ausschließlich aus Supabase gelesen — es gibt keine lokale
/// Drift-Tabelle dafür, weil die Prüfung online passiert.
enum SubmissionStatus {
  pending,
  reviewing,
  accepted,
  rejected,
  closed;

  static SubmissionStatus fromDb(String? value) {
    return SubmissionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SubmissionStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case SubmissionStatus.pending:
        return 'Offen';
      case SubmissionStatus.reviewing:
        return 'In Prüfung';
      case SubmissionStatus.accepted:
        return 'Angenommen';
      case SubmissionStatus.rejected:
        return 'Abgelehnt';
      case SubmissionStatus.closed:
        return 'Erledigt';
    }
  }
}

enum SubmissionType {
  quoteSubmission('quote_submission', 'Zitat'),
  bugReport('bug_report', 'Fehler');

  const SubmissionType(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static SubmissionType fromDb(String? value) {
    return SubmissionType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => SubmissionType.quoteSubmission,
    );
  }
}

class QuoteSubmission {
  const QuoteSubmission({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.message,
    required this.quoteText,
    required this.author,
    required this.source,
    required this.contact,
    required this.submitterEmail,
    required this.platform,
    required this.appVersion,
    required this.createdAt,
    required this.reviewedAt,
    required this.reviewNotes,
  });

  factory QuoteSubmission.fromJson(Map<String, dynamic> json) {
    final details = json['details'];
    final detailMap = details is Map<String, dynamic>
        ? details
        : <String, dynamic>{};

    return QuoteSubmission(
      id: json['id'] as String,
      type: SubmissionType.fromDb(json['submission_type'] as String?),
      status: SubmissionStatus.fromDb(json['status'] as String?),
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      quoteText: json['quote_text'] as String?,
      author: json['author'] as String?,
      source: json['source'] as String?,
      contact: detailMap['contact'] as String?,
      submitterEmail: json['submitter_email'] as String?,
      platform: json['platform'] as String?,
      appVersion: json['app_version'] as String?,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse((json['reviewed_at'] as String?) ?? ''),
      reviewNotes: json['review_notes'] as String?,
    );
  }

  final String id;
  final SubmissionType type;
  final SubmissionStatus status;
  final String title;
  final String message;
  final String? quoteText;
  final String? author;
  final String? source;
  final String? contact;
  final String? submitterEmail;
  final String? platform;
  final String? appVersion;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;

  /// Wie der Einreichende erreichbar ist — die Einreichung kann anonym sein,
  /// mit Konto-Mail, oder mit freiwillig angegebenem Kontakt.
  String get contactLabel {
    final candidate = <String?>[
      contact,
      submitterEmail,
    ].firstWhere((value) => value != null && value.trim().isNotEmpty,
        orElse: () => null);
    return candidate ?? 'Anonym';
  }

  /// Gerüst für `assets/thinkers_quotes.json`, damit ein angenommenes Zitat
  /// per Copy&Paste in den Datensatz wandern kann.
  ///
  /// Bewusst mit leeren Erklärungsfeldern: Laut CLAUDE.md müssen
  /// `explanation_short` / `explanation_long` von Hand für genau dieses Zitat
  /// geschrieben werden — hier darf nichts generiert werden.
  String toAssetJsonTemplate() {
    final quote = (quoteText ?? '').replaceAll('"', r'\"');
    final quoteAuthor = (author ?? '').replaceAll('"', r'\"');
    final quoteSource = (source ?? '').replaceAll('"', r'\"');

    return '''
{
  "id": "TODO_id",
  "author": "$quoteAuthor",
  "author_type": "philosopher",
  "text_de": "$quote",
  "text_original": "$quote",
  "source": "$quoteSource",
  "year": 0,
  "chapter": "",
  "category": [],
  "difficulty": "beginner",
  "series": "",
  "explanation_short": "",
  "explanation_long": "",
  "related_ids": []
}''';
  }
}
