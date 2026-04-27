import 'package:firebase_database/firebase_database.dart';

/// Streams real-time bin fill levels from Firebase Realtime Database.
///
/// The Arduino bridge (arduino_bridge.py) writes to this path every 3 seconds:
///
/// ```
/// bin_status/
///   plastic:      <int 0-100>   ← fill % of the plastic bin
///   paper:        <int 0-100>   ← fill % of the paper bin
///   metal:        <int 0-100>   ← fill % of the metal bin
///   last_updated: <ISO-8601>    ← timestamp of the last write
/// ```
///
/// Usage:
/// ```dart
/// StreamBuilder<BinLevels>(
///   stream: BinLevelService.levelsStream(),
///   builder: (context, snapshot) { ... },
/// )
/// ```
class BinLevelService {
  // Path in Firebase Realtime Database where the bridge writes bin data.
  static const String _binStatusPath = 'bin_status';

  static final DatabaseReference _ref =
      FirebaseDatabase.instance.ref(_binStatusPath);

  /// Returns a continuous stream of [BinLevels].
  ///
  /// Each event is emitted whenever the bridge writes new data to Firebase.
  /// If the node does not exist yet, defaults of 0 % are returned.
  static Stream<BinLevels> levelsStream() {
    return _ref.onValue.map((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return BinLevels.zero();
      return BinLevels.fromMap(Map<String, dynamic>.from(data as Map));
    });
  }
}

/// Immutable snapshot of all three bin fill levels (0–100 %).
class BinLevels {
  final int plastic;
  final int paper;
  final int metal;

  const BinLevels({
    required this.plastic,
    required this.paper,
    required this.metal,
  });

  /// All bins empty – used as a safe fallback before Firebase data arrives.
  factory BinLevels.zero() =>
      const BinLevels(plastic: 0, paper: 0, metal: 0);

  /// Parses a Firebase snapshot map. Missing or malformed fields default to 0.
  factory BinLevels.fromMap(Map<String, dynamic> map) {
    int parse(String key) => (map[key] as num?)?.toInt().clamp(0, 100) ?? 0;
    return BinLevels(
      plastic: parse('plastic'),
      paper:   parse('paper'),
      metal:   parse('metal'),
    );
  }
}
