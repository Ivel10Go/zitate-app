import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/quote_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final quoteRepositoryProvider = Provider<QuoteRepository>((Ref ref) {
  return QuoteRepository(ref.watch(appDatabaseProvider));
});

final initialSeedProvider = FutureProvider<void>((Ref ref) async {
  final quoteRepository = ref.watch(quoteRepositoryProvider);

  // Check if seeding was already done (idempotent check via SharedPreferences)
  // Version suffix must be bumped whenever assets/thinkers_quotes.json changes,
  // so existing installs re-upsert the fixes.
  final prefs = await SharedPreferences.getInstance();
  const seedKey = 'app_seeded_v4';

  if (prefs.getBool(seedKey) == true) {
    // The flag says we've seeded before, but the database itself is the
    // source of truth: if it was reset independently of SharedPreferences
    // (reinstall, cleared app storage, migration wipe, ...) the flag alone
    // would leave the app stuck with no quotes forever, since nothing
    // else ever re-triggers seeding.
    final hasQuotes = await quoteRepository.quoteCount() > 0;
    if (hasQuotes) {
      return;
    }
  }

  // Mark as seeding to prevent concurrent operations
  await prefs.setBool(seedKey, true);

  try {
    await quoteRepository.ensureSeeded();
  } catch (e) {
    // Reset flag on error so retry can happen
    await prefs.remove(seedKey);
    rethrow;
  }
});
