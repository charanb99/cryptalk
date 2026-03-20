// lib/services/app_state.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import 'firestore_service.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();

  AppUser? _currentUser;
  CipherTable? _activeCipherTable;
  List<CipherTable> _cipherTables = [];
  bool _loading = false;

  AppUser? get currentUser => _currentUser;
  CipherTable? get activeCipherTable => _activeCipherTable;
  List<CipherTable> get cipherTables => _cipherTables;
  bool get loading => _loading;

  AppState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _initUserData();
      } else {
        _currentUser = null;
        _activeCipherTable = null;
        _cipherTables = [];
        notifyListeners();
      }
    });
  }

  Future<void> _initUserData() async {
    _loading = true;
    notifyListeners();

    _fs.watchCurrentUser().listen((user) {
      _currentUser = user;
      notifyListeners();
    });

    _fs.watchCipherTables().listen((tables) {
      _cipherTables = tables;
      notifyListeners();
    });

    _activeCipherTable = await _fs.getActiveCipherTable();
    _loading = false;
    notifyListeners();
  }

  Future<void> setActiveCipherTable(CipherTable table) async {
    await _fs.setActiveCipherTable(table.id);
    _activeCipherTable = table;
    notifyListeners();
  }

  /// Encode text using the active cipher table
  String encode(String text) {
    return _activeCipherTable?.encode(text) ??
        CipherTable.defaultTable().encode(text);
  }

  /// Decode text using provided table (or active by default)
  String decode(String text, {CipherTable? withTable}) {
    final table = withTable ?? _activeCipherTable ?? CipherTable.defaultTable();
    return table.decode(text);
  }
}
