import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorage {
  SecureStorage._();
  static final SecureStorage _instance = SecureStorage._();
  factory SecureStorage() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Token ──────────────────────────────────────────────────
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.keyAuthToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.keyAuthToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.keyAuthToken);
  }

  // ── Username ───────────────────────────────────────────────
  Future<void> saveUsername(String username) async {
    await _storage.write(key: AppConstants.keyUsername, value: username);
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: AppConstants.keyUsername);
  }

  // ── Base URL ───────────────────────────────────────────────
  Future<void> saveBaseUrl(String url) async {
    await _storage.write(key: AppConstants.keyBaseUrl, value: url);
  }

  Future<String?> getBaseUrl() async {
    return await _storage.read(key: AppConstants.keyBaseUrl);
  }

  // ── Session ────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
