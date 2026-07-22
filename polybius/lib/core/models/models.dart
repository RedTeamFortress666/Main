import 'package:polybius/core/constants/app_constants.dart';

class UserAccount {
  const UserAccount({
    required this.username,
    required this.passwordHash,
    required this.pinHash,
    required this.tier,
    this.createdAt,
    this.lastLogin,
    this.requiresPin = false,
  });

  final String username;
  final String passwordHash;
  final String pinHash;
  final UserTier tier;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool requiresPin;

  Map<String, dynamic> toJson() => {
        'username': username,
        'passwordHash': passwordHash,
        'pinHash': pinHash,
        'tier': tier.name,
        'createdAt': createdAt?.toIso8601String(),
        'lastLogin': lastLogin?.toIso8601String(),
        'requiresPin': requiresPin,
      };

  factory UserAccount.fromJson(Map<dynamic, dynamic> json) => UserAccount(
        username: json['username'] as String,
        passwordHash: json['passwordHash'] as String,
        pinHash: json['pinHash'] as String,
        tier: UserTier.values.byName(json['tier'] as String),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        lastLogin: json['lastLogin'] != null
            ? DateTime.parse(json['lastLogin'] as String)
            : null,
        requiresPin: json['requiresPin'] as bool? ?? false,
      );

  UserAccount copyWith({
    String? username,
    String? passwordHash,
    String? pinHash,
    UserTier? tier,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? requiresPin,
  }) =>
      UserAccount(
        username: username ?? this.username,
        passwordHash: passwordHash ?? this.passwordHash,
        pinHash: pinHash ?? this.pinHash,
        tier: tier ?? this.tier,
        createdAt: createdAt ?? this.createdAt,
        lastLogin: lastLogin ?? this.lastLogin,
        requiresPin: requiresPin ?? this.requiresPin,
      );
}

class InviteCode {
  const InviteCode({
    required this.code,
    required this.tier,
    required this.createdBy,
    this.usedBy,
    this.createdAt,
    this.expiresAt,
    this.isUsed = false,
  });

  final String code;
  final InviteTier tier;
  final String createdBy;
  final String? usedBy;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool isUsed;

  Map<String, dynamic> toJson() => {
        'code': code,
        'tier': tier.name,
        'createdBy': createdBy,
        'usedBy': usedBy,
        'createdAt': createdAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'isUsed': isUsed,
      };

  factory InviteCode.fromJson(Map<dynamic, dynamic> json) => InviteCode(
        code: json['code'] as String,
        tier: InviteTier.values.byName(json['tier'] as String),
        createdBy: json['createdBy'] as String,
        usedBy: json['usedBy'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        isUsed: json['isUsed'] as bool? ?? false,
      );
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.timestamp,
    required this.action,
    required this.actor,
    this.details,
  });

  final DateTime timestamp;
  final String action;
  final String actor;
  final String? details;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'action': action,
        'actor': actor,
        'details': details,
      };

  factory AuditLogEntry.fromJson(Map<dynamic, dynamic> json) => AuditLogEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        action: json['action'] as String,
        actor: json['actor'] as String,
        details: json['details'] as String?,
      );
}

class GameSettings {
  const GameSettings({
    this.difficulty = 5,
    this.language = 'ENGLISH',
    this.soundEnabled = true,
    this.crtIntensity = 0.7,
  });

  final int difficulty;
  final String language;
  final bool soundEnabled;
  final double crtIntensity;

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty,
        'language': language,
        'soundEnabled': soundEnabled,
        'crtIntensity': crtIntensity,
      };

  factory GameSettings.fromJson(Map<dynamic, dynamic> json) => GameSettings(
        difficulty: json['difficulty'] as int? ?? 5,
        language: json['language'] as String? ?? 'ENGLISH',
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        crtIntensity: (json['crtIntensity'] as num?)?.toDouble() ?? 0.7,
      );

  GameSettings copyWith({
    int? difficulty,
    String? language,
    bool? soundEnabled,
    double? crtIntensity,
  }) =>
      GameSettings(
        difficulty: difficulty ?? this.difficulty,
        language: language ?? this.language,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        crtIntensity: crtIntensity ?? this.crtIntensity,
      );
}
