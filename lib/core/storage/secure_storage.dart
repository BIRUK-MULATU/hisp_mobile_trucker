import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();
  static final SecureStorage _instance = SecureStorage._();
  factory SecureStorage() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Legacy token cleanup ───────────────────────────────────
  // The app no longer STORES credentials in any recoverable form
  // (offline login uses a salted hash — see CredentialStore). This
  // delete stays so installs that saved a basic token under an older
  // build get purged on their next 401/logout.
  Future<void> deleteToken() async =>
      await _storage.delete(key: 'auth_token');

  // ── Username ───────────────────────────────────────────────
  Future<void> saveUsername(String username) async =>
      await _storage.write(key: 'username', value: username);

  Future<String?> getUsername() async =>
      await _storage.read(key: 'username');

  // ── Base URL ───────────────────────────────────────────────
  Future<void> saveBaseUrl(String url) async =>
      await _storage.write(key: 'base_url', value: url);

  Future<String?> getBaseUrl() async =>
      await _storage.read(key: 'base_url');

  // ── User Data (includes org units) ─────────────────────────
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(
      key: 'user_data',
      value: jsonEncode(userData),
    );
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: 'user_data');
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // ── Org Units ──────────────────────────────────────────────
  Future<void> saveOrgUnits(List<Map<String, dynamic>> orgUnits) async {
    await _storage.write(
      key: 'org_units',
      value: jsonEncode(orgUnits),
    );
  }

  Future<List<Map<String, dynamic>>> getOrgUnits() async {
    final data = await _storage.read(key: 'org_units');
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getPrimaryOrgUnit() async {
    final orgUnits = await getOrgUnits();
    return orgUnits.isNotEmpty ? orgUnits.first : null;
  }

  // ── Session ────────────────────────────────────────────────

  /// Ends the user session but keeps device settings (server URL).
  Future<void> clearSession() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'user_data');
    await _storage.delete(key: 'org_units');
  }

  Future<void> clearAll() async => await _storage.deleteAll();
}
