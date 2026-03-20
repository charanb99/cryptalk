// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ─── User ────────────────────────────────────────────────────────────────

  Stream<AppUser> watchCurrentUser() => _db
      .collection('users')
      .doc(_uid)
      .snapshots()
      .map((s) => AppUser.fromFirestore(s.data()!));

  Future<AppUser?> getUserByEmail(String email) async {
    final q = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return AppUser.fromFirestore(q.docs.first.data());
  }

  Future<AppUser?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc.data()!);
  }

  // ─── Friend System ────────────────────────────────────────────────────────

  Future<void> sendFriendRequest(String targetUid) async {
    // Add my uid to their pendingFriendRequests
    await _db.collection('users').doc(targetUid).update({
      'pendingFriendRequests': FieldValue.arrayUnion([_uid]),
    });
  }

  Future<void> acceptFriendRequest(String requesterUid) async {
    final batch = _db.batch();
    final meRef = _db.collection('users').doc(_uid);
    final themRef = _db.collection('users').doc(requesterUid);

    // Add each other to friendUids
    batch.update(meRef, {
      'friendUids': FieldValue.arrayUnion([requesterUid]),
      'pendingFriendRequests': FieldValue.arrayRemove([requesterUid]),
    });
    batch.update(themRef, {
      'friendUids': FieldValue.arrayUnion([_uid]),
    });

    await batch.commit();
  }

  Future<void> declineFriendRequest(String requesterUid) async {
    await _db.collection('users').doc(_uid).update({
      'pendingFriendRequests': FieldValue.arrayRemove([requesterUid]),
    });
  }

  Future<void> removeFriend(String friendUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(_uid), {
      'friendUids': FieldValue.arrayRemove([friendUid]),
    });
    batch.update(_db.collection('users').doc(friendUid), {
      'friendUids': FieldValue.arrayRemove([_uid]),
    });
    await batch.commit();
  }

  Future<List<AppUser>> getFriends(List<String> uids) async {
    if (uids.isEmpty) return [];
    final futures = uids.map((uid) => getUserById(uid));
    final results = await Future.wait(futures);
    return results.whereType<AppUser>().toList();
  }

  // ─── Cipher Tables ────────────────────────────────────────────────────────

  Stream<List<CipherTable>> watchCipherTables() => _db
      .collection('users')
      .doc(_uid)
      .collection('cipherTables')
      .snapshots()
      .map((s) => s.docs.map((d) => CipherTable.fromFirestore(d.data())).toList());

  Future<void> saveCipherTable(CipherTable table) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('cipherTables')
        .doc(table.id)
        .set(table.toFirestore());
  }

  Future<void> deleteCipherTable(String tableId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('cipherTables')
        .doc(tableId)
        .delete();
  }

  Future<void> setActiveCipherTable(String tableId) async {
    await _db.collection('users').doc(_uid).update({
      'activeCipherTableId': tableId,
    });
  }

  Future<CipherTable?> getActiveCipherTable() async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final data = userDoc.data();
    if (data == null) return null;
    final activeId = data['activeCipherTableId'] as String?;
    if (activeId == null) return null;

    final tableDoc = await _db
        .collection('users')
        .doc(_uid)
        .collection('cipherTables')
        .doc(activeId)
        .get();
    if (!tableDoc.exists) return null;
    return CipherTable.fromFirestore(tableDoc.data()!);
  }

  // ─── Shared Cipher (between friends) ─────────────────────────────────────

  /// Share my active cipher table with a friend (stores in their 'sharedCiphers')
  Future<void> shareCipherWithFriend(String friendUid, CipherTable table) async {
    await _db
        .collection('users')
        .doc(friendUid)
        .collection('sharedCiphers')
        .doc(_uid) // keyed by sharer's uid
        .set({
      ...table.toFirestore(),
      'sharedBy': _uid,
      'sharedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get shared cipher from a friend
  Future<CipherTable?> getSharedCipher(String friendUid) async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('sharedCiphers')
        .doc(friendUid)
        .get();
    if (!doc.exists) return null;
    return CipherTable.fromFirestore(doc.data()!);
  }
}
