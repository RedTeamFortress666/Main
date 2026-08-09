import '../models/models.dart';
import '../theme/noir_theme.dart';

/// Curated timezone threat board.
/// Levels reflect open-source conflict / crisis reporting categories
/// (International Crisis Group CrisisWatch / ACLED-style conflict presence),
/// not classified intelligence. Refresh manually as conditions change.
class ConflictZones {
  static const List<ZoneClock> zones = [
    ZoneClock(
      id: 'utc',
      label: 'UTC · Reference',
      iana: 'UTC',
      threat: ThreatLevel.peace,
      rationale: 'Neutral reference meridian — no territorial conflict clock.',
      source: 'IANA TZDB',
    ),
    ZoneClock(
      id: 'ny',
      label: 'New York',
      iana: 'America/New_York',
      threat: ThreatLevel.tension,
      rationale: 'Strategic signalling & alliance politics; elevated rhetoric risk.',
      source: 'CrisisWatch / public diplomacy reporting',
    ),
    ZoneClock(
      id: 'lon',
      label: 'London',
      iana: 'Europe/London',
      threat: ThreatLevel.tension,
      rationale: 'NATO coordination node; sanctions & hybrid-threat posture.',
      source: 'CrisisWatch Europe briefings',
    ),
    ZoneClock(
      id: 'kyiv',
      label: 'Kyiv',
      iana: 'Europe/Kyiv',
      threat: ThreatLevel.conflict,
      rationale: 'Active interstate war — currently engaged in armed conflict.',
      source: 'ACLED / UN / Crisis Group Ukraine',
    ),
    ZoneClock(
      id: 'msk',
      label: 'Moscow',
      iana: 'Europe/Moscow',
      threat: ThreatLevel.conflict,
      rationale: 'Party to active interstate war; nuclear signalling risk.',
      source: 'ACLED / Crisis Group Eurasia',
    ),
    ZoneClock(
      id: 'jer',
      label: 'Jerusalem',
      iana: 'Asia/Jerusalem',
      threat: ThreatLevel.conflict,
      rationale: 'Active regional war & multi-front escalation risk.',
      source: 'CrisisWatch Middle East / ACLED',
    ),
    ZoneClock(
      id: 'teh',
      label: 'Tehran',
      iana: 'Asia/Tehran',
      threat: ThreatLevel.crisis,
      rationale: 'Proxy + direct confrontation cycles; nuclear file tension.',
      source: 'Crisis Group Middle East',
    ),
    ZoneClock(
      id: 'tpe',
      label: 'Taipei',
      iana: 'Asia/Taipei',
      threat: ThreatLevel.crisis,
      rationale: 'Cross-strait military pressure short of open war.',
      source: 'CrisisWatch Asia / public PLA activity reports',
    ),
    ZoneClock(
      id: 'sel',
      label: 'Seoul',
      iana: 'Asia/Seoul',
      threat: ThreatLevel.crisis,
      rationale: 'Armistice line; DPRK missile & nuclear testing cadence.',
      source: 'Crisis Group Northeast Asia',
    ),
    ZoneClock(
      id: 'khartoum',
      label: 'Khartoum',
      iana: 'Africa/Khartoum',
      threat: ThreatLevel.conflict,
      rationale: 'Active civil war with mass displacement.',
      source: 'ACLED Sudan / CrisisWatch Africa',
    ),
    ZoneClock(
      id: 'gaza_cairo_ref',
      label: 'Cairo (regional)',
      iana: 'Africa/Cairo',
      threat: ThreatLevel.crisis,
      rationale: 'Regional mediation under adjacent war spillover pressure.',
      source: 'CrisisWatch Middle East',
    ),
  ];
}
