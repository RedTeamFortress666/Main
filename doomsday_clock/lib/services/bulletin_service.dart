import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Pulls / caches Bulletin of the Atomic Scientists Doomsday Clock status.
///
/// Primary source: https://thebulletin.org/doomsday-clock/
/// Falls back to last cached snapshot, then a built-in baseline.
class BulletinService {
  static const _cacheKey = 'bulletin_snapshot_v1';
  static const sourceUrl = 'https://thebulletin.org/doomsday-clock/';

  /// Jan 2025 announcement: 89 seconds to midnight (public BAS statement).
  static const _baselineSeconds = 89;
  static const _baselineSummary =
      'The Bulletin of the Atomic Scientists holds the Clock at 89 seconds '
      'to midnight, citing nuclear risk, climate disruption, and destabilizing '
      'emerging technologies. This offline baseline updates when the device '
      'can reach thebulletin.org; treat network text as a brief digest, not a '
      'substitute for the full BAS statement.';

  Future<BulletinSnapshot> load({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRaw = prefs.getString(_cacheKey);
    BulletinSnapshot? cached;
    if (cachedRaw != null) {
      final m = jsonDecode(cachedRaw) as Map<String, dynamic>;
      cached = BulletinSnapshot(
        secondsToMidnight: m['seconds'] as int,
        headline: m['headline'] as String,
        summary: m['summary'] as String,
        sourceUrl: m['sourceUrl'] as String,
        fetchedAt: DateTime.parse(m['fetchedAt'] as String),
        fromNetwork: m['fromNetwork'] as bool? ?? false,
      );
    }

    final today = DateTime.now();
    final freshEnough = cached != null &&
        !forceRefresh &&
        cached.fetchedAt.year == today.year &&
        cached.fetchedAt.month == today.month &&
        cached.fetchedAt.day == today.day;

    if (freshEnough) return cached;

    try {
      final res = await http
          .get(Uri.parse(sourceUrl), headers: {'User-Agent': 'DoomsdayClock2.0'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final parsed = _parseHtml(res.body);
        final snap = BulletinSnapshot(
          secondsToMidnight: parsed.$1,
          headline: parsed.$2,
          summary: parsed.$3,
          sourceUrl: sourceUrl,
          fetchedAt: DateTime.now(),
          fromNetwork: true,
        );
        await prefs.setString(
          _cacheKey,
          jsonEncode({
            'seconds': snap.secondsToMidnight,
            'headline': snap.headline,
            'summary': snap.summary,
            'sourceUrl': snap.sourceUrl,
            'fetchedAt': snap.fetchedAt.toIso8601String(),
            'fromNetwork': true,
          }),
        );
        return snap;
      }
    } catch (_) {
      /* fall through */
    }

    if (cached != null) return cached;

    return BulletinSnapshot(
      secondsToMidnight: _baselineSeconds,
      headline: 'IT IS 89 SECONDS TO MIDNIGHT',
      summary: _baselineSummary,
      sourceUrl: sourceUrl,
      fetchedAt: DateTime.now(),
      fromNetwork: false,
    );
  }

  /// Best-effort scrape of seconds + a short digest from BAS HTML.
  (int, String, String) _parseHtml(String html) {
    var seconds = _baselineSeconds;
    final secMatch = RegExp(
      r'(\d+)\s+seconds?\s+to\s+midnight',
      caseSensitive: false,
    ).firstMatch(html);
    final minMatch = RegExp(
      r'(\d+)\s+minutes?\s+to\s+midnight',
      caseSensitive: false,
    ).firstMatch(html);
    if (secMatch != null) {
      seconds = int.parse(secMatch.group(1)!);
    } else if (minMatch != null) {
      seconds = int.parse(minMatch.group(1)!) * 60;
    }

    final headlineMatch = RegExp(
      r'IT IS\s+\d+\s+(?:SECONDS?|MINUTES?)\s+TO\s+MIDNIGHT',
      caseSensitive: false,
    ).firstMatch(html);
    final headline = headlineMatch?.group(0)?.toUpperCase() ??
        'IT IS $seconds SECONDS TO MIDNIGHT';

    // Strip tags roughly for a short analysis blurb.
    final stripped = html
        .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    String summary = _baselineSummary;
    final idx = stripped.toLowerCase().indexOf('doomsday clock');
    if (idx >= 0) {
      final slice = stripped.substring(idx, (idx + 480).clamp(0, stripped.length));
      if (slice.length > 80) summary = '$slice…';
    }
    return (seconds, headline, summary);
  }
}
