/// Integration test -needs a DHIS2 instance running.
///
/// Run: flutter test test/core/database/data_element_roundtrip_test.dart
///

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/metadata/validation_rule.dart';
import 'package:hisp_mobile_trucker/core/network/api_client.dart';

const _baseUrl = '';
const _username = '';
const _password = '';

void main() {
  late AppDatabase db;
  late ApiClient api;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    api = ApiClient.withBasicAuth(
        baseUrl: _baseUrl, username: _username, password: _password);
  });

  tearDown(() async => db.close());

  test('SyncAll pulls every validation Rule in one request; reads are local',
      () async {
    try {
      await api.get('/api/system/info');
    } catch (_) {
      markTestSkipped('DHIS2 is not reachable at $_baseUrl - skipping');
      return;
    }

    final validationRulesResource = ValidationRuleResource(db);

    final count = await validationRulesResource.syncAll(api);

    if (count == 0) {
      markTestSkipped("Instance has no validation Rules - nothing to test.");
      return;
    }

    // 2. Everything below is LOCAL — server could go down now.
    final all = await validationRulesResource.getAll();
    expect(all.length, count, reason: 'every fetched rule must be saved');

    print('');
    print('=== first ${all.length.clamp(0, 3)} rules from SQLite ===');
    for (final r in all.take(3)) {
      print('${r.name}');
      print('   ${r.leftExpression}  ${r.operator}  ${r.rightExpression}');
      print('   importance: ${r.importance ?? '-'}  '
          'periodType: ${r.periodType ?? '-'}');
    }

    // 3. Retrieve specific ones by id — single and batch.
    final one = await validationRulesResource.getById(all.first.uid);
    expect(one!.name, all.first.name);

    final someUids = [for (final r in all.take(2)) r.uid];
    final some = await validationRulesResource.getByIds(someUids);
    expect(some.length, someUids.length);

    // 4. The flattening survived: both sides must carry expressions.
    for (final r in all) {
      expect(r.leftExpression, isNotEmpty,
          reason: '${r.uid} leftSide.expression missing');
      expect(r.rightExpression, isNotEmpty,
          reason: '${r.uid} rightSide.expression missing');
    }

    // 5. Idempotency: a second sync must update, not duplicate.
    final count2 = await validationRulesResource.syncAll(api);
    expect((await validationRulesResource.getAll()).length, count2);
  });
}
