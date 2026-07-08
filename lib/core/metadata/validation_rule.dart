import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'metadata_resource.dart';

@DataClassName('ValidationRule')
class ValidationRulesTable extends Table {
  TextColumn get uid => text().withLength(min: 11, max: 11)();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get description => text().nullable()();
  TextColumn get importance => text().nullable()();
  TextColumn get operator => text()();
  TextColumn get instruction => text().nullable()();
  TextColumn get periodType => text().nullable()();

  // leftSide / rightSide flattened (strict 1:1 nesting in the API).
  TextColumn get leftExpression => text()();
  TextColumn get leftDescription => text().nullable()();
  TextColumn get leftMissingValueStrategy => text().nullable()();
  TextColumn get rightExpression => text()();
  TextColumn get rightDescription => text().nullable()();
  TextColumn get rightMissingValueStrategy => text().nullable()();
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}

class ValidationRuleResource extends MetadataResource<ValidationRule> {
  ValidationRuleResource(super.db);

  @override
  String get resource => 'validationRules';

  @override
  List<String> get fields => [
        'id', 'name', 'displayName', 'description', 'importance',
        'operator', 'instruction', 'periodType', 'lastUpdated',
        'leftSide[expression,description,missingValueStrategy]',
        'rightSide[expression,description,missingValueStrategy]',
      ];

  @override
  TableInfo<Table, ValidationRule> get table => db.validationRulesTable;

  @override
  Column<String> get uidColumn => db.validationRulesTable.uid;

  @override
  Column<DateTime> get lastUpdatedColumn => db.validationRulesTable.lastUpdated;

  @override
  Insertable<ValidationRule> companionFromJson(Map<String, dynamic> json) {
    final left = (json['leftSide'] ?? const {}) as Map<String, dynamic>;
    final right = (json['rightSide'] ?? const {}) as Map<String, dynamic>;
    return ValidationRulesTableCompanion.insert(
      uid: json['id'] as String,
      name: json['name'] as String,
      displayName: (json['displayName'] ?? json['name']) as String,
      description: Value(json['description'] as String?),
      importance: Value(json['importance'] as String?),
      operator: json['operator'] as String,
      instruction: Value(json['instruction'] as String?),
      periodType: Value(json['periodType'] as String?),
      leftExpression: left['expression'] as String? ?? '',
      leftDescription: Value(left['description'] as String?),
      leftMissingValueStrategy:
          Value(left['missingValueStrategy'] as String?),
      rightExpression: right['expression'] as String? ?? '',
      rightDescription: Value(right['description'] as String?),
      rightMissingValueStrategy:
          Value(right['missingValueStrategy'] as String?),
      lastUpdated: lastUpdatedFrom(json),
    );
  }
}
