import '../models/models.dart';
import '../theme/noir_theme.dart';

/// Curated timezone threat board. Brisbane (AEST, UTC+10, no DST) is primary.
class ConflictZones {
  static const List<ZoneClock> zones = [
    ZoneClock(
      id: 'bne',
      label: 'Brisbane · QLD',
      iana: 'Australia/Brisbane',
      threat: ThreatLevel.tension,
      rationale:
          'AEST (UTC+10, no daylight saving). Primary chronometer for this build.',
      source: 'IANA TZDB Australia/Brisbane',
    ),
    ZoneClock(
      id: 'utc',
      label: 'UTC · Reference',
      iana: 'UTC',
      threat: ThreatLevel.peace,
      rationale: 'Neutral reference meridian.',
      source: 'IANA TZDB',
    ),
    ZoneClock(
      id: 'syd',
      label: 'Sydney',
      iana: 'Australia/Sydney',
      threat: ThreatLevel.tension,
      rationale: 'AEST/AEDT — may differ from Brisbane during DST months.',
      source: 'IANA TZDB',
    ),
    ZoneClock(
      id: 'ny',
      label: 'New York',
      iana: 'America/New_York',
      threat: ThreatLevel.tension,
      rationale: 'Strategic signalling & alliance politics.',
      source: 'CrisisWatch',
    ),
    ZoneClock(
      id: 'lon',
      label: 'London',
      iana: 'Europe/London',
      threat: ThreatLevel.tension,
      rationale: 'NATO coordination node.',
      source: 'CrisisWatch Europe',
    ),
    ZoneClock(
      id: 'kyiv',
      label: 'Kyiv',
      iana: 'Europe/Kyiv',
      threat: ThreatLevel.conflict,
      rationale: 'Active interstate war.',
      source: 'ACLED / Crisis Group',
    ),
    ZoneClock(
      id: 'msk',
      label: 'Moscow',
      iana: 'Europe/Moscow',
      threat: ThreatLevel.conflict,
      rationale: 'Party to active interstate war; nuclear signalling risk.',
      source: 'Crisis Group Eurasia',
    ),
    ZoneClock(
      id: 'jer',
      label: 'Jerusalem',
      iana: 'Asia/Jerusalem',
      threat: ThreatLevel.conflict,
      rationale: 'Active regional war & multi-front escalation risk.',
      source: 'CrisisWatch Middle East',
    ),
    ZoneClock(
      id: 'teh',
      label: 'Tehran',
      iana: 'Asia/Tehran',
      threat: ThreatLevel.crisis,
      rationale: 'Proxy + direct confrontation cycles.',
      source: 'Crisis Group Middle East',
    ),
    ZoneClock(
      id: 'tpe',
      label: 'Taipei',
      iana: 'Asia/Taipei',
      threat: ThreatLevel.crisis,
      rationale: 'Cross-strait military pressure short of open war.',
      source: 'CrisisWatch Asia',
    ),
    ZoneClock(
      id: 'sel',
      label: 'Seoul',
      iana: 'Asia/Seoul',
      threat: ThreatLevel.crisis,
      rationale: 'Armistice line; DPRK testing cadence.',
      source: 'Crisis Group Northeast Asia',
    ),
    ZoneClock(
      id: 'khartoum',
      label: 'Khartoum',
      iana: 'Africa/Khartoum',
      threat: ThreatLevel.conflict,
      rationale: 'Active civil war with mass displacement.',
      source: 'ACLED Sudan',
    ),
  ];
}
