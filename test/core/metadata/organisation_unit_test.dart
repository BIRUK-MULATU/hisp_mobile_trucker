import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/database/app_database.dart';
import 'package:hisp_mobile_trucker/core/metadata/organisation_unit.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  // A small realistic hierarchy: National(1) > Region(2) > Zone(3) >
  // Woreda(4) > PHCU(5) > HealthCenter(6) > HealthPost(7).
  Map<String, dynamic> orgUnit(String path) => {
        'id': path.split('/').last,
        'name': 'test',
        'displayName': 'test',
        'path': path,
      };

  const woreda = '/national/region/zone/woreda';
  const phcuA = '$woreda/phcuA';
  const healthCenter = '$phcuA/hc1';
  const healthPost = '$healthCenter/hp1';

  test('with no captureRootLevels configured, everything is valid '
      '(today\'s unbounded behavior)', () {
    final resource = OrgUnitResource(db)..captureRootUids = ['woreda'];
    expect(resource.isValid(orgUnit(healthPost)), isTrue);
  });

  group('with a depth bound configured (Woreda, level 4)', () {
    late OrgUnitResource resource;

    setUp(() {
      resource = OrgUnitResource(db)
        ..captureRootUids = ['woreda']
        ..captureRootLevels = {'woreda': 4};
    });

    test('the capture root itself is valid', () {
      expect(resource.isValid(orgUnit(woreda)), isTrue);
    });

    test('a direct child (PHCU, level 5) is valid', () {
      expect(resource.isValid(orgUnit(phcuA)), isTrue);
    });

    test('a grandchild (Health Center, level 6) is NOT valid', () {
      expect(resource.isValid(orgUnit(healthCenter)), isFalse);
    });

    test('a great-grandchild (Health Post, level 7) is NOT valid', () {
      expect(resource.isValid(orgUnit(healthPost)), isFalse);
    });

    test('an org unit outside the capture root entirely is not valid', () {
      expect(resource.isValid(orgUnit('/national/region/zone/otherWoreda')),
          isFalse);
    });
  });

  test('multiple capture roots at different levels each bound '
      'independently', () {
    final resource = OrgUnitResource(db)
      ..captureRootUids = ['woreda', 'phcuA']
      ..captureRootLevels = {'woreda': 4, 'phcuA': 5};

    // Direct child of the Woreda root.
    expect(resource.isValid(orgUnit(phcuA)), isTrue);
    // Direct child of the PHCU root (even though it's a grandchild of
    // the Woreda root) — valid via the phcuA root's own bound.
    expect(resource.isValid(orgUnit(healthCenter)), isTrue);
    // Grandchild of the PHCU root: too deep even under that bound.
    expect(resource.isValid(orgUnit(healthPost)), isFalse);
  });

  group('pruneOutOfScope', () {
    // Real uid length (11 chars) — the table enforces it.
    const woredaUid = 'woreda00001';
    const phcuUid = 'phcuA000001';
    const hcUid = 'hc1000000A1';
    const hpUid = 'hp1000000A1';

    Future<void> insert(String uid, String path) => db
        .into(db.orgUnitsTable)
        .insert(OrgUnitsTableCompanion.insert(
          uid: uid,
          name: uid,
          displayName: uid,
          path: path,
        ));

    test('deletes already-stored rows that fail the depth bound, keeps '
        'the rest — converges a device synced before the bound existed',
        () async {
      await insert(woredaUid, '/national/region/zone/$woredaUid');
      await insert(phcuUid, '/national/region/zone/$woredaUid/$phcuUid');
      await insert(hcUid,
          '/national/region/zone/$woredaUid/$phcuUid/$hcUid');
      await insert(hpUid,
          '/national/region/zone/$woredaUid/$phcuUid/$hcUid/$hpUid');

      final resource = OrgUnitResource(db)
        ..captureRootUids = [woredaUid]
        ..captureRootLevels = {woredaUid: 4};

      final pruned = await resource.pruneOutOfScope();
      expect(pruned, 2); // health center + health post

      final remaining = await db.select(db.orgUnitsTable).get();
      expect(remaining.map((r) => r.uid), containsAll([woredaUid, phcuUid]));
      expect(remaining.map((r) => r.uid),
          isNot(anyOf(contains(hcUid), contains(hpUid))));
    });

    test('no-op when captureRootLevels is unset', () async {
      await insert(hcUid, '/national/region/zone/$woredaUid/$phcuUid/$hcUid');
      final resource = OrgUnitResource(db)..captureRootUids = [woredaUid];
      expect(await resource.pruneOutOfScope(), 0);
      expect(await db.select(db.orgUnitsTable).get(), hasLength(1));
    });
  });
}
