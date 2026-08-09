import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/quote_submission.dart';

class FeedbackSubmissionService {
  FeedbackSubmissionService._();

  static final FeedbackSubmissionService _instance =
      FeedbackSubmissionService._();

  factory FeedbackSubmissionService() => _instance;

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> submitBugReport({
    required String title,
    required String description,
    required String steps,
    required String expected,
    required String? contact,
    required String platform,
    required String appVersion,
    required String appLocale,
    String? submittedBy,
    String? submitterEmail,
  }) async {
    await _insertSubmission(<String, dynamic>{
      'submission_type': 'bug_report',
      'title': title.isEmpty ? 'Fehlerbericht' : title,
      'message': description,
      'details': <String, dynamic>{
        'steps_to_reproduce': steps,
        'expected_behavior': expected,
        'contact': contact,
      },
      'submitted_by': submittedBy,
      'submitter_email': submitterEmail,
      'platform': platform,
      'app_version': appVersion,
      'app_locale': appLocale,
    });
  }

  Future<void> submitQuoteSubmission({
    required String quote,
    required String author,
    required String? source,
    required String note,
    required String? contact,
    required String platform,
    required String appVersion,
    required String appLocale,
    String? submittedBy,
    String? submitterEmail,
  }) async {
    await _insertSubmission(<String, dynamic>{
      'submission_type': 'quote_submission',
      'title': author.isEmpty ? 'Zitat-Einreichung' : 'Zitat: $author',
      'quote_text': quote,
      'author': author,
      'source': source,
      'message': note,
      'details': <String, dynamic>{'contact': contact},
      'submitted_by': submittedBy,
      'submitter_email': submitterEmail,
      'platform': platform,
      'app_version': appVersion,
      'app_locale': appLocale,
    });
  }

  /// Liest Einreichungen zur Prüfung.
  ///
  /// Was zurückkommt, entscheidet die RLS in Supabase: Admins
  /// (`profiles.is_admin = true`) sehen alles, alle anderen nur ihre eigenen
  /// Einreichungen. Der lokale `UserProfile.isAdmin`-Schalter steuert nur die
  /// Sichtbarkeit der UI, nicht den Datenzugriff.
  Future<List<QuoteSubmission>> fetchSubmissions({
    SubmissionType? type,
    SubmissionStatus? status,
    int limit = 200,
  }) async {
    try {
      var query = _client.from('community_submissions').select();
      if (type != null) {
        query = query.eq('submission_type', type.dbValue);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }
      final rows = await query.order('created_at', ascending: false).limit(
        limit,
      );

      return (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(QuoteSubmission.fromJson)
          .toList();
    } catch (e) {
      throw Exception('Einreichungen konnten nicht geladen werden: $e');
    }
  }

  /// Setzt Status und Prüfnotiz einer Einreichung. Nur Admins dürfen das —
  /// bei allen anderen lehnt die RLS das Update ab.
  Future<void> reviewSubmission({
    required String id,
    required SubmissionStatus status,
    String? reviewNotes,
  }) async {
    final reviewerId = _client.auth.currentUser?.id;
    try {
      await _client
          .from('community_submissions')
          .update(<String, dynamic>{
            'status': status.name,
            'reviewed_at': DateTime.now().toUtc().toIso8601String(),
            'reviewed_by': reviewerId,
            if (reviewNotes != null) 'review_notes': reviewNotes,
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Status konnte nicht gespeichert werden: $e');
    }
  }

  Future<void> _insertSubmission(Map<String, dynamic> payload) async {
    try {
      await _client.from('community_submissions').insert(payload);
    } catch (e) {
      throw Exception('Fehler beim Speichern der Einreichung: $e');
    }
  }
}
