// lib/models/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── CipherTable ─────────────────────────────────────────────────────────────
class CipherTable {
  /// Map from letter (a-z, 0-9, space) → list of possible substitutes
  final Map<String, List<String>> table;
  final String name;
  final String id;
  final DateTime createdAt;

  CipherTable({
    required this.table,
    required this.name,
    required this.id,
    required this.createdAt,
  });

  /// Encode a plaintext message using this table
  String encode(String plaintext) {
    final sb = StringBuffer();
    for (final ch in plaintext.toLowerCase().split('')) {
      if (table.containsKey(ch) && table[ch]!.isNotEmpty) {
        final subs = table[ch]!;
        // pick randomly among substitutes for variation
        subs.shuffle();
        sb.write(subs.first);
      } else {
        sb.write(ch); // passthrough unknown chars
      }
    }
    return sb.toString();
  }

  /// Decode a coded message using the reverse of this table
  String decode(String coded) {
    // Build reverse map: symbol → letter
    final reverse = <String, String>{};
    table.forEach((letter, subs) {
      for (final s in subs) {
        reverse[s] = letter;
      }
    });

    // Greedy longest-match decoding
    final sb = StringBuffer();
    int i = 0;
    while (i < coded.length) {
      bool matched = false;
      // Try longest possible match first (up to 8 runes)
      for (int len = 8; len >= 1; len--) {
        if (i + len > coded.length) continue;
        final candidate = coded.substring(i, i + len);
        if (reverse.containsKey(candidate)) {
          sb.write(reverse[candidate]);
          i += len;
          matched = true;
          break;
        }
      }
      if (!matched) {
        sb.write(coded[i]);
        i++;
      }
    }
    return sb.toString();
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'id': id,
        'createdAt': Timestamp.fromDate(createdAt),
        'table': table,
      };

  factory CipherTable.fromFirestore(Map<String, dynamic> data) => CipherTable(
        name: data['name'] ?? 'Unnamed',
        id: data['id'] ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        table: (data['table'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, List<String>.from(v as List)),
        ),
      );

  CipherTable copyWith({Map<String, List<String>>? table, String? name}) =>
      CipherTable(
        table: table ?? this.table,
        name: name ?? this.name,
        id: id,
        createdAt: createdAt,
      );

  static CipherTable defaultTable() {
    return CipherTable(
      id: 'default',
      name: 'Default Cipher',
      createdAt: DateTime.now(),
      table: {
        'a': ['@', '△'],
        'b': ['β', '8'],
        'c': ['©', '¢'],
        'd': ['∂', 'đ'],
        'e': ['€', '3', 'ε'],
        'f': ['ƒ', 'φ'],
        'g': ['9', 'ğ'],
        'h': ['#', 'η'],
        'i': ['!', '1', 'î'],
        'j': ['ĵ', 'ʝ'],
        'k': ['κ', 'ķ'],
        'l': ['£', '1', 'λ'],
        'm': ['μ', 'ɱ'],
        'n': ['η', 'ñ'],
        'o': ['0', 'θ', 'ø'],
        'p': ['π', 'þ'],
        'q': ['φ', 'q̃'],
        'r': ['®', 'ρ'],
        's': ['§', '$', 'σ'],
        't': ['†', '+', 'τ'],
        'u': ['υ', 'ü'],
        'v': ['√', 'ν'],
        'w': ['ω', 'ψ'],
        'x': ['×', 'χ'],
        'y': ['¥', 'γ'],
        'z': ['ζ', '2'],
        ' ': ['_', '·'],
        '0': ['⓪'],
        '1': ['①'],
        '2': ['②'],
        '3': ['③'],
        '4': ['④'],
        '5': ['⑤'],
        '6': ['⑥'],
        '7': ['⑦'],
        '8': ['⑧'],
        '9': ['⑨'],
      },
    );
  }
}

// ─── AppUser ──────────────────────────────────────────────────────────────────
class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final List<String> friendUids;
  final List<String> pendingFriendRequests; // uids that sent requests to me
  final String? activeCipherTableId;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.friendUids = const [],
    this.pendingFriendRequests = const [],
    this.activeCipherTableId,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data) => AppUser(
        uid: data['uid'] ?? '',
        displayName: data['displayName'] ?? 'Anonymous',
        email: data['email'] ?? '',
        photoUrl: data['photoUrl'],
        friendUids: List<String>.from(data['friendUids'] ?? []),
        pendingFriendRequests:
            List<String>.from(data['pendingFriendRequests'] ?? []),
        activeCipherTableId: data['activeCipherTableId'],
      );

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'friendUids': friendUids,
        'pendingFriendRequests': pendingFriendRequests,
        'activeCipherTableId': activeCipherTableId,
      };
}

// ─── Friend ────────────────────────────────────────────────────────────────
class Friend {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isMutual;

  Friend({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.isMutual,
  });
}
