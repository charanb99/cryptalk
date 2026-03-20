// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create/update user document in Firestore
      await _createOrUpdateUser(userCredential.user!);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _createOrUpdateUser(User user) async {
    final doc = _db.collection('users').doc(user.uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      final appUser = AppUser(
        uid: user.uid,
        displayName: user.displayName ?? 'Anonymous',
        email: user.email ?? '',
        photoUrl: user.photoURL,
      );
      await doc.set(appUser.toFirestore());

      // Also save the default cipher table
      final defaultTable = CipherTable.defaultTable();
      await doc
          .collection('cipherTables')
          .doc(defaultTable.id)
          .set(defaultTable.toFirestore());
      await doc.update({'activeCipherTableId': defaultTable.id});
    } else {
      await doc.update({
        'displayName': user.displayName ?? 'Anonymous',
        'photoUrl': user.photoURL,
      });
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
