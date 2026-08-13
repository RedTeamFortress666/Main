/// Full PØLYBÎŪS operator identity roster for Gam3.0n DARTH CHERRY cache.
class PolybiusOperatorCard {
  const PolybiusOperatorCard({
    required this.username,
    required this.displayName,
    required this.inviteCode,
    required this.pin,
    required this.password,
    required this.backupPassword,
    required this.tier,
  });
  final String username;
  final String displayName;
  final String inviteCode;
  final String pin;
  final String password;
  final String backupPassword;
  final String tier;
}

class PolybiusOperatorCards {
  PolybiusOperatorCards._();
  static const gam3onUsername = 'GAM3.0N';

  static bool canOpenCherryCache(String username) =>
      username.trim().toUpperCase() == gam3onUsername;

  static const all = <PolybiusOperatorCard>[
    PolybiusOperatorCard(username: 'ARTEM3S', displayName: 'Art3mas', inviteCode: 'AR2-66-3R', pin: '271828', password: 'BowArrow7', backupPassword: 'Huntress9', tier: 'admin'),
    PolybiusOperatorCard(username: 'ASHK1TE', displayName: 'AshK1te', inviteCode: 'U01-55-3R', pin: '600101', password: 'AshKite11', backupPassword: 'KiteAsh2', tier: 'agent'),
    PolybiusOperatorCard(username: 'B1TR0VER', displayName: 'B1tR0ver', inviteCode: 'U02-55-3R', pin: '600202', password: 'BitRover22', backupPassword: 'RoverBit8', tier: 'agent'),
    PolybiusOperatorCard(username: 'BL4DERUN', displayName: 'Bl4deRun', inviteCode: 'BR1-77-3R', pin: '401122', password: 'BladeCut99', backupPassword: 'RunBlade7', tier: 'admin'),
    PolybiusOperatorCard(username: 'C0DERAVEN', displayName: 'C0deRaven', inviteCode: 'CR1-88-3R', pin: '501177', password: 'RavenCode9', backupPassword: 'CodeNest1', tier: 'developer'),
    PolybiusOperatorCard(username: 'CROWNOFCORNS', displayName: 'CrownOfCorns', inviteCode: 'C0-9N-3E', pin: '539667', password: '20YokoMicrowave14', backupPassword: 'C0rnS1lo14', tier: 'admin'),
    PolybiusOperatorCard(username: 'CRY0MOTH', displayName: 'Cry0Moth', inviteCode: 'U03-55-3R', pin: '600303', password: 'CryoMoth3', backupPassword: 'MothCryo9', tier: 'agent'),
    PolybiusOperatorCard(username: 'CUP1D!', displayName: 'Cup1d!', inviteCode: 'CU3-66-3R', pin: '161803', password: 'LoveShot99', backupPassword: 'CupidsBow1', tier: 'agent'),
    PolybiusOperatorCard(username: 'DR1FTFOX', displayName: 'Dr1ftFox', inviteCode: 'U04-55-3R', pin: '600404', password: 'DriftFox4', backupPassword: 'FoxDrift1', tier: 'agent'),
    PolybiusOperatorCard(username: 'DYSLEX1C', displayName: 'Dyslex1c', inviteCode: 'DX4-66-3R', pin: '141421', password: 'SpellMix8', backupPassword: 'LexiFix99', tier: 'agent'),
    PolybiusOperatorCard(username: 'ECH0LYNX', displayName: 'Ech0Lynx', inviteCode: 'U05-55-3R', pin: '600505', password: 'EchoLynx5', backupPassword: 'LynxEcho7', tier: 'agent'),
    PolybiusOperatorCard(username: 'FLAREM1NT', displayName: 'FlareM1nt', inviteCode: 'U06-55-3R', pin: '600606', password: 'FlareMint6', backupPassword: 'MintFlare2', tier: 'agent'),
    PolybiusOperatorCard(username: 'GAM3.0N', displayName: 'Gam3.0n', inviteCode: 'B1-66-3R', pin: '816639', password: 'Dig1tal.Ra1n99', backupPassword: '01-p0lyb1u5-10', tier: 'developer'),
    PolybiusOperatorCard(username: 'GL0WWIRE', displayName: 'Gl0wWire', inviteCode: 'U07-55-3R', pin: '600707', password: 'GlowWire7', backupPassword: 'WireGlow3', tier: 'agent'),
    PolybiusOperatorCard(username: 'GL1TCHCAT', displayName: 'Gl1tchCat', inviteCode: 'GC7-66-3R', pin: '264575', password: 'CatGlitch1', backupPassword: 'GlitchMe2', tier: 'agent'),
    PolybiusOperatorCard(username: 'H0NEYBAD', displayName: 'H0neyBad', inviteCode: 'HB8-66-3R', pin: '331127', password: 'HoneyRun7', backupPassword: 'BadHoney9', tier: 'agent'),
    PolybiusOperatorCard(username: 'H4ZEP1X', displayName: 'H4zeP1x', inviteCode: 'U08-55-3R', pin: '600808', password: 'HazePix88', backupPassword: 'PixHaze4', tier: 'agent'),
    PolybiusOperatorCard(username: 'HEXWRAITH', displayName: 'HexWraith', inviteCode: 'HW3-88-3R', pin: '523399', password: 'HexGhost7', backupPassword: 'WraithHex2', tier: 'developer'),
    PolybiusOperatorCard(username: 'IRONMER1D', displayName: 'IronMer1d', inviteCode: 'IM4-77-3R', pin: '434455', password: 'IronTide42', backupPassword: 'MeridIron5', tier: 'admin'),
    PolybiusOperatorCard(username: 'IVYR0CKET', displayName: 'IvyR0cket', inviteCode: 'U09-55-3R', pin: '600909', password: 'IvyRocket9', backupPassword: 'RocketIvy5', tier: 'agent'),
    PolybiusOperatorCard(username: 'J3TC0IL', displayName: 'J3tC0il', inviteCode: 'U10-55-3R', pin: '601010', password: 'JetCoil10', backupPassword: 'CoilJet6', tier: 'agent'),
    PolybiusOperatorCard(username: 'KASP3R', displayName: 'KASP3R', inviteCode: 'TR1-66-3R', pin: '791639', password: 'BurnHideFr13d', backupPassword: 'P1ckl3M0rty69', tier: 'admin'),
    PolybiusOperatorCard(username: 'KRYPT0BEE', displayName: 'Krypt0Bee', inviteCode: 'U11-55-3R', pin: '601111', password: 'KryptoBee1', backupPassword: 'BeeKrypt7', tier: 'agent'),
    PolybiusOperatorCard(username: 'LUMENRAY', displayName: 'LumenRay', inviteCode: 'U12-55-3R', pin: '601212', password: 'LumenRay12', backupPassword: 'RayLumen8', tier: 'agent'),
    PolybiusOperatorCard(username: 'M00NFOX', displayName: 'M00nFox', inviteCode: 'MF5-66-3R', pin: '223606', password: 'MoonRun88', backupPassword: 'FoxMoon11', tier: 'agent'),
    PolybiusOperatorCard(username: 'MIR4GECAT', displayName: 'Mir4geCat', inviteCode: 'U13-55-3R', pin: '601313', password: 'MirageCat3', backupPassword: 'CatMirage9', tier: 'agent'),
    PolybiusOperatorCard(username: 'MIZZPICKL3S', displayName: 'MizzPickl3s', inviteCode: 'SP-1N-33', pin: '080826', password: '8-Bit.Bitch3s', backupPassword: 'Glitch.B1tch99', tier: 'agent'),
    PolybiusOperatorCard(username: 'N0VAQUILL', displayName: 'N0vaQuill', inviteCode: 'U14-55-3R', pin: '601414', password: 'NovaQuill4', backupPassword: 'QuillNova1', tier: 'agent'),
    PolybiusOperatorCard(username: 'NEONVULT', displayName: 'NeonVult', inviteCode: 'NV5-77-3R', pin: '445566', password: 'VultNeon77', backupPassword: 'NeonNest2', tier: 'admin'),
    PolybiusOperatorCard(username: 'NITEQUEEN', displayName: 'NiteQueen', inviteCode: 'NQ1-66-3R', pin: '314159', password: 'NiteOwl42', backupPassword: 'NightOwl7', tier: 'admin'),
    PolybiusOperatorCard(username: 'NULLPTRX', displayName: 'NullPtrX', inviteCode: 'NP2-88-3R', pin: '512288', password: 'NullSeg88', backupPassword: 'PtrNull3', tier: 'developer'),
    PolybiusOperatorCard(username: 'ORB1TWISP', displayName: 'Orb1tWisp', inviteCode: 'U15-55-3R', pin: '601515', password: 'OrbitWisp5', backupPassword: 'WispOrbit2', tier: 'agent'),
    PolybiusOperatorCard(username: 'P!K.ZUP', displayName: 'P!k.ZuP', inviteCode: 'D4-N6-3R', pin: '839093', password: 'DocCh1ck3n', backupPassword: 'TakeAOrdaPr33z', tier: 'admin'),
    PolybiusOperatorCard(username: 'PIXELW1Z', displayName: 'PixelW1z', inviteCode: 'PW9-66-3R', pin: '367879', password: 'PixelZap12', backupPassword: 'WizPixel5', tier: 'agent'),
    PolybiusOperatorCard(username: 'PR1SMDAWN', displayName: 'Pr1smDawn', inviteCode: 'U16-55-3R', pin: '601616', password: 'PrismDawn6', backupPassword: 'DawnPrism3', tier: 'agent'),
    PolybiusOperatorCard(username: 'QU4NTUMOWL', displayName: 'Qu4ntumOwl', inviteCode: 'QO3-77-3R', pin: '423344', password: 'OwlQuant1', backupPassword: 'QuantOwl9', tier: 'admin'),
    PolybiusOperatorCard(username: 'QUARKM1NT', displayName: 'QuarkM1nt', inviteCode: 'U17-55-3R', pin: '601717', password: 'QuarkMint7', backupPassword: 'MintQuark4', tier: 'agent'),
    PolybiusOperatorCard(username: 'R1FTSPARK', displayName: 'R1ftSpark', inviteCode: 'U18-55-3R', pin: '601818', password: 'RiftSpark8', backupPassword: 'SparkRift5', tier: 'agent'),
    PolybiusOperatorCard(username: 'REDTEAM01', displayName: 'RedTeam01', inviteCode: 'B1-66-3R', pin: '816639', password: '816639', backupPassword: '816639', tier: 'admin'),
    PolybiusOperatorCard(username: 'S0LARF1X', displayName: 'S0larF1x', inviteCode: 'SF2-77-3R', pin: '412233', password: 'SolarFix88', backupPassword: 'FixSolar3', tier: 'admin'),
    PolybiusOperatorCard(username: 'SPAMKAT2', displayName: 'SpamKat2', inviteCode: 'W1-66-3R', pin: '810739', password: 'Ev1l-Schm33', backupPassword: 'LilB1tScary99', tier: 'developer'),
    PolybiusOperatorCard(username: 'SYNTHOWL', displayName: 'SynthOwl', inviteCode: 'U19-55-3R', pin: '601919', password: 'SynthOwl19', backupPassword: 'OwlSynth6', tier: 'agent'),
    PolybiusOperatorCard(username: 'T3MPTRESS', displayName: 'T3mptress', inviteCode: '80-081-35', pin: '808135', password: 'not1nkansas69', backupPassword: 'NoPlaceL1ke', tier: 'agent'),
    PolybiusOperatorCard(username: 'TACHY0N', displayName: 'Tachyon', inviteCode: 'U20-55-3R', pin: '602020', password: 'TachyOn20', backupPassword: 'OnTachy7', tier: 'agent'),
    PolybiusOperatorCard(username: 'V3CTORKID', displayName: 'V3ctorKid', inviteCode: 'VK6-66-3R', pin: '244949', password: 'VecTor99', backupPassword: 'KidVector3', tier: 'agent'),
    PolybiusOperatorCard(username: 'WHYTWOK', displayName: 'WhyTwoK', inviteCode: 'Y2K-66-3R', pin: '173205', password: 'PartyY2K1', backupPassword: 'TwoKWave2', tier: 'agent'),
  ];
}
