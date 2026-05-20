abstract final class QuoteScheduler {
  static Future<String?> pickDailyId(List<String> allIds) async {
    if (allIds.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceEpoch = today.millisecondsSinceEpoch ~/ 86400000;
    final index = daysSinceEpoch % allIds.length;
    return allIds[index];
  }

  static Future<String?> pickNextId(List<String> allIds) async {
    if (allIds.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceEpoch = today.millisecondsSinceEpoch ~/ 86400000;
    final index = (daysSinceEpoch + 1) % allIds.length;
    return allIds[index];
  }
}
