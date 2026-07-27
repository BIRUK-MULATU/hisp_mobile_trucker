import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores an OFFLINE VERIFIER for a user's credentials — never the
/// password itself.
///
/// Verifier = SHA-256( salt : serverUrl : username : password ), with a
/// random per-user salt. Binding the serverUrl means a verifier created
/// against one instance can't validate a login aimed at another.
///
/// The store can CHECK a login offline but cannot RECOVER the password —
/// that's the whole point. Backed by flutter_secure_storage (Android
/// Keystore), so the verifier itself is also encrypted at rest.
class CredentialStore {
  CredentialStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _aOptions = AndroidOptions(encryptedSharedPreferences: true);

  String _saltKey(String userKey) => 'cred_salt_$userKey';
  String _hashKey(String userKey) => 'cred_hash_$userKey';

  /// Called at successful ONLINE login. Persists salt + verifier so the
  /// same user can later log in OFFLINE.
  Future<void> store({
    required String userKey,
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final salt = _randomSalt();
    final hash = _hash(salt, serverUrl, username, password);
    await _storage.write(
        key: _saltKey(userKey), value: salt, aOptions: _aOptions);
    await _storage.write(
        key: _hashKey(userKey), value: hash, aOptions: _aOptions);
  }

  /// Offline verification: recompute and compare. False if no verifier
  /// stored (user never logged in online on this device) or mismatch.
  Future<bool> verify({
    required String userKey,
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final salt =
        await _storage.read(key: _saltKey(userKey), aOptions: _aOptions);
    final stored =
        await _storage.read(key: _hashKey(userKey), aOptions: _aOptions);
    if (salt == null || stored == null) return false;
    final computed = _hash(salt, serverUrl, username, password);
    // Constant-time-ish compare (length is fixed for SHA-256 hex).
    return _constantTimeEquals(computed, stored);
  }

  /// Remove a user's verifier — part of full WIPE, not logout.
  Future<void> clear(String userKey) async {
    await _storage.delete(key: _saltKey(userKey), aOptions: _aOptions);
    await _storage.delete(key: _hashKey(userKey), aOptions: _aOptions);
  }

  Future<bool> hasVerifier(String userKey) async =>
      await _storage.read(key: _hashKey(userKey), aOptions: _aOptions) != null;

  // ── internals ──

  String _hash(String salt, String url, String user, String pass) {
    // Normalise url so trailing-slash differences don't break matching.
    final u = url.replaceAll(RegExp(r'/+$'), '');
    final bytes = utf8.encode('$salt:$u:$user:$pass');
    return sha256.convert(bytes).toString();
  }


  String _randomSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Url.encode(bytes);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
