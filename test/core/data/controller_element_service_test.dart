import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hisp_mobile_trucker/core/data/controller_element_service.dart';
import 'package:hisp_mobile_trucker/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  const controllerAttr = 'ctrlAttr001';
  const controllerDe = 'controller1'; // "RMNCH - Delivery services..."
  const controlledDe1 = 'controlled1';
  const controlledDe2 = 'controlled2';
  const plainDe = 'plainDe0001';
  const groupUid = 'cgDelivery1';

  Future<void> insertDataElement(String uid) =>
      db.into(db.dataElementsTable).insert(
            DataElementsTableCompanion.insert(
              uid: uid,
              name: uid,
              displayName: uid,
              formName: uid,
              valueType: 'BOOLEAN',
              categoryComboUid: 'catCombo001',
            ),
          );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    await db.into(db.attributesTable).insert(
          AttributesTableCompanion.insert(
            uid: controllerAttr,
            name: 'Controller Data Element Attribute',
            displayName: 'Controller Data Element Attribute',
            valueType: 'TEXT',
          ),
        );

    for (final uid in [controllerDe, controlledDe1, controlledDe2, plainDe]) {
      await insertDataElement(uid);
    }

    // Only the controller carries the attribute, value "true" — same
    // shape as the real metadata sample.
    await db.into(db.attributeValuesTable).insert(
          AttributeValuesTableCompanion.insert(
            objectType: 'dataElement',
            objectUid: controllerDe,
            attributeUid: controllerAttr,
            value: 'true',
          ),
        );

    await db.into(db.dataElementGroupsTable).insert(
          DataElementGroupsTableCompanion.insert(
            uid: groupUid,
            name: 'CG_Delivery Services',
            displayName: 'CG_Delivery Services',
          ),
        );
    for (final uid in [controllerDe, controlledDe1, controlledDe2]) {
      await db.into(db.dataElementGroupMembersTable).insert(
            DataElementGroupMembersTableCompanion.insert(
              dataElementGroupUid: groupUid,
              dataElementUid: uid,
            ),
          );
    }
  });

  tearDown(() => db.close());

  group('ControllerElementService.controllersFor', () {
    test('maps the controller to the OTHER members of its group', () async {
      final gates = await ControllerElementService(db).controllersFor(
          [controllerDe, controlledDe1, controlledDe2, plainDe]);

      expect(gates.keys, [controllerDe]);
      expect(gates[controllerDe], containsAll([controlledDe1, controlledDe2]));
      expect(gates[controllerDe], isNot(contains(controllerDe)),
          reason: 'a controller never gates itself');
      expect(gates[controllerDe], isNot(contains(plainDe)),
          reason: 'plainDe is not in the group, so it is not gated');
    });

    test('an ordinary element (no "true" attribute value) gates nothing',
        () async {
      final gates =
          await ControllerElementService(db).controllersFor([plainDe]);
      expect(gates, isEmpty);
    });

    test(
        'only CONTROLLER identification is scoped to the requested uids — '
        'the group lookup itself is not', () async {
      // Ask about the controller alone; its controlled group members
      // still come back even though they weren't in the input list —
      // harmless, since callers only ever match ids against their own
      // already-scoped element list.
      final gates =
          await ControllerElementService(db).controllersFor([controllerDe]);
      expect(gates[controllerDe], containsAll([controlledDe1, controlledDe2]));
    });

    test(
        'missing "Controller Data Element Attribute" definition gates '
        'nothing', () async {
      await (db.delete(db.attributesTable)
            ..where((t) => t.uid.equals(controllerAttr)))
          .go();
      final gates = await ControllerElementService(db)
          .controllersFor([controllerDe, controlledDe1]);
      expect(gates, isEmpty);
    });
  });
}
