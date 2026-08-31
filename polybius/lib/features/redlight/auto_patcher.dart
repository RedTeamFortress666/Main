import 'package:polybius/features/redlight/cabinet_policy.dart';
import 'package:polybius/features/redlight/leak_detector.dart';

/// Interwoven auto-patcher.
///
/// Runs as part of the V2 login handshake and again when Darth Cherry arms.
/// It does not fetch or apply signed binaries — [SignatureService.verifyPayload]
/// still has no install path (BUILD.md). It weaves cabinet policy so known
/// leaks are not the live default.
class AutoPatcher {
  AutoPatcher._();

  static const String auditAction = 'AUTOPATCH';

  static CabinetPolicy weave() => CabinetPolicy.woven;

  static LeakReport afterWeave(LeakSnapshot snap) {
    return LeakDetector.scan(
      LeakSnapshot(
        policy: weave(),
        mixer: snap.mixer,
        operatorUsername: snap.operatorUsername,
        sessionIsV2: snap.sessionIsV2,
        cabinetRecordExists: snap.cabinetRecordExists,
        masterJunk: snap.masterJunk,
        derangeSecret: snap.derangeSecret,
      ),
    );
  }
}
