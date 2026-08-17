enum QShieldHandshakePhase {
  idle,
  classicalExchange,
  pqcKem,
  sessionReady,
  error,
}

class QShieldSessionInfo {
  const QShieldSessionInfo({
    this.phase = QShieldHandshakePhase.idle,
    this.sessionId = '',
    this.classicalFingerprint = '',
    this.pqcKeyId = '',
    this.hybridProfile = 'X25519+Kyber512',
    this.createdAt,
    this.error,
  });

  final QShieldHandshakePhase phase;
  final String sessionId;
  final String classicalFingerprint;
  final String pqcKeyId;
  final String hybridProfile;
  final DateTime? createdAt;
  final String? error;

  bool get isReady => phase == QShieldHandshakePhase.sessionReady;

  QShieldSessionInfo copyWith({
    QShieldHandshakePhase? phase,
    String? sessionId,
    String? classicalFingerprint,
    String? pqcKeyId,
    DateTime? createdAt,
    String? error,
    bool clearError = false,
  }) {
    return QShieldSessionInfo(
      phase: phase ?? this.phase,
      sessionId: sessionId ?? this.sessionId,
      classicalFingerprint: classicalFingerprint ?? this.classicalFingerprint,
      pqcKeyId: pqcKeyId ?? this.pqcKeyId,
      hybridProfile: hybridProfile,
      createdAt: createdAt ?? this.createdAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
