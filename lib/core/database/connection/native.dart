import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// [userKey] must already be sanitized (AppDatabase.sanitizeUserKey).
QueryExecutor openConnectionFor(String userKey) {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'hisp_$userKey.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// True if this user has logged in on this device before (their
/// database file exists) — the gate for allowing OFFLINE login.
Future<bool> databaseExistsFor(String userKey) async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, 'hisp_$userKey.sqlite')).exists();
}

/// Delete a user's database file(s) entirely — part of WIPE. Removes the
/// main file plus WAL/SHM sidecars left by WAL journal mode.
Future<void> deleteDatabaseFor(String userKey) async {
  final dir = await getApplicationDocumentsDirectory();
  final base = p.join(dir.path, 'hisp_$userKey.sqlite');
  for (final suffix in ['', '-wal', '-shm']) {
    final f = File('$base$suffix');
    if (await f.exists()) await f.delete();
  }
}
