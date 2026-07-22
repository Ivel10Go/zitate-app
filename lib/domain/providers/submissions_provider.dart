import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/feedback_submission_service.dart';
import '../../data/models/quote_submission.dart';

final feedbackSubmissionServiceProvider = Provider<FeedbackSubmissionService>(
  (Ref ref) => FeedbackSubmissionService(),
);

/// Aktiver Statusfilter im Prüf-Postfach. `null` = alle Status.
final submissionStatusFilterProvider = StateProvider<SubmissionStatus?>(
  (Ref ref) => SubmissionStatus.pending,
);

/// Aktiver Typfilter im Prüf-Postfach. `null` = Zitate und Fehlerberichte.
final submissionTypeFilterProvider = StateProvider<SubmissionType?>(
  (Ref ref) => SubmissionType.quoteSubmission,
);

/// Die gefilterte Liste der Einreichungen aus Supabase.
final submissionsProvider = FutureProvider.autoDispose<List<QuoteSubmission>>((
  Ref ref,
) async {
  final service = ref.watch(feedbackSubmissionServiceProvider);
  final status = ref.watch(submissionStatusFilterProvider);
  final type = ref.watch(submissionTypeFilterProvider);

  return service.fetchSubmissions(status: status, type: type);
});

/// Anzahl der offenen Zitat-Einreichungen — für das Badge im Admin-Bereich.
final pendingSubmissionCountProvider = FutureProvider.autoDispose<int>((
  Ref ref,
) async {
  final service = ref.watch(feedbackSubmissionServiceProvider);
  final pending = await service.fetchSubmissions(
    status: SubmissionStatus.pending,
  );
  return pending.length;
});
