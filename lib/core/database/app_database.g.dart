// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OrgUnitsTableTable extends OrgUnitsTable
    with TableInfo<$OrgUnitsTableTable, OrgUnit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrgUnitsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentUidMeta =
      const VerificationMeta('parentUid');
  @override
  late final GeneratedColumn<String> parentUid = GeneratedColumn<String>(
      'parent_uid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parentNameMeta =
      const VerificationMeta('parentName');
  @override
  late final GeneratedColumn<String> parentName = GeneratedColumn<String>(
      'parent_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _openingDateMeta =
      const VerificationMeta('openingDate');
  @override
  late final GeneratedColumn<String> openingDate = GeneratedColumn<String>(
      'opening_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _closedDateMeta =
      const VerificationMeta('closedDate');
  @override
  late final GeneratedColumn<String> closedDate = GeneratedColumn<String>(
      'closed_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isUserCaptureRootMeta =
      const VerificationMeta('isUserCaptureRoot');
  @override
  late final GeneratedColumn<bool> isUserCaptureRoot = GeneratedColumn<bool>(
      'is_user_capture_root', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_user_capture_root" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        uid,
        name,
        displayName,
        parentUid,
        parentName,
        path,
        code,
        openingDate,
        closedDate,
        lastUpdated,
        isUserCaptureRoot
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'org_units_table';
  @override
  VerificationContext validateIntegrity(Insertable<OrgUnit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('parent_uid')) {
      context.handle(_parentUidMeta,
          parentUid.isAcceptableOrUnknown(data['parent_uid']!, _parentUidMeta));
    }
    if (data.containsKey('parent_name')) {
      context.handle(
          _parentNameMeta,
          parentName.isAcceptableOrUnknown(
              data['parent_name']!, _parentNameMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    }
    if (data.containsKey('opening_date')) {
      context.handle(
          _openingDateMeta,
          openingDate.isAcceptableOrUnknown(
              data['opening_date']!, _openingDateMeta));
    }
    if (data.containsKey('closed_date')) {
      context.handle(
          _closedDateMeta,
          closedDate.isAcceptableOrUnknown(
              data['closed_date']!, _closedDateMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    if (data.containsKey('is_user_capture_root')) {
      context.handle(
          _isUserCaptureRootMeta,
          isUserCaptureRoot.isAcceptableOrUnknown(
              data['is_user_capture_root']!, _isUserCaptureRootMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  OrgUnit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrgUnit(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      parentUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_uid']),
      parentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_name']),
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code']),
      openingDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}opening_date']),
      closedDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}closed_date']),
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
      isUserCaptureRoot: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_user_capture_root'])!,
    );
  }

  @override
  $OrgUnitsTableTable createAlias(String alias) {
    return $OrgUnitsTableTable(attachedDatabase, alias);
  }
}

class OrgUnit extends DataClass implements Insertable<OrgUnit> {
  final String uid;
  final String name;
  final String displayName;
  final String? parentUid;
  final String? parentName;
  final String path;
  final String? code;
  final String? openingDate;
  final String? closedDate;
  final DateTime? lastUpdated;

  /// True for the roots of the logged-in user's capture tree
  /// (set from /api/me by the sync service, not by this resource).
  final bool isUserCaptureRoot;
  const OrgUnit(
      {required this.uid,
      required this.name,
      required this.displayName,
      this.parentUid,
      this.parentName,
      required this.path,
      this.code,
      this.openingDate,
      this.closedDate,
      this.lastUpdated,
      required this.isUserCaptureRoot});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || parentUid != null) {
      map['parent_uid'] = Variable<String>(parentUid);
    }
    if (!nullToAbsent || parentName != null) {
      map['parent_name'] = Variable<String>(parentName);
    }
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    if (!nullToAbsent || openingDate != null) {
      map['opening_date'] = Variable<String>(openingDate);
    }
    if (!nullToAbsent || closedDate != null) {
      map['closed_date'] = Variable<String>(closedDate);
    }
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    map['is_user_capture_root'] = Variable<bool>(isUserCaptureRoot);
    return map;
  }

  OrgUnitsTableCompanion toCompanion(bool nullToAbsent) {
    return OrgUnitsTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      parentUid: parentUid == null && nullToAbsent
          ? const Value.absent()
          : Value(parentUid),
      parentName: parentName == null && nullToAbsent
          ? const Value.absent()
          : Value(parentName),
      path: Value(path),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      openingDate: openingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(openingDate),
      closedDate: closedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(closedDate),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
      isUserCaptureRoot: Value(isUserCaptureRoot),
    );
  }

  factory OrgUnit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrgUnit(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      parentUid: serializer.fromJson<String?>(json['parentUid']),
      parentName: serializer.fromJson<String?>(json['parentName']),
      path: serializer.fromJson<String>(json['path']),
      code: serializer.fromJson<String?>(json['code']),
      openingDate: serializer.fromJson<String?>(json['openingDate']),
      closedDate: serializer.fromJson<String?>(json['closedDate']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
      isUserCaptureRoot: serializer.fromJson<bool>(json['isUserCaptureRoot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'parentUid': serializer.toJson<String?>(parentUid),
      'parentName': serializer.toJson<String?>(parentName),
      'path': serializer.toJson<String>(path),
      'code': serializer.toJson<String?>(code),
      'openingDate': serializer.toJson<String?>(openingDate),
      'closedDate': serializer.toJson<String?>(closedDate),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
      'isUserCaptureRoot': serializer.toJson<bool>(isUserCaptureRoot),
    };
  }

  OrgUnit copyWith(
          {String? uid,
          String? name,
          String? displayName,
          Value<String?> parentUid = const Value.absent(),
          Value<String?> parentName = const Value.absent(),
          String? path,
          Value<String?> code = const Value.absent(),
          Value<String?> openingDate = const Value.absent(),
          Value<String?> closedDate = const Value.absent(),
          Value<DateTime?> lastUpdated = const Value.absent(),
          bool? isUserCaptureRoot}) =>
      OrgUnit(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        parentUid: parentUid.present ? parentUid.value : this.parentUid,
        parentName: parentName.present ? parentName.value : this.parentName,
        path: path ?? this.path,
        code: code.present ? code.value : this.code,
        openingDate: openingDate.present ? openingDate.value : this.openingDate,
        closedDate: closedDate.present ? closedDate.value : this.closedDate,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
        isUserCaptureRoot: isUserCaptureRoot ?? this.isUserCaptureRoot,
      );
  OrgUnit copyWithCompanion(OrgUnitsTableCompanion data) {
    return OrgUnit(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      parentUid: data.parentUid.present ? data.parentUid.value : this.parentUid,
      parentName:
          data.parentName.present ? data.parentName.value : this.parentName,
      path: data.path.present ? data.path.value : this.path,
      code: data.code.present ? data.code.value : this.code,
      openingDate:
          data.openingDate.present ? data.openingDate.value : this.openingDate,
      closedDate:
          data.closedDate.present ? data.closedDate.value : this.closedDate,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
      isUserCaptureRoot: data.isUserCaptureRoot.present
          ? data.isUserCaptureRoot.value
          : this.isUserCaptureRoot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrgUnit(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('parentUid: $parentUid, ')
          ..write('parentName: $parentName, ')
          ..write('path: $path, ')
          ..write('code: $code, ')
          ..write('openingDate: $openingDate, ')
          ..write('closedDate: $closedDate, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('isUserCaptureRoot: $isUserCaptureRoot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, name, displayName, parentUid, parentName,
      path, code, openingDate, closedDate, lastUpdated, isUserCaptureRoot);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrgUnit &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.parentUid == this.parentUid &&
          other.parentName == this.parentName &&
          other.path == this.path &&
          other.code == this.code &&
          other.openingDate == this.openingDate &&
          other.closedDate == this.closedDate &&
          other.lastUpdated == this.lastUpdated &&
          other.isUserCaptureRoot == this.isUserCaptureRoot);
}

class OrgUnitsTableCompanion extends UpdateCompanion<OrgUnit> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String?> parentUid;
  final Value<String?> parentName;
  final Value<String> path;
  final Value<String?> code;
  final Value<String?> openingDate;
  final Value<String?> closedDate;
  final Value<DateTime?> lastUpdated;
  final Value<bool> isUserCaptureRoot;
  final Value<int> rowid;
  const OrgUnitsTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.parentUid = const Value.absent(),
    this.parentName = const Value.absent(),
    this.path = const Value.absent(),
    this.code = const Value.absent(),
    this.openingDate = const Value.absent(),
    this.closedDate = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.isUserCaptureRoot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrgUnitsTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    this.parentUid = const Value.absent(),
    this.parentName = const Value.absent(),
    required String path,
    this.code = const Value.absent(),
    this.openingDate = const Value.absent(),
    this.closedDate = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.isUserCaptureRoot = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName),
        path = Value(path);
  static Insertable<OrgUnit> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? parentUid,
    Expression<String>? parentName,
    Expression<String>? path,
    Expression<String>? code,
    Expression<String>? openingDate,
    Expression<String>? closedDate,
    Expression<DateTime>? lastUpdated,
    Expression<bool>? isUserCaptureRoot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (parentUid != null) 'parent_uid': parentUid,
      if (parentName != null) 'parent_name': parentName,
      if (path != null) 'path': path,
      if (code != null) 'code': code,
      if (openingDate != null) 'opening_date': openingDate,
      if (closedDate != null) 'closed_date': closedDate,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (isUserCaptureRoot != null) 'is_user_capture_root': isUserCaptureRoot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrgUnitsTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<String?>? parentUid,
      Value<String?>? parentName,
      Value<String>? path,
      Value<String?>? code,
      Value<String?>? openingDate,
      Value<String?>? closedDate,
      Value<DateTime?>? lastUpdated,
      Value<bool>? isUserCaptureRoot,
      Value<int>? rowid}) {
    return OrgUnitsTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      parentUid: parentUid ?? this.parentUid,
      parentName: parentName ?? this.parentName,
      path: path ?? this.path,
      code: code ?? this.code,
      openingDate: openingDate ?? this.openingDate,
      closedDate: closedDate ?? this.closedDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isUserCaptureRoot: isUserCaptureRoot ?? this.isUserCaptureRoot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (parentUid.present) {
      map['parent_uid'] = Variable<String>(parentUid.value);
    }
    if (parentName.present) {
      map['parent_name'] = Variable<String>(parentName.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (openingDate.present) {
      map['opening_date'] = Variable<String>(openingDate.value);
    }
    if (closedDate.present) {
      map['closed_date'] = Variable<String>(closedDate.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (isUserCaptureRoot.present) {
      map['is_user_capture_root'] = Variable<bool>(isUserCaptureRoot.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrgUnitsTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('parentUid: $parentUid, ')
          ..write('parentName: $parentName, ')
          ..write('path: $path, ')
          ..write('code: $code, ')
          ..write('openingDate: $openingDate, ')
          ..write('closedDate: $closedDate, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('isUserCaptureRoot: $isUserCaptureRoot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DataSetsTableTable extends DataSetsTable
    with TableInfo<$DataSetsTableTable, DataSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DataSetsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _periodTypeMeta =
      const VerificationMeta('periodType');
  @override
  late final GeneratedColumn<String> periodType = GeneratedColumn<String>(
      'period_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _categoryComboUidMeta =
      const VerificationMeta('categoryComboUid');
  @override
  late final GeneratedColumn<String> categoryComboUid = GeneratedColumn<String>(
      'category_combo_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _openFuturePeriodsMeta =
      const VerificationMeta('openFuturePeriods');
  @override
  late final GeneratedColumn<int> openFuturePeriods = GeneratedColumn<int>(
      'open_future_periods', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _expiryDaysMeta =
      const VerificationMeta('expiryDays');
  @override
  late final GeneratedColumn<int> expiryDays = GeneratedColumn<int>(
      'expiry_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        uid,
        name,
        displayName,
        periodType,
        version,
        categoryComboUid,
        openFuturePeriods,
        expiryDays,
        lastUpdated
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'data_sets_table';
  @override
  VerificationContext validateIntegrity(Insertable<DataSet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('period_type')) {
      context.handle(
          _periodTypeMeta,
          periodType.isAcceptableOrUnknown(
              data['period_type']!, _periodTypeMeta));
    } else if (isInserting) {
      context.missing(_periodTypeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('category_combo_uid')) {
      context.handle(
          _categoryComboUidMeta,
          categoryComboUid.isAcceptableOrUnknown(
              data['category_combo_uid']!, _categoryComboUidMeta));
    } else if (isInserting) {
      context.missing(_categoryComboUidMeta);
    }
    if (data.containsKey('open_future_periods')) {
      context.handle(
          _openFuturePeriodsMeta,
          openFuturePeriods.isAcceptableOrUnknown(
              data['open_future_periods']!, _openFuturePeriodsMeta));
    }
    if (data.containsKey('expiry_days')) {
      context.handle(
          _expiryDaysMeta,
          expiryDays.isAcceptableOrUnknown(
              data['expiry_days']!, _expiryDaysMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DataSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DataSet(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      periodType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}period_type'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      categoryComboUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}category_combo_uid'])!,
      openFuturePeriods: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}open_future_periods'])!,
      expiryDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expiry_days'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $DataSetsTableTable createAlias(String alias) {
    return $DataSetsTableTable(attachedDatabase, alias);
  }
}

class DataSet extends DataClass implements Insertable<DataSet> {
  final String uid;
  final String name;
  final String displayName;
  final String periodType;
  final int version;
  final String categoryComboUid;
  final int openFuturePeriods;
  final int expiryDays;
  final DateTime? lastUpdated;
  const DataSet(
      {required this.uid,
      required this.name,
      required this.displayName,
      required this.periodType,
      required this.version,
      required this.categoryComboUid,
      required this.openFuturePeriods,
      required this.expiryDays,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    map['period_type'] = Variable<String>(periodType);
    map['version'] = Variable<int>(version);
    map['category_combo_uid'] = Variable<String>(categoryComboUid);
    map['open_future_periods'] = Variable<int>(openFuturePeriods);
    map['expiry_days'] = Variable<int>(expiryDays);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  DataSetsTableCompanion toCompanion(bool nullToAbsent) {
    return DataSetsTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      periodType: Value(periodType),
      version: Value(version),
      categoryComboUid: Value(categoryComboUid),
      openFuturePeriods: Value(openFuturePeriods),
      expiryDays: Value(expiryDays),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory DataSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DataSet(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      periodType: serializer.fromJson<String>(json['periodType']),
      version: serializer.fromJson<int>(json['version']),
      categoryComboUid: serializer.fromJson<String>(json['categoryComboUid']),
      openFuturePeriods: serializer.fromJson<int>(json['openFuturePeriods']),
      expiryDays: serializer.fromJson<int>(json['expiryDays']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'periodType': serializer.toJson<String>(periodType),
      'version': serializer.toJson<int>(version),
      'categoryComboUid': serializer.toJson<String>(categoryComboUid),
      'openFuturePeriods': serializer.toJson<int>(openFuturePeriods),
      'expiryDays': serializer.toJson<int>(expiryDays),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  DataSet copyWith(
          {String? uid,
          String? name,
          String? displayName,
          String? periodType,
          int? version,
          String? categoryComboUid,
          int? openFuturePeriods,
          int? expiryDays,
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      DataSet(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        periodType: periodType ?? this.periodType,
        version: version ?? this.version,
        categoryComboUid: categoryComboUid ?? this.categoryComboUid,
        openFuturePeriods: openFuturePeriods ?? this.openFuturePeriods,
        expiryDays: expiryDays ?? this.expiryDays,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  DataSet copyWithCompanion(DataSetsTableCompanion data) {
    return DataSet(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      periodType:
          data.periodType.present ? data.periodType.value : this.periodType,
      version: data.version.present ? data.version.value : this.version,
      categoryComboUid: data.categoryComboUid.present
          ? data.categoryComboUid.value
          : this.categoryComboUid,
      openFuturePeriods: data.openFuturePeriods.present
          ? data.openFuturePeriods.value
          : this.openFuturePeriods,
      expiryDays:
          data.expiryDays.present ? data.expiryDays.value : this.expiryDays,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DataSet(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('periodType: $periodType, ')
          ..write('version: $version, ')
          ..write('categoryComboUid: $categoryComboUid, ')
          ..write('openFuturePeriods: $openFuturePeriods, ')
          ..write('expiryDays: $expiryDays, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, name, displayName, periodType, version,
      categoryComboUid, openFuturePeriods, expiryDays, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataSet &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.periodType == this.periodType &&
          other.version == this.version &&
          other.categoryComboUid == this.categoryComboUid &&
          other.openFuturePeriods == this.openFuturePeriods &&
          other.expiryDays == this.expiryDays &&
          other.lastUpdated == this.lastUpdated);
}

class DataSetsTableCompanion extends UpdateCompanion<DataSet> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String> periodType;
  final Value<int> version;
  final Value<String> categoryComboUid;
  final Value<int> openFuturePeriods;
  final Value<int> expiryDays;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const DataSetsTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.periodType = const Value.absent(),
    this.version = const Value.absent(),
    this.categoryComboUid = const Value.absent(),
    this.openFuturePeriods = const Value.absent(),
    this.expiryDays = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DataSetsTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    required String periodType,
    this.version = const Value.absent(),
    required String categoryComboUid,
    this.openFuturePeriods = const Value.absent(),
    this.expiryDays = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName),
        periodType = Value(periodType),
        categoryComboUid = Value(categoryComboUid);
  static Insertable<DataSet> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? periodType,
    Expression<int>? version,
    Expression<String>? categoryComboUid,
    Expression<int>? openFuturePeriods,
    Expression<int>? expiryDays,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (periodType != null) 'period_type': periodType,
      if (version != null) 'version': version,
      if (categoryComboUid != null) 'category_combo_uid': categoryComboUid,
      if (openFuturePeriods != null) 'open_future_periods': openFuturePeriods,
      if (expiryDays != null) 'expiry_days': expiryDays,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DataSetsTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<String>? periodType,
      Value<int>? version,
      Value<String>? categoryComboUid,
      Value<int>? openFuturePeriods,
      Value<int>? expiryDays,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return DataSetsTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      periodType: periodType ?? this.periodType,
      version: version ?? this.version,
      categoryComboUid: categoryComboUid ?? this.categoryComboUid,
      openFuturePeriods: openFuturePeriods ?? this.openFuturePeriods,
      expiryDays: expiryDays ?? this.expiryDays,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (periodType.present) {
      map['period_type'] = Variable<String>(periodType.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (categoryComboUid.present) {
      map['category_combo_uid'] = Variable<String>(categoryComboUid.value);
    }
    if (openFuturePeriods.present) {
      map['open_future_periods'] = Variable<int>(openFuturePeriods.value);
    }
    if (expiryDays.present) {
      map['expiry_days'] = Variable<int>(expiryDays.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DataSetsTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('periodType: $periodType, ')
          ..write('version: $version, ')
          ..write('categoryComboUid: $categoryComboUid, ')
          ..write('openFuturePeriods: $openFuturePeriods, ')
          ..write('expiryDays: $expiryDays, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DataElementsTableTable extends DataElementsTable
    with TableInfo<$DataElementsTableTable, DataElement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DataElementsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _formNameMeta =
      const VerificationMeta('formName');
  @override
  late final GeneratedColumn<String> formName = GeneratedColumn<String>(
      'form_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _valueTypeMeta =
      const VerificationMeta('valueType');
  @override
  late final GeneratedColumn<String> valueType = GeneratedColumn<String>(
      'value_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryComboUidMeta =
      const VerificationMeta('categoryComboUid');
  @override
  late final GeneratedColumn<String> categoryComboUid = GeneratedColumn<String>(
      'category_combo_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _optionSetUidMeta =
      const VerificationMeta('optionSetUid');
  @override
  late final GeneratedColumn<String> optionSetUid = GeneratedColumn<String>(
      'option_set_uid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        uid,
        name,
        displayName,
        formName,
        description,
        valueType,
        categoryComboUid,
        optionSetUid,
        lastUpdated
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'data_elements_table';
  @override
  VerificationContext validateIntegrity(Insertable<DataElement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('form_name')) {
      context.handle(_formNameMeta,
          formName.isAcceptableOrUnknown(data['form_name']!, _formNameMeta));
    } else if (isInserting) {
      context.missing(_formNameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('value_type')) {
      context.handle(_valueTypeMeta,
          valueType.isAcceptableOrUnknown(data['value_type']!, _valueTypeMeta));
    } else if (isInserting) {
      context.missing(_valueTypeMeta);
    }
    if (data.containsKey('category_combo_uid')) {
      context.handle(
          _categoryComboUidMeta,
          categoryComboUid.isAcceptableOrUnknown(
              data['category_combo_uid']!, _categoryComboUidMeta));
    } else if (isInserting) {
      context.missing(_categoryComboUidMeta);
    }
    if (data.containsKey('option_set_uid')) {
      context.handle(
          _optionSetUidMeta,
          optionSetUid.isAcceptableOrUnknown(
              data['option_set_uid']!, _optionSetUidMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DataElement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DataElement(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      formName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}form_name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      valueType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value_type'])!,
      categoryComboUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}category_combo_uid'])!,
      optionSetUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}option_set_uid']),
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $DataElementsTableTable createAlias(String alias) {
    return $DataElementsTableTable(attachedDatabase, alias);
  }
}

class DataElement extends DataClass implements Insertable<DataElement> {
  final String uid;
  final String name;
  final String displayName;
  final String formName;
  final String? description;
  final String valueType;
  final String categoryComboUid;
  final String? optionSetUid;
  final DateTime? lastUpdated;
  const DataElement(
      {required this.uid,
      required this.name,
      required this.displayName,
      required this.formName,
      this.description,
      required this.valueType,
      required this.categoryComboUid,
      this.optionSetUid,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    map['form_name'] = Variable<String>(formName);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['value_type'] = Variable<String>(valueType);
    map['category_combo_uid'] = Variable<String>(categoryComboUid);
    if (!nullToAbsent || optionSetUid != null) {
      map['option_set_uid'] = Variable<String>(optionSetUid);
    }
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  DataElementsTableCompanion toCompanion(bool nullToAbsent) {
    return DataElementsTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      formName: Value(formName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      valueType: Value(valueType),
      categoryComboUid: Value(categoryComboUid),
      optionSetUid: optionSetUid == null && nullToAbsent
          ? const Value.absent()
          : Value(optionSetUid),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory DataElement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DataElement(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      formName: serializer.fromJson<String>(json['formName']),
      description: serializer.fromJson<String?>(json['description']),
      valueType: serializer.fromJson<String>(json['valueType']),
      categoryComboUid: serializer.fromJson<String>(json['categoryComboUid']),
      optionSetUid: serializer.fromJson<String?>(json['optionSetUid']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'formName': serializer.toJson<String>(formName),
      'description': serializer.toJson<String?>(description),
      'valueType': serializer.toJson<String>(valueType),
      'categoryComboUid': serializer.toJson<String>(categoryComboUid),
      'optionSetUid': serializer.toJson<String?>(optionSetUid),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  DataElement copyWith(
          {String? uid,
          String? name,
          String? displayName,
          String? formName,
          Value<String?> description = const Value.absent(),
          String? valueType,
          String? categoryComboUid,
          Value<String?> optionSetUid = const Value.absent(),
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      DataElement(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        formName: formName ?? this.formName,
        description: description.present ? description.value : this.description,
        valueType: valueType ?? this.valueType,
        categoryComboUid: categoryComboUid ?? this.categoryComboUid,
        optionSetUid:
            optionSetUid.present ? optionSetUid.value : this.optionSetUid,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  DataElement copyWithCompanion(DataElementsTableCompanion data) {
    return DataElement(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      formName: data.formName.present ? data.formName.value : this.formName,
      description:
          data.description.present ? data.description.value : this.description,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
      categoryComboUid: data.categoryComboUid.present
          ? data.categoryComboUid.value
          : this.categoryComboUid,
      optionSetUid: data.optionSetUid.present
          ? data.optionSetUid.value
          : this.optionSetUid,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DataElement(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('formName: $formName, ')
          ..write('description: $description, ')
          ..write('valueType: $valueType, ')
          ..write('categoryComboUid: $categoryComboUid, ')
          ..write('optionSetUid: $optionSetUid, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, name, displayName, formName, description,
      valueType, categoryComboUid, optionSetUid, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataElement &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.formName == this.formName &&
          other.description == this.description &&
          other.valueType == this.valueType &&
          other.categoryComboUid == this.categoryComboUid &&
          other.optionSetUid == this.optionSetUid &&
          other.lastUpdated == this.lastUpdated);
}

class DataElementsTableCompanion extends UpdateCompanion<DataElement> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String> formName;
  final Value<String?> description;
  final Value<String> valueType;
  final Value<String> categoryComboUid;
  final Value<String?> optionSetUid;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const DataElementsTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.formName = const Value.absent(),
    this.description = const Value.absent(),
    this.valueType = const Value.absent(),
    this.categoryComboUid = const Value.absent(),
    this.optionSetUid = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DataElementsTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    required String formName,
    this.description = const Value.absent(),
    required String valueType,
    required String categoryComboUid,
    this.optionSetUid = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName),
        formName = Value(formName),
        valueType = Value(valueType),
        categoryComboUid = Value(categoryComboUid);
  static Insertable<DataElement> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? formName,
    Expression<String>? description,
    Expression<String>? valueType,
    Expression<String>? categoryComboUid,
    Expression<String>? optionSetUid,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (formName != null) 'form_name': formName,
      if (description != null) 'description': description,
      if (valueType != null) 'value_type': valueType,
      if (categoryComboUid != null) 'category_combo_uid': categoryComboUid,
      if (optionSetUid != null) 'option_set_uid': optionSetUid,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DataElementsTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<String>? formName,
      Value<String?>? description,
      Value<String>? valueType,
      Value<String>? categoryComboUid,
      Value<String?>? optionSetUid,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return DataElementsTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      formName: formName ?? this.formName,
      description: description ?? this.description,
      valueType: valueType ?? this.valueType,
      categoryComboUid: categoryComboUid ?? this.categoryComboUid,
      optionSetUid: optionSetUid ?? this.optionSetUid,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (formName.present) {
      map['form_name'] = Variable<String>(formName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (valueType.present) {
      map['value_type'] = Variable<String>(valueType.value);
    }
    if (categoryComboUid.present) {
      map['category_combo_uid'] = Variable<String>(categoryComboUid.value);
    }
    if (optionSetUid.present) {
      map['option_set_uid'] = Variable<String>(optionSetUid.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DataElementsTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('formName: $formName, ')
          ..write('description: $description, ')
          ..write('valueType: $valueType, ')
          ..write('categoryComboUid: $categoryComboUid, ')
          ..write('optionSetUid: $optionSetUid, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SectionsTableTable extends SectionsTable
    with TableInfo<$SectionsTableTable, Section> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataSetUidMeta =
      const VerificationMeta('dataSetUid');
  @override
  late final GeneratedColumn<String> dataSetUid = GeneratedColumn<String>(
      'data_set_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, name, displayName, dataSetUid, sortOrder, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sections_table';
  @override
  VerificationContext validateIntegrity(Insertable<Section> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('data_set_uid')) {
      context.handle(
          _dataSetUidMeta,
          dataSetUid.isAcceptableOrUnknown(
              data['data_set_uid']!, _dataSetUidMeta));
    } else if (isInserting) {
      context.missing(_dataSetUidMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  Section map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Section(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      dataSetUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_set_uid'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $SectionsTableTable createAlias(String alias) {
    return $SectionsTableTable(attachedDatabase, alias);
  }
}

class Section extends DataClass implements Insertable<Section> {
  final String uid;
  final String name;
  final String displayName;
  final String dataSetUid;
  final int sortOrder;
  final DateTime? lastUpdated;
  const Section(
      {required this.uid,
      required this.name,
      required this.displayName,
      required this.dataSetUid,
      required this.sortOrder,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    map['data_set_uid'] = Variable<String>(dataSetUid);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  SectionsTableCompanion toCompanion(bool nullToAbsent) {
    return SectionsTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      dataSetUid: Value(dataSetUid),
      sortOrder: Value(sortOrder),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory Section.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Section(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      dataSetUid: serializer.fromJson<String>(json['dataSetUid']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'dataSetUid': serializer.toJson<String>(dataSetUid),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  Section copyWith(
          {String? uid,
          String? name,
          String? displayName,
          String? dataSetUid,
          int? sortOrder,
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      Section(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        dataSetUid: dataSetUid ?? this.dataSetUid,
        sortOrder: sortOrder ?? this.sortOrder,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  Section copyWithCompanion(SectionsTableCompanion data) {
    return Section(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      dataSetUid:
          data.dataSetUid.present ? data.dataSetUid.value : this.dataSetUid,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Section(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('dataSetUid: $dataSetUid, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uid, name, displayName, dataSetUid, sortOrder, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Section &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.dataSetUid == this.dataSetUid &&
          other.sortOrder == this.sortOrder &&
          other.lastUpdated == this.lastUpdated);
}

class SectionsTableCompanion extends UpdateCompanion<Section> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String> dataSetUid;
  final Value<int> sortOrder;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const SectionsTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.dataSetUid = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SectionsTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    required String dataSetUid,
    this.sortOrder = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName),
        dataSetUid = Value(dataSetUid);
  static Insertable<Section> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? dataSetUid,
    Expression<int>? sortOrder,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (dataSetUid != null) 'data_set_uid': dataSetUid,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SectionsTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<String>? dataSetUid,
      Value<int>? sortOrder,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return SectionsTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      dataSetUid: dataSetUid ?? this.dataSetUid,
      sortOrder: sortOrder ?? this.sortOrder,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (dataSetUid.present) {
      map['data_set_uid'] = Variable<String>(dataSetUid.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectionsTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('dataSetUid: $dataSetUid, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IndicatorsTableTable extends IndicatorsTable
    with TableInfo<$IndicatorsTableTable, Indicator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IndicatorsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numeratorMeta =
      const VerificationMeta('numerator');
  @override
  late final GeneratedColumn<String> numerator = GeneratedColumn<String>(
      'numerator', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _denominatorMeta =
      const VerificationMeta('denominator');
  @override
  late final GeneratedColumn<String> denominator = GeneratedColumn<String>(
      'denominator', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _indicatorTypeFactorMeta =
      const VerificationMeta('indicatorTypeFactor');
  @override
  late final GeneratedColumn<int> indicatorTypeFactor = GeneratedColumn<int>(
      'indicator_type_factor', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _annualizedMeta =
      const VerificationMeta('annualized');
  @override
  late final GeneratedColumn<bool> annualized = GeneratedColumn<bool>(
      'annualized', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("annualized" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        uid,
        name,
        displayName,
        numerator,
        denominator,
        description,
        indicatorTypeFactor,
        annualized,
        lastUpdated
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'indicators_table';
  @override
  VerificationContext validateIntegrity(Insertable<Indicator> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('numerator')) {
      context.handle(_numeratorMeta,
          numerator.isAcceptableOrUnknown(data['numerator']!, _numeratorMeta));
    } else if (isInserting) {
      context.missing(_numeratorMeta);
    }
    if (data.containsKey('denominator')) {
      context.handle(
          _denominatorMeta,
          denominator.isAcceptableOrUnknown(
              data['denominator']!, _denominatorMeta));
    } else if (isInserting) {
      context.missing(_denominatorMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('indicator_type_factor')) {
      context.handle(
          _indicatorTypeFactorMeta,
          indicatorTypeFactor.isAcceptableOrUnknown(
              data['indicator_type_factor']!, _indicatorTypeFactorMeta));
    }
    if (data.containsKey('annualized')) {
      context.handle(
          _annualizedMeta,
          annualized.isAcceptableOrUnknown(
              data['annualized']!, _annualizedMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  Indicator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Indicator(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      numerator: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}numerator'])!,
      denominator: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}denominator'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      indicatorTypeFactor: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}indicator_type_factor'])!,
      annualized: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}annualized'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $IndicatorsTableTable createAlias(String alias) {
    return $IndicatorsTableTable(attachedDatabase, alias);
  }
}

class Indicator extends DataClass implements Insertable<Indicator> {
  final String uid;
  final String name;
  final String displayName;
  final String numerator;
  final String denominator;
  final String? description;
  final int indicatorTypeFactor;
  final bool annualized;
  final DateTime? lastUpdated;
  const Indicator(
      {required this.uid,
      required this.name,
      required this.displayName,
      required this.numerator,
      required this.denominator,
      this.description,
      required this.indicatorTypeFactor,
      required this.annualized,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    map['numerator'] = Variable<String>(numerator);
    map['denominator'] = Variable<String>(denominator);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['indicator_type_factor'] = Variable<int>(indicatorTypeFactor);
    map['annualized'] = Variable<bool>(annualized);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  IndicatorsTableCompanion toCompanion(bool nullToAbsent) {
    return IndicatorsTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      numerator: Value(numerator),
      denominator: Value(denominator),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      indicatorTypeFactor: Value(indicatorTypeFactor),
      annualized: Value(annualized),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory Indicator.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Indicator(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      numerator: serializer.fromJson<String>(json['numerator']),
      denominator: serializer.fromJson<String>(json['denominator']),
      description: serializer.fromJson<String?>(json['description']),
      indicatorTypeFactor:
          serializer.fromJson<int>(json['indicatorTypeFactor']),
      annualized: serializer.fromJson<bool>(json['annualized']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'numerator': serializer.toJson<String>(numerator),
      'denominator': serializer.toJson<String>(denominator),
      'description': serializer.toJson<String?>(description),
      'indicatorTypeFactor': serializer.toJson<int>(indicatorTypeFactor),
      'annualized': serializer.toJson<bool>(annualized),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  Indicator copyWith(
          {String? uid,
          String? name,
          String? displayName,
          String? numerator,
          String? denominator,
          Value<String?> description = const Value.absent(),
          int? indicatorTypeFactor,
          bool? annualized,
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      Indicator(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        numerator: numerator ?? this.numerator,
        denominator: denominator ?? this.denominator,
        description: description.present ? description.value : this.description,
        indicatorTypeFactor: indicatorTypeFactor ?? this.indicatorTypeFactor,
        annualized: annualized ?? this.annualized,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  Indicator copyWithCompanion(IndicatorsTableCompanion data) {
    return Indicator(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      numerator: data.numerator.present ? data.numerator.value : this.numerator,
      denominator:
          data.denominator.present ? data.denominator.value : this.denominator,
      description:
          data.description.present ? data.description.value : this.description,
      indicatorTypeFactor: data.indicatorTypeFactor.present
          ? data.indicatorTypeFactor.value
          : this.indicatorTypeFactor,
      annualized:
          data.annualized.present ? data.annualized.value : this.annualized,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Indicator(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('numerator: $numerator, ')
          ..write('denominator: $denominator, ')
          ..write('description: $description, ')
          ..write('indicatorTypeFactor: $indicatorTypeFactor, ')
          ..write('annualized: $annualized, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, name, displayName, numerator,
      denominator, description, indicatorTypeFactor, annualized, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Indicator &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.numerator == this.numerator &&
          other.denominator == this.denominator &&
          other.description == this.description &&
          other.indicatorTypeFactor == this.indicatorTypeFactor &&
          other.annualized == this.annualized &&
          other.lastUpdated == this.lastUpdated);
}

class IndicatorsTableCompanion extends UpdateCompanion<Indicator> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String> numerator;
  final Value<String> denominator;
  final Value<String?> description;
  final Value<int> indicatorTypeFactor;
  final Value<bool> annualized;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const IndicatorsTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.numerator = const Value.absent(),
    this.denominator = const Value.absent(),
    this.description = const Value.absent(),
    this.indicatorTypeFactor = const Value.absent(),
    this.annualized = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IndicatorsTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    required String numerator,
    required String denominator,
    this.description = const Value.absent(),
    this.indicatorTypeFactor = const Value.absent(),
    this.annualized = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName),
        numerator = Value(numerator),
        denominator = Value(denominator);
  static Insertable<Indicator> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? numerator,
    Expression<String>? denominator,
    Expression<String>? description,
    Expression<int>? indicatorTypeFactor,
    Expression<bool>? annualized,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (numerator != null) 'numerator': numerator,
      if (denominator != null) 'denominator': denominator,
      if (description != null) 'description': description,
      if (indicatorTypeFactor != null)
        'indicator_type_factor': indicatorTypeFactor,
      if (annualized != null) 'annualized': annualized,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IndicatorsTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<String>? numerator,
      Value<String>? denominator,
      Value<String?>? description,
      Value<int>? indicatorTypeFactor,
      Value<bool>? annualized,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return IndicatorsTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      numerator: numerator ?? this.numerator,
      denominator: denominator ?? this.denominator,
      description: description ?? this.description,
      indicatorTypeFactor: indicatorTypeFactor ?? this.indicatorTypeFactor,
      annualized: annualized ?? this.annualized,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (numerator.present) {
      map['numerator'] = Variable<String>(numerator.value);
    }
    if (denominator.present) {
      map['denominator'] = Variable<String>(denominator.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (indicatorTypeFactor.present) {
      map['indicator_type_factor'] = Variable<int>(indicatorTypeFactor.value);
    }
    if (annualized.present) {
      map['annualized'] = Variable<bool>(annualized.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IndicatorsTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('numerator: $numerator, ')
          ..write('denominator: $denominator, ')
          ..write('description: $description, ')
          ..write('indicatorTypeFactor: $indicatorTypeFactor, ')
          ..write('annualized: $annualized, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTableTable extends CategoriesTable
    with TableInfo<$CategoriesTableTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataDimensionTypeMeta =
      const VerificationMeta('dataDimensionType');
  @override
  late final GeneratedColumn<String> dataDimensionType =
      GeneratedColumn<String>('data_dimension_type', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, name, displayName, dataDimensionType, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories_table';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('data_dimension_type')) {
      context.handle(
          _dataDimensionTypeMeta,
          dataDimensionType.isAcceptableOrUnknown(
              data['data_dimension_type']!, _dataDimensionTypeMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      dataDimensionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}data_dimension_type']),
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $CategoriesTableTable createAlias(String alias) {
    return $CategoriesTableTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String uid;
  final String name;
  final String displayName;
  final String? dataDimensionType;
  final DateTime? lastUpdated;
  const Category(
      {required this.uid,
      required this.name,
      required this.displayName,
      this.dataDimensionType,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || dataDimensionType != null) {
      map['data_dimension_type'] = Variable<String>(dataDimensionType);
    }
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  CategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return CategoriesTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      dataDimensionType: dataDimensionType == null && nullToAbsent
          ? const Value.absent()
          : Value(dataDimensionType),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      dataDimensionType:
          serializer.fromJson<String?>(json['dataDimensionType']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'dataDimensionType': serializer.toJson<String?>(dataDimensionType),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  Category copyWith(
          {String? uid,
          String? name,
          String? displayName,
          Value<String?> dataDimensionType = const Value.absent(),
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      Category(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        dataDimensionType: dataDimensionType.present
            ? dataDimensionType.value
            : this.dataDimensionType,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  Category copyWithCompanion(CategoriesTableCompanion data) {
    return Category(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      dataDimensionType: data.dataDimensionType.present
          ? data.dataDimensionType.value
          : this.dataDimensionType,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('dataDimensionType: $dataDimensionType, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uid, name, displayName, dataDimensionType, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.dataDimensionType == this.dataDimensionType &&
          other.lastUpdated == this.lastUpdated);
}

class CategoriesTableCompanion extends UpdateCompanion<Category> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String?> dataDimensionType;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const CategoriesTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.dataDimensionType = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    this.dataDimensionType = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName);
  static Insertable<Category> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? dataDimensionType,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (dataDimensionType != null) 'data_dimension_type': dataDimensionType,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<String?>? dataDimensionType,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return CategoriesTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      dataDimensionType: dataDimensionType ?? this.dataDimensionType,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (dataDimensionType.present) {
      map['data_dimension_type'] = Variable<String>(dataDimensionType.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('dataDimensionType: $dataDimensionType, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryOptionsTableTable extends CategoryOptionsTable
    with TableInfo<$CategoryOptionsTableTable, CategoryOption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryOptionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shortNameMeta =
      const VerificationMeta('shortName');
  @override
  late final GeneratedColumn<String> shortName = GeneratedColumn<String>(
      'short_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
      'start_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
      'end_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, name, displayName, shortName, startDate, endDate, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_options_table';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryOption> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('short_name')) {
      context.handle(_shortNameMeta,
          shortName.isAcceptableOrUnknown(data['short_name']!, _shortNameMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  CategoryOption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryOption(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      shortName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}short_name']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_date']),
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_date']),
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $CategoryOptionsTableTable createAlias(String alias) {
    return $CategoryOptionsTableTable(attachedDatabase, alias);
  }
}

class CategoryOption extends DataClass implements Insertable<CategoryOption> {
  final String uid;
  final String name;
  final String displayName;
  final String? shortName;
  final String? startDate;
  final String? endDate;
  final DateTime? lastUpdated;
  const CategoryOption(
      {required this.uid,
      required this.name,
      required this.displayName,
      this.shortName,
      this.startDate,
      this.endDate,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || shortName != null) {
      map['short_name'] = Variable<String>(shortName);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  CategoryOptionsTableCompanion toCompanion(bool nullToAbsent) {
    return CategoryOptionsTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      shortName: shortName == null && nullToAbsent
          ? const Value.absent()
          : Value(shortName),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory CategoryOption.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryOption(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      shortName: serializer.fromJson<String?>(json['shortName']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'shortName': serializer.toJson<String?>(shortName),
      'startDate': serializer.toJson<String?>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  CategoryOption copyWith(
          {String? uid,
          String? name,
          String? displayName,
          Value<String?> shortName = const Value.absent(),
          Value<String?> startDate = const Value.absent(),
          Value<String?> endDate = const Value.absent(),
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      CategoryOption(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        shortName: shortName.present ? shortName.value : this.shortName,
        startDate: startDate.present ? startDate.value : this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  CategoryOption copyWithCompanion(CategoryOptionsTableCompanion data) {
    return CategoryOption(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      shortName: data.shortName.present ? data.shortName.value : this.shortName,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOption(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('shortName: $shortName, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      uid, name, displayName, shortName, startDate, endDate, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryOption &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.shortName == this.shortName &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.lastUpdated == this.lastUpdated);
}

class CategoryOptionsTableCompanion extends UpdateCompanion<CategoryOption> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String?> shortName;
  final Value<String?> startDate;
  final Value<String?> endDate;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const CategoryOptionsTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.shortName = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryOptionsTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    this.shortName = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName);
  static Insertable<CategoryOption> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? shortName,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (shortName != null) 'short_name': shortName,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryOptionsTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<String?>? shortName,
      Value<String?>? startDate,
      Value<String?>? endDate,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return CategoryOptionsTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      shortName: shortName ?? this.shortName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (shortName.present) {
      map['short_name'] = Variable<String>(shortName.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOptionsTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('shortName: $shortName, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryCombosTableTable extends CategoryCombosTable
    with TableInfo<$CategoryCombosTableTable, CategoryCombo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryCombosTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataDimensionTypeMeta =
      const VerificationMeta('dataDimensionType');
  @override
  late final GeneratedColumn<String> dataDimensionType =
      GeneratedColumn<String>('data_dimension_type', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _skipTotalMeta =
      const VerificationMeta('skipTotal');
  @override
  late final GeneratedColumn<bool> skipTotal = GeneratedColumn<bool>(
      'skip_total', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("skip_total" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, name, displayName, dataDimensionType, skipTotal, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_combos_table';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryCombo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('data_dimension_type')) {
      context.handle(
          _dataDimensionTypeMeta,
          dataDimensionType.isAcceptableOrUnknown(
              data['data_dimension_type']!, _dataDimensionTypeMeta));
    }
    if (data.containsKey('skip_total')) {
      context.handle(_skipTotalMeta,
          skipTotal.isAcceptableOrUnknown(data['skip_total']!, _skipTotalMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  CategoryCombo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryCombo(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      dataDimensionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}data_dimension_type']),
      skipTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}skip_total'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $CategoryCombosTableTable createAlias(String alias) {
    return $CategoryCombosTableTable(attachedDatabase, alias);
  }
}

class CategoryCombo extends DataClass implements Insertable<CategoryCombo> {
  final String uid;
  final String name;
  final String displayName;
  final String? dataDimensionType;
  final bool skipTotal;
  final DateTime? lastUpdated;
  const CategoryCombo(
      {required this.uid,
      required this.name,
      required this.displayName,
      this.dataDimensionType,
      required this.skipTotal,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || dataDimensionType != null) {
      map['data_dimension_type'] = Variable<String>(dataDimensionType);
    }
    map['skip_total'] = Variable<bool>(skipTotal);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  CategoryCombosTableCompanion toCompanion(bool nullToAbsent) {
    return CategoryCombosTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      dataDimensionType: dataDimensionType == null && nullToAbsent
          ? const Value.absent()
          : Value(dataDimensionType),
      skipTotal: Value(skipTotal),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory CategoryCombo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryCombo(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      dataDimensionType:
          serializer.fromJson<String?>(json['dataDimensionType']),
      skipTotal: serializer.fromJson<bool>(json['skipTotal']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'dataDimensionType': serializer.toJson<String?>(dataDimensionType),
      'skipTotal': serializer.toJson<bool>(skipTotal),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  CategoryCombo copyWith(
          {String? uid,
          String? name,
          String? displayName,
          Value<String?> dataDimensionType = const Value.absent(),
          bool? skipTotal,
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      CategoryCombo(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        dataDimensionType: dataDimensionType.present
            ? dataDimensionType.value
            : this.dataDimensionType,
        skipTotal: skipTotal ?? this.skipTotal,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  CategoryCombo copyWithCompanion(CategoryCombosTableCompanion data) {
    return CategoryCombo(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      dataDimensionType: data.dataDimensionType.present
          ? data.dataDimensionType.value
          : this.dataDimensionType,
      skipTotal: data.skipTotal.present ? data.skipTotal.value : this.skipTotal,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryCombo(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('dataDimensionType: $dataDimensionType, ')
          ..write('skipTotal: $skipTotal, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      uid, name, displayName, dataDimensionType, skipTotal, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryCombo &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.dataDimensionType == this.dataDimensionType &&
          other.skipTotal == this.skipTotal &&
          other.lastUpdated == this.lastUpdated);
}

class CategoryCombosTableCompanion extends UpdateCompanion<CategoryCombo> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String?> dataDimensionType;
  final Value<bool> skipTotal;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const CategoryCombosTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.dataDimensionType = const Value.absent(),
    this.skipTotal = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryCombosTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    this.dataDimensionType = const Value.absent(),
    this.skipTotal = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName);
  static Insertable<CategoryCombo> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? dataDimensionType,
    Expression<bool>? skipTotal,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (dataDimensionType != null) 'data_dimension_type': dataDimensionType,
      if (skipTotal != null) 'skip_total': skipTotal,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryCombosTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<String?>? dataDimensionType,
      Value<bool>? skipTotal,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return CategoryCombosTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      dataDimensionType: dataDimensionType ?? this.dataDimensionType,
      skipTotal: skipTotal ?? this.skipTotal,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (dataDimensionType.present) {
      map['data_dimension_type'] = Variable<String>(dataDimensionType.value);
    }
    if (skipTotal.present) {
      map['skip_total'] = Variable<bool>(skipTotal.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryCombosTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('dataDimensionType: $dataDimensionType, ')
          ..write('skipTotal: $skipTotal, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryOptionCombosTableTable extends CategoryOptionCombosTable
    with TableInfo<$CategoryOptionCombosTableTable, CategoryOptionCombo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryOptionCombosTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryComboUidMeta =
      const VerificationMeta('categoryComboUid');
  @override
  late final GeneratedColumn<String> categoryComboUid = GeneratedColumn<String>(
      'category_combo_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, name, categoryComboUid, sortOrder, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_option_combos_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<CategoryOptionCombo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_combo_uid')) {
      context.handle(
          _categoryComboUidMeta,
          categoryComboUid.isAcceptableOrUnknown(
              data['category_combo_uid']!, _categoryComboUidMeta));
    } else if (isInserting) {
      context.missing(_categoryComboUidMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  CategoryOptionCombo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryOptionCombo(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      categoryComboUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}category_combo_uid'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $CategoryOptionCombosTableTable createAlias(String alias) {
    return $CategoryOptionCombosTableTable(attachedDatabase, alias);
  }
}

class CategoryOptionCombo extends DataClass
    implements Insertable<CategoryOptionCombo> {
  final String uid;
  final String name;
  final String categoryComboUid;
  final int sortOrder;
  final DateTime? lastUpdated;
  const CategoryOptionCombo(
      {required this.uid,
      required this.name,
      required this.categoryComboUid,
      required this.sortOrder,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['category_combo_uid'] = Variable<String>(categoryComboUid);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  CategoryOptionCombosTableCompanion toCompanion(bool nullToAbsent) {
    return CategoryOptionCombosTableCompanion(
      uid: Value(uid),
      name: Value(name),
      categoryComboUid: Value(categoryComboUid),
      sortOrder: Value(sortOrder),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory CategoryOptionCombo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryOptionCombo(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      categoryComboUid: serializer.fromJson<String>(json['categoryComboUid']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'categoryComboUid': serializer.toJson<String>(categoryComboUid),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  CategoryOptionCombo copyWith(
          {String? uid,
          String? name,
          String? categoryComboUid,
          int? sortOrder,
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      CategoryOptionCombo(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        categoryComboUid: categoryComboUid ?? this.categoryComboUid,
        sortOrder: sortOrder ?? this.sortOrder,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  CategoryOptionCombo copyWithCompanion(
      CategoryOptionCombosTableCompanion data) {
    return CategoryOptionCombo(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      categoryComboUid: data.categoryComboUid.present
          ? data.categoryComboUid.value
          : this.categoryComboUid,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOptionCombo(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('categoryComboUid: $categoryComboUid, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uid, name, categoryComboUid, sortOrder, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryOptionCombo &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.categoryComboUid == this.categoryComboUid &&
          other.sortOrder == this.sortOrder &&
          other.lastUpdated == this.lastUpdated);
}

class CategoryOptionCombosTableCompanion
    extends UpdateCompanion<CategoryOptionCombo> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> categoryComboUid;
  final Value<int> sortOrder;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const CategoryOptionCombosTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryComboUid = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryOptionCombosTableCompanion.insert({
    required String uid,
    required String name,
    required String categoryComboUid,
    this.sortOrder = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        categoryComboUid = Value(categoryComboUid);
  static Insertable<CategoryOptionCombo> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? categoryComboUid,
    Expression<int>? sortOrder,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (categoryComboUid != null) 'category_combo_uid': categoryComboUid,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryOptionCombosTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? categoryComboUid,
      Value<int>? sortOrder,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return CategoryOptionCombosTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      categoryComboUid: categoryComboUid ?? this.categoryComboUid,
      sortOrder: sortOrder ?? this.sortOrder,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryComboUid.present) {
      map['category_combo_uid'] = Variable<String>(categoryComboUid.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOptionCombosTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('categoryComboUid: $categoryComboUid, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OptionSetsTableTable extends OptionSetsTable
    with TableInfo<$OptionSetsTableTable, OptionSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OptionSetsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueTypeMeta =
      const VerificationMeta('valueType');
  @override
  late final GeneratedColumn<String> valueType = GeneratedColumn<String>(
      'value_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, name, displayName, valueType, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'option_sets_table';
  @override
  VerificationContext validateIntegrity(Insertable<OptionSet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('value_type')) {
      context.handle(_valueTypeMeta,
          valueType.isAcceptableOrUnknown(data['value_type']!, _valueTypeMeta));
    } else if (isInserting) {
      context.missing(_valueTypeMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  OptionSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OptionSet(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      valueType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value_type'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $OptionSetsTableTable createAlias(String alias) {
    return $OptionSetsTableTable(attachedDatabase, alias);
  }
}

class OptionSet extends DataClass implements Insertable<OptionSet> {
  final String uid;
  final String name;
  final String displayName;
  final String valueType;
  final DateTime? lastUpdated;
  const OptionSet(
      {required this.uid,
      required this.name,
      required this.displayName,
      required this.valueType,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    map['value_type'] = Variable<String>(valueType);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  OptionSetsTableCompanion toCompanion(bool nullToAbsent) {
    return OptionSetsTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      valueType: Value(valueType),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory OptionSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OptionSet(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      valueType: serializer.fromJson<String>(json['valueType']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'valueType': serializer.toJson<String>(valueType),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  OptionSet copyWith(
          {String? uid,
          String? name,
          String? displayName,
          String? valueType,
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      OptionSet(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        valueType: valueType ?? this.valueType,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  OptionSet copyWithCompanion(OptionSetsTableCompanion data) {
    return OptionSet(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OptionSet(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('valueType: $valueType, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uid, name, displayName, valueType, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OptionSet &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.valueType == this.valueType &&
          other.lastUpdated == this.lastUpdated);
}

class OptionSetsTableCompanion extends UpdateCompanion<OptionSet> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String> valueType;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const OptionSetsTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.valueType = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OptionSetsTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    required String valueType,
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName),
        valueType = Value(valueType);
  static Insertable<OptionSet> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? valueType,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (valueType != null) 'value_type': valueType,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OptionSetsTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<String>? valueType,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return OptionSetsTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      valueType: valueType ?? this.valueType,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (valueType.present) {
      map['value_type'] = Variable<String>(valueType.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OptionSetsTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('valueType: $valueType, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OptionsTableTable extends OptionsTable
    with TableInfo<$OptionsTableTable, OptionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OptionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _optionSetUidMeta =
      const VerificationMeta('optionSetUid');
  @override
  late final GeneratedColumn<String> optionSetUid = GeneratedColumn<String>(
      'option_set_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uid, code, name, displayName, sortOrder, optionSetUid, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'options_table';
  @override
  VerificationContext validateIntegrity(Insertable<OptionItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('option_set_uid')) {
      context.handle(
          _optionSetUidMeta,
          optionSetUid.isAcceptableOrUnknown(
              data['option_set_uid']!, _optionSetUidMeta));
    } else if (isInserting) {
      context.missing(_optionSetUidMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  OptionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OptionItem(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      optionSetUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}option_set_uid'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $OptionsTableTable createAlias(String alias) {
    return $OptionsTableTable(attachedDatabase, alias);
  }
}

class OptionItem extends DataClass implements Insertable<OptionItem> {
  final String uid;
  final String code;
  final String name;
  final String displayName;
  final int sortOrder;

  /// Parent FK — options belong to exactly one set (no link table).
  final String optionSetUid;
  final DateTime? lastUpdated;
  const OptionItem(
      {required this.uid,
      required this.code,
      required this.name,
      required this.displayName,
      required this.sortOrder,
      required this.optionSetUid,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    map['sort_order'] = Variable<int>(sortOrder);
    map['option_set_uid'] = Variable<String>(optionSetUid);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  OptionsTableCompanion toCompanion(bool nullToAbsent) {
    return OptionsTableCompanion(
      uid: Value(uid),
      code: Value(code),
      name: Value(name),
      displayName: Value(displayName),
      sortOrder: Value(sortOrder),
      optionSetUid: Value(optionSetUid),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory OptionItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OptionItem(
      uid: serializer.fromJson<String>(json['uid']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      optionSetUid: serializer.fromJson<String>(json['optionSetUid']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'optionSetUid': serializer.toJson<String>(optionSetUid),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  OptionItem copyWith(
          {String? uid,
          String? code,
          String? name,
          String? displayName,
          int? sortOrder,
          String? optionSetUid,
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      OptionItem(
        uid: uid ?? this.uid,
        code: code ?? this.code,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        sortOrder: sortOrder ?? this.sortOrder,
        optionSetUid: optionSetUid ?? this.optionSetUid,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  OptionItem copyWithCompanion(OptionsTableCompanion data) {
    return OptionItem(
      uid: data.uid.present ? data.uid.value : this.uid,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      optionSetUid: data.optionSetUid.present
          ? data.optionSetUid.value
          : this.optionSetUid,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OptionItem(')
          ..write('uid: $uid, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('optionSetUid: $optionSetUid, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      uid, code, name, displayName, sortOrder, optionSetUid, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OptionItem &&
          other.uid == this.uid &&
          other.code == this.code &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.sortOrder == this.sortOrder &&
          other.optionSetUid == this.optionSetUid &&
          other.lastUpdated == this.lastUpdated);
}

class OptionsTableCompanion extends UpdateCompanion<OptionItem> {
  final Value<String> uid;
  final Value<String> code;
  final Value<String> name;
  final Value<String> displayName;
  final Value<int> sortOrder;
  final Value<String> optionSetUid;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const OptionsTableCompanion({
    this.uid = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.optionSetUid = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OptionsTableCompanion.insert({
    required String uid,
    required String code,
    required String name,
    required String displayName,
    this.sortOrder = const Value.absent(),
    required String optionSetUid,
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        code = Value(code),
        name = Value(name),
        displayName = Value(displayName),
        optionSetUid = Value(optionSetUid);
  static Insertable<OptionItem> custom({
    Expression<String>? uid,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<int>? sortOrder,
    Expression<String>? optionSetUid,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (optionSetUid != null) 'option_set_uid': optionSetUid,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OptionsTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? code,
      Value<String>? name,
      Value<String>? displayName,
      Value<int>? sortOrder,
      Value<String>? optionSetUid,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return OptionsTableCompanion(
      uid: uid ?? this.uid,
      code: code ?? this.code,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      sortOrder: sortOrder ?? this.sortOrder,
      optionSetUid: optionSetUid ?? this.optionSetUid,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (optionSetUid.present) {
      map['option_set_uid'] = Variable<String>(optionSetUid.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OptionsTableCompanion(')
          ..write('uid: $uid, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('optionSetUid: $optionSetUid, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DataElementGroupsTableTable extends DataElementGroupsTable
    with TableInfo<$DataElementGroupsTableTable, DataElementGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DataElementGroupsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [uid, name, displayName, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'data_element_groups_table';
  @override
  VerificationContext validateIntegrity(Insertable<DataElementGroup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  DataElementGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DataElementGroup(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $DataElementGroupsTableTable createAlias(String alias) {
    return $DataElementGroupsTableTable(attachedDatabase, alias);
  }
}

class DataElementGroup extends DataClass
    implements Insertable<DataElementGroup> {
  final String uid;
  final String name;
  final String displayName;
  final DateTime? lastUpdated;
  const DataElementGroup(
      {required this.uid,
      required this.name,
      required this.displayName,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  DataElementGroupsTableCompanion toCompanion(bool nullToAbsent) {
    return DataElementGroupsTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory DataElementGroup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DataElementGroup(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  DataElementGroup copyWith(
          {String? uid,
          String? name,
          String? displayName,
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      DataElementGroup(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  DataElementGroup copyWithCompanion(DataElementGroupsTableCompanion data) {
    return DataElementGroup(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DataElementGroup(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, name, displayName, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataElementGroup &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.lastUpdated == this.lastUpdated);
}

class DataElementGroupsTableCompanion
    extends UpdateCompanion<DataElementGroup> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const DataElementGroupsTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DataElementGroupsTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName);
  static Insertable<DataElementGroup> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DataElementGroupsTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return DataElementGroupsTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DataElementGroupsTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ValidationRulesTableTable extends ValidationRulesTable
    with TableInfo<$ValidationRulesTableTable, ValidationRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ValidationRulesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _importanceMeta =
      const VerificationMeta('importance');
  @override
  late final GeneratedColumn<String> importance = GeneratedColumn<String>(
      'importance', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _operatorMeta =
      const VerificationMeta('operator');
  @override
  late final GeneratedColumn<String> operator = GeneratedColumn<String>(
      'operator', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _instructionMeta =
      const VerificationMeta('instruction');
  @override
  late final GeneratedColumn<String> instruction = GeneratedColumn<String>(
      'instruction', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _periodTypeMeta =
      const VerificationMeta('periodType');
  @override
  late final GeneratedColumn<String> periodType = GeneratedColumn<String>(
      'period_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _leftExpressionMeta =
      const VerificationMeta('leftExpression');
  @override
  late final GeneratedColumn<String> leftExpression = GeneratedColumn<String>(
      'left_expression', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _leftDescriptionMeta =
      const VerificationMeta('leftDescription');
  @override
  late final GeneratedColumn<String> leftDescription = GeneratedColumn<String>(
      'left_description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _leftMissingValueStrategyMeta =
      const VerificationMeta('leftMissingValueStrategy');
  @override
  late final GeneratedColumn<String> leftMissingValueStrategy =
      GeneratedColumn<String>('left_missing_value_strategy', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rightExpressionMeta =
      const VerificationMeta('rightExpression');
  @override
  late final GeneratedColumn<String> rightExpression = GeneratedColumn<String>(
      'right_expression', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rightDescriptionMeta =
      const VerificationMeta('rightDescription');
  @override
  late final GeneratedColumn<String> rightDescription = GeneratedColumn<String>(
      'right_description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rightMissingValueStrategyMeta =
      const VerificationMeta('rightMissingValueStrategy');
  @override
  late final GeneratedColumn<String> rightMissingValueStrategy =
      GeneratedColumn<String>('right_missing_value_strategy', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
      'last_updated', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        uid,
        name,
        displayName,
        description,
        importance,
        operator,
        instruction,
        periodType,
        leftExpression,
        leftDescription,
        leftMissingValueStrategy,
        rightExpression,
        rightDescription,
        rightMissingValueStrategy,
        lastUpdated
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'validation_rules_table';
  @override
  VerificationContext validateIntegrity(Insertable<ValidationRule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('importance')) {
      context.handle(
          _importanceMeta,
          importance.isAcceptableOrUnknown(
              data['importance']!, _importanceMeta));
    }
    if (data.containsKey('operator')) {
      context.handle(_operatorMeta,
          operator.isAcceptableOrUnknown(data['operator']!, _operatorMeta));
    } else if (isInserting) {
      context.missing(_operatorMeta);
    }
    if (data.containsKey('instruction')) {
      context.handle(
          _instructionMeta,
          instruction.isAcceptableOrUnknown(
              data['instruction']!, _instructionMeta));
    }
    if (data.containsKey('period_type')) {
      context.handle(
          _periodTypeMeta,
          periodType.isAcceptableOrUnknown(
              data['period_type']!, _periodTypeMeta));
    }
    if (data.containsKey('left_expression')) {
      context.handle(
          _leftExpressionMeta,
          leftExpression.isAcceptableOrUnknown(
              data['left_expression']!, _leftExpressionMeta));
    } else if (isInserting) {
      context.missing(_leftExpressionMeta);
    }
    if (data.containsKey('left_description')) {
      context.handle(
          _leftDescriptionMeta,
          leftDescription.isAcceptableOrUnknown(
              data['left_description']!, _leftDescriptionMeta));
    }
    if (data.containsKey('left_missing_value_strategy')) {
      context.handle(
          _leftMissingValueStrategyMeta,
          leftMissingValueStrategy.isAcceptableOrUnknown(
              data['left_missing_value_strategy']!,
              _leftMissingValueStrategyMeta));
    }
    if (data.containsKey('right_expression')) {
      context.handle(
          _rightExpressionMeta,
          rightExpression.isAcceptableOrUnknown(
              data['right_expression']!, _rightExpressionMeta));
    } else if (isInserting) {
      context.missing(_rightExpressionMeta);
    }
    if (data.containsKey('right_description')) {
      context.handle(
          _rightDescriptionMeta,
          rightDescription.isAcceptableOrUnknown(
              data['right_description']!, _rightDescriptionMeta));
    }
    if (data.containsKey('right_missing_value_strategy')) {
      context.handle(
          _rightMissingValueStrategyMeta,
          rightMissingValueStrategy.isAcceptableOrUnknown(
              data['right_missing_value_strategy']!,
              _rightMissingValueStrategyMeta));
    }
    if (data.containsKey('last_updated')) {
      context.handle(
          _lastUpdatedMeta,
          lastUpdated.isAcceptableOrUnknown(
              data['last_updated']!, _lastUpdatedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  ValidationRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ValidationRule(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      importance: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}importance']),
      operator: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operator'])!,
      instruction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}instruction']),
      periodType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}period_type']),
      leftExpression: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}left_expression'])!,
      leftDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}left_description']),
      leftMissingValueStrategy: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}left_missing_value_strategy']),
      rightExpression: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}right_expression'])!,
      rightDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}right_description']),
      rightMissingValueStrategy: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}right_missing_value_strategy']),
      lastUpdated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_updated']),
    );
  }

  @override
  $ValidationRulesTableTable createAlias(String alias) {
    return $ValidationRulesTableTable(attachedDatabase, alias);
  }
}

class ValidationRule extends DataClass implements Insertable<ValidationRule> {
  final String uid;
  final String name;
  final String displayName;
  final String? description;
  final String? importance;
  final String operator;
  final String? instruction;
  final String? periodType;
  final String leftExpression;
  final String? leftDescription;
  final String? leftMissingValueStrategy;
  final String rightExpression;
  final String? rightDescription;
  final String? rightMissingValueStrategy;
  final DateTime? lastUpdated;
  const ValidationRule(
      {required this.uid,
      required this.name,
      required this.displayName,
      this.description,
      this.importance,
      required this.operator,
      this.instruction,
      this.periodType,
      required this.leftExpression,
      this.leftDescription,
      this.leftMissingValueStrategy,
      required this.rightExpression,
      this.rightDescription,
      this.rightMissingValueStrategy,
      this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || importance != null) {
      map['importance'] = Variable<String>(importance);
    }
    map['operator'] = Variable<String>(operator);
    if (!nullToAbsent || instruction != null) {
      map['instruction'] = Variable<String>(instruction);
    }
    if (!nullToAbsent || periodType != null) {
      map['period_type'] = Variable<String>(periodType);
    }
    map['left_expression'] = Variable<String>(leftExpression);
    if (!nullToAbsent || leftDescription != null) {
      map['left_description'] = Variable<String>(leftDescription);
    }
    if (!nullToAbsent || leftMissingValueStrategy != null) {
      map['left_missing_value_strategy'] =
          Variable<String>(leftMissingValueStrategy);
    }
    map['right_expression'] = Variable<String>(rightExpression);
    if (!nullToAbsent || rightDescription != null) {
      map['right_description'] = Variable<String>(rightDescription);
    }
    if (!nullToAbsent || rightMissingValueStrategy != null) {
      map['right_missing_value_strategy'] =
          Variable<String>(rightMissingValueStrategy);
    }
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  ValidationRulesTableCompanion toCompanion(bool nullToAbsent) {
    return ValidationRulesTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      importance: importance == null && nullToAbsent
          ? const Value.absent()
          : Value(importance),
      operator: Value(operator),
      instruction: instruction == null && nullToAbsent
          ? const Value.absent()
          : Value(instruction),
      periodType: periodType == null && nullToAbsent
          ? const Value.absent()
          : Value(periodType),
      leftExpression: Value(leftExpression),
      leftDescription: leftDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(leftDescription),
      leftMissingValueStrategy: leftMissingValueStrategy == null && nullToAbsent
          ? const Value.absent()
          : Value(leftMissingValueStrategy),
      rightExpression: Value(rightExpression),
      rightDescription: rightDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(rightDescription),
      rightMissingValueStrategy:
          rightMissingValueStrategy == null && nullToAbsent
              ? const Value.absent()
              : Value(rightMissingValueStrategy),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory ValidationRule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ValidationRule(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      description: serializer.fromJson<String?>(json['description']),
      importance: serializer.fromJson<String?>(json['importance']),
      operator: serializer.fromJson<String>(json['operator']),
      instruction: serializer.fromJson<String?>(json['instruction']),
      periodType: serializer.fromJson<String?>(json['periodType']),
      leftExpression: serializer.fromJson<String>(json['leftExpression']),
      leftDescription: serializer.fromJson<String?>(json['leftDescription']),
      leftMissingValueStrategy:
          serializer.fromJson<String?>(json['leftMissingValueStrategy']),
      rightExpression: serializer.fromJson<String>(json['rightExpression']),
      rightDescription: serializer.fromJson<String?>(json['rightDescription']),
      rightMissingValueStrategy:
          serializer.fromJson<String?>(json['rightMissingValueStrategy']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'description': serializer.toJson<String?>(description),
      'importance': serializer.toJson<String?>(importance),
      'operator': serializer.toJson<String>(operator),
      'instruction': serializer.toJson<String?>(instruction),
      'periodType': serializer.toJson<String?>(periodType),
      'leftExpression': serializer.toJson<String>(leftExpression),
      'leftDescription': serializer.toJson<String?>(leftDescription),
      'leftMissingValueStrategy':
          serializer.toJson<String?>(leftMissingValueStrategy),
      'rightExpression': serializer.toJson<String>(rightExpression),
      'rightDescription': serializer.toJson<String?>(rightDescription),
      'rightMissingValueStrategy':
          serializer.toJson<String?>(rightMissingValueStrategy),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  ValidationRule copyWith(
          {String? uid,
          String? name,
          String? displayName,
          Value<String?> description = const Value.absent(),
          Value<String?> importance = const Value.absent(),
          String? operator,
          Value<String?> instruction = const Value.absent(),
          Value<String?> periodType = const Value.absent(),
          String? leftExpression,
          Value<String?> leftDescription = const Value.absent(),
          Value<String?> leftMissingValueStrategy = const Value.absent(),
          String? rightExpression,
          Value<String?> rightDescription = const Value.absent(),
          Value<String?> rightMissingValueStrategy = const Value.absent(),
          Value<DateTime?> lastUpdated = const Value.absent()}) =>
      ValidationRule(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        description: description.present ? description.value : this.description,
        importance: importance.present ? importance.value : this.importance,
        operator: operator ?? this.operator,
        instruction: instruction.present ? instruction.value : this.instruction,
        periodType: periodType.present ? periodType.value : this.periodType,
        leftExpression: leftExpression ?? this.leftExpression,
        leftDescription: leftDescription.present
            ? leftDescription.value
            : this.leftDescription,
        leftMissingValueStrategy: leftMissingValueStrategy.present
            ? leftMissingValueStrategy.value
            : this.leftMissingValueStrategy,
        rightExpression: rightExpression ?? this.rightExpression,
        rightDescription: rightDescription.present
            ? rightDescription.value
            : this.rightDescription,
        rightMissingValueStrategy: rightMissingValueStrategy.present
            ? rightMissingValueStrategy.value
            : this.rightMissingValueStrategy,
        lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
      );
  ValidationRule copyWithCompanion(ValidationRulesTableCompanion data) {
    return ValidationRule(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      description:
          data.description.present ? data.description.value : this.description,
      importance:
          data.importance.present ? data.importance.value : this.importance,
      operator: data.operator.present ? data.operator.value : this.operator,
      instruction:
          data.instruction.present ? data.instruction.value : this.instruction,
      periodType:
          data.periodType.present ? data.periodType.value : this.periodType,
      leftExpression: data.leftExpression.present
          ? data.leftExpression.value
          : this.leftExpression,
      leftDescription: data.leftDescription.present
          ? data.leftDescription.value
          : this.leftDescription,
      leftMissingValueStrategy: data.leftMissingValueStrategy.present
          ? data.leftMissingValueStrategy.value
          : this.leftMissingValueStrategy,
      rightExpression: data.rightExpression.present
          ? data.rightExpression.value
          : this.rightExpression,
      rightDescription: data.rightDescription.present
          ? data.rightDescription.value
          : this.rightDescription,
      rightMissingValueStrategy: data.rightMissingValueStrategy.present
          ? data.rightMissingValueStrategy.value
          : this.rightMissingValueStrategy,
      lastUpdated:
          data.lastUpdated.present ? data.lastUpdated.value : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ValidationRule(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('description: $description, ')
          ..write('importance: $importance, ')
          ..write('operator: $operator, ')
          ..write('instruction: $instruction, ')
          ..write('periodType: $periodType, ')
          ..write('leftExpression: $leftExpression, ')
          ..write('leftDescription: $leftDescription, ')
          ..write('leftMissingValueStrategy: $leftMissingValueStrategy, ')
          ..write('rightExpression: $rightExpression, ')
          ..write('rightDescription: $rightDescription, ')
          ..write('rightMissingValueStrategy: $rightMissingValueStrategy, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      uid,
      name,
      displayName,
      description,
      importance,
      operator,
      instruction,
      periodType,
      leftExpression,
      leftDescription,
      leftMissingValueStrategy,
      rightExpression,
      rightDescription,
      rightMissingValueStrategy,
      lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ValidationRule &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.description == this.description &&
          other.importance == this.importance &&
          other.operator == this.operator &&
          other.instruction == this.instruction &&
          other.periodType == this.periodType &&
          other.leftExpression == this.leftExpression &&
          other.leftDescription == this.leftDescription &&
          other.leftMissingValueStrategy == this.leftMissingValueStrategy &&
          other.rightExpression == this.rightExpression &&
          other.rightDescription == this.rightDescription &&
          other.rightMissingValueStrategy == this.rightMissingValueStrategy &&
          other.lastUpdated == this.lastUpdated);
}

class ValidationRulesTableCompanion extends UpdateCompanion<ValidationRule> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String?> description;
  final Value<String?> importance;
  final Value<String> operator;
  final Value<String?> instruction;
  final Value<String?> periodType;
  final Value<String> leftExpression;
  final Value<String?> leftDescription;
  final Value<String?> leftMissingValueStrategy;
  final Value<String> rightExpression;
  final Value<String?> rightDescription;
  final Value<String?> rightMissingValueStrategy;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const ValidationRulesTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.description = const Value.absent(),
    this.importance = const Value.absent(),
    this.operator = const Value.absent(),
    this.instruction = const Value.absent(),
    this.periodType = const Value.absent(),
    this.leftExpression = const Value.absent(),
    this.leftDescription = const Value.absent(),
    this.leftMissingValueStrategy = const Value.absent(),
    this.rightExpression = const Value.absent(),
    this.rightDescription = const Value.absent(),
    this.rightMissingValueStrategy = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ValidationRulesTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    this.description = const Value.absent(),
    this.importance = const Value.absent(),
    required String operator,
    this.instruction = const Value.absent(),
    this.periodType = const Value.absent(),
    required String leftExpression,
    this.leftDescription = const Value.absent(),
    this.leftMissingValueStrategy = const Value.absent(),
    required String rightExpression,
    this.rightDescription = const Value.absent(),
    this.rightMissingValueStrategy = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName),
        operator = Value(operator),
        leftExpression = Value(leftExpression),
        rightExpression = Value(rightExpression);
  static Insertable<ValidationRule> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? description,
    Expression<String>? importance,
    Expression<String>? operator,
    Expression<String>? instruction,
    Expression<String>? periodType,
    Expression<String>? leftExpression,
    Expression<String>? leftDescription,
    Expression<String>? leftMissingValueStrategy,
    Expression<String>? rightExpression,
    Expression<String>? rightDescription,
    Expression<String>? rightMissingValueStrategy,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (description != null) 'description': description,
      if (importance != null) 'importance': importance,
      if (operator != null) 'operator': operator,
      if (instruction != null) 'instruction': instruction,
      if (periodType != null) 'period_type': periodType,
      if (leftExpression != null) 'left_expression': leftExpression,
      if (leftDescription != null) 'left_description': leftDescription,
      if (leftMissingValueStrategy != null)
        'left_missing_value_strategy': leftMissingValueStrategy,
      if (rightExpression != null) 'right_expression': rightExpression,
      if (rightDescription != null) 'right_description': rightDescription,
      if (rightMissingValueStrategy != null)
        'right_missing_value_strategy': rightMissingValueStrategy,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ValidationRulesTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<String?>? description,
      Value<String?>? importance,
      Value<String>? operator,
      Value<String?>? instruction,
      Value<String?>? periodType,
      Value<String>? leftExpression,
      Value<String?>? leftDescription,
      Value<String?>? leftMissingValueStrategy,
      Value<String>? rightExpression,
      Value<String?>? rightDescription,
      Value<String?>? rightMissingValueStrategy,
      Value<DateTime?>? lastUpdated,
      Value<int>? rowid}) {
    return ValidationRulesTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      importance: importance ?? this.importance,
      operator: operator ?? this.operator,
      instruction: instruction ?? this.instruction,
      periodType: periodType ?? this.periodType,
      leftExpression: leftExpression ?? this.leftExpression,
      leftDescription: leftDescription ?? this.leftDescription,
      leftMissingValueStrategy:
          leftMissingValueStrategy ?? this.leftMissingValueStrategy,
      rightExpression: rightExpression ?? this.rightExpression,
      rightDescription: rightDescription ?? this.rightDescription,
      rightMissingValueStrategy:
          rightMissingValueStrategy ?? this.rightMissingValueStrategy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (importance.present) {
      map['importance'] = Variable<String>(importance.value);
    }
    if (operator.present) {
      map['operator'] = Variable<String>(operator.value);
    }
    if (instruction.present) {
      map['instruction'] = Variable<String>(instruction.value);
    }
    if (periodType.present) {
      map['period_type'] = Variable<String>(periodType.value);
    }
    if (leftExpression.present) {
      map['left_expression'] = Variable<String>(leftExpression.value);
    }
    if (leftDescription.present) {
      map['left_description'] = Variable<String>(leftDescription.value);
    }
    if (leftMissingValueStrategy.present) {
      map['left_missing_value_strategy'] =
          Variable<String>(leftMissingValueStrategy.value);
    }
    if (rightExpression.present) {
      map['right_expression'] = Variable<String>(rightExpression.value);
    }
    if (rightDescription.present) {
      map['right_description'] = Variable<String>(rightDescription.value);
    }
    if (rightMissingValueStrategy.present) {
      map['right_missing_value_strategy'] =
          Variable<String>(rightMissingValueStrategy.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ValidationRulesTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('description: $description, ')
          ..write('importance: $importance, ')
          ..write('operator: $operator, ')
          ..write('instruction: $instruction, ')
          ..write('periodType: $periodType, ')
          ..write('leftExpression: $leftExpression, ')
          ..write('leftDescription: $leftDescription, ')
          ..write('leftMissingValueStrategy: $leftMissingValueStrategy, ')
          ..write('rightExpression: $rightExpression, ')
          ..write('rightDescription: $rightDescription, ')
          ..write('rightMissingValueStrategy: $rightMissingValueStrategy, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DataSetElementsTableTable extends DataSetElementsTable
    with TableInfo<$DataSetElementsTableTable, DataSetElement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DataSetElementsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dataSetUidMeta =
      const VerificationMeta('dataSetUid');
  @override
  late final GeneratedColumn<String> dataSetUid = GeneratedColumn<String>(
      'data_set_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _dataElementUidMeta =
      const VerificationMeta('dataElementUid');
  @override
  late final GeneratedColumn<String> dataElementUid = GeneratedColumn<String>(
      'data_element_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryComboUidMeta =
      const VerificationMeta('categoryComboUid');
  @override
  late final GeneratedColumn<String> categoryComboUid = GeneratedColumn<String>(
      'category_combo_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [dataSetUid, dataElementUid, categoryComboUid, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'data_set_elements_table';
  @override
  VerificationContext validateIntegrity(Insertable<DataSetElement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('data_set_uid')) {
      context.handle(
          _dataSetUidMeta,
          dataSetUid.isAcceptableOrUnknown(
              data['data_set_uid']!, _dataSetUidMeta));
    } else if (isInserting) {
      context.missing(_dataSetUidMeta);
    }
    if (data.containsKey('data_element_uid')) {
      context.handle(
          _dataElementUidMeta,
          dataElementUid.isAcceptableOrUnknown(
              data['data_element_uid']!, _dataElementUidMeta));
    } else if (isInserting) {
      context.missing(_dataElementUidMeta);
    }
    if (data.containsKey('category_combo_uid')) {
      context.handle(
          _categoryComboUidMeta,
          categoryComboUid.isAcceptableOrUnknown(
              data['category_combo_uid']!, _categoryComboUidMeta));
    } else if (isInserting) {
      context.missing(_categoryComboUidMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dataSetUid, dataElementUid};
  @override
  DataSetElement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DataSetElement(
      dataSetUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_set_uid'])!,
      dataElementUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}data_element_uid'])!,
      categoryComboUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}category_combo_uid'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $DataSetElementsTableTable createAlias(String alias) {
    return $DataSetElementsTableTable(attachedDatabase, alias);
  }
}

class DataSetElement extends DataClass implements Insertable<DataSetElement> {
  final String dataSetUid;
  final String dataElementUid;

  /// EFFECTIVE categoryCombo (override if present, else element's own),
  /// resolved at write time in DataSetResource.saveAll.
  final String categoryComboUid;
  final int sortOrder;
  const DataSetElement(
      {required this.dataSetUid,
      required this.dataElementUid,
      required this.categoryComboUid,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['data_set_uid'] = Variable<String>(dataSetUid);
    map['data_element_uid'] = Variable<String>(dataElementUid);
    map['category_combo_uid'] = Variable<String>(categoryComboUid);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DataSetElementsTableCompanion toCompanion(bool nullToAbsent) {
    return DataSetElementsTableCompanion(
      dataSetUid: Value(dataSetUid),
      dataElementUid: Value(dataElementUid),
      categoryComboUid: Value(categoryComboUid),
      sortOrder: Value(sortOrder),
    );
  }

  factory DataSetElement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DataSetElement(
      dataSetUid: serializer.fromJson<String>(json['dataSetUid']),
      dataElementUid: serializer.fromJson<String>(json['dataElementUid']),
      categoryComboUid: serializer.fromJson<String>(json['categoryComboUid']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataSetUid': serializer.toJson<String>(dataSetUid),
      'dataElementUid': serializer.toJson<String>(dataElementUid),
      'categoryComboUid': serializer.toJson<String>(categoryComboUid),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DataSetElement copyWith(
          {String? dataSetUid,
          String? dataElementUid,
          String? categoryComboUid,
          int? sortOrder}) =>
      DataSetElement(
        dataSetUid: dataSetUid ?? this.dataSetUid,
        dataElementUid: dataElementUid ?? this.dataElementUid,
        categoryComboUid: categoryComboUid ?? this.categoryComboUid,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  DataSetElement copyWithCompanion(DataSetElementsTableCompanion data) {
    return DataSetElement(
      dataSetUid:
          data.dataSetUid.present ? data.dataSetUid.value : this.dataSetUid,
      dataElementUid: data.dataElementUid.present
          ? data.dataElementUid.value
          : this.dataElementUid,
      categoryComboUid: data.categoryComboUid.present
          ? data.categoryComboUid.value
          : this.categoryComboUid,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DataSetElement(')
          ..write('dataSetUid: $dataSetUid, ')
          ..write('dataElementUid: $dataElementUid, ')
          ..write('categoryComboUid: $categoryComboUid, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(dataSetUid, dataElementUid, categoryComboUid, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataSetElement &&
          other.dataSetUid == this.dataSetUid &&
          other.dataElementUid == this.dataElementUid &&
          other.categoryComboUid == this.categoryComboUid &&
          other.sortOrder == this.sortOrder);
}

class DataSetElementsTableCompanion extends UpdateCompanion<DataSetElement> {
  final Value<String> dataSetUid;
  final Value<String> dataElementUid;
  final Value<String> categoryComboUid;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const DataSetElementsTableCompanion({
    this.dataSetUid = const Value.absent(),
    this.dataElementUid = const Value.absent(),
    this.categoryComboUid = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DataSetElementsTableCompanion.insert({
    required String dataSetUid,
    required String dataElementUid,
    required String categoryComboUid,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : dataSetUid = Value(dataSetUid),
        dataElementUid = Value(dataElementUid),
        categoryComboUid = Value(categoryComboUid);
  static Insertable<DataSetElement> custom({
    Expression<String>? dataSetUid,
    Expression<String>? dataElementUid,
    Expression<String>? categoryComboUid,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dataSetUid != null) 'data_set_uid': dataSetUid,
      if (dataElementUid != null) 'data_element_uid': dataElementUid,
      if (categoryComboUid != null) 'category_combo_uid': categoryComboUid,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DataSetElementsTableCompanion copyWith(
      {Value<String>? dataSetUid,
      Value<String>? dataElementUid,
      Value<String>? categoryComboUid,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return DataSetElementsTableCompanion(
      dataSetUid: dataSetUid ?? this.dataSetUid,
      dataElementUid: dataElementUid ?? this.dataElementUid,
      categoryComboUid: categoryComboUid ?? this.categoryComboUid,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dataSetUid.present) {
      map['data_set_uid'] = Variable<String>(dataSetUid.value);
    }
    if (dataElementUid.present) {
      map['data_element_uid'] = Variable<String>(dataElementUid.value);
    }
    if (categoryComboUid.present) {
      map['category_combo_uid'] = Variable<String>(categoryComboUid.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DataSetElementsTableCompanion(')
          ..write('dataSetUid: $dataSetUid, ')
          ..write('dataElementUid: $dataElementUid, ')
          ..write('categoryComboUid: $categoryComboUid, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DataSetOrgUnitsTableTable extends DataSetOrgUnitsTable
    with TableInfo<$DataSetOrgUnitsTableTable, DataSetOrgUnit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DataSetOrgUnitsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dataSetUidMeta =
      const VerificationMeta('dataSetUid');
  @override
  late final GeneratedColumn<String> dataSetUid = GeneratedColumn<String>(
      'data_set_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _orgUnitUidMeta =
      const VerificationMeta('orgUnitUid');
  @override
  late final GeneratedColumn<String> orgUnitUid = GeneratedColumn<String>(
      'org_unit_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [dataSetUid, orgUnitUid];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'data_set_org_units_table';
  @override
  VerificationContext validateIntegrity(Insertable<DataSetOrgUnit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('data_set_uid')) {
      context.handle(
          _dataSetUidMeta,
          dataSetUid.isAcceptableOrUnknown(
              data['data_set_uid']!, _dataSetUidMeta));
    } else if (isInserting) {
      context.missing(_dataSetUidMeta);
    }
    if (data.containsKey('org_unit_uid')) {
      context.handle(
          _orgUnitUidMeta,
          orgUnitUid.isAcceptableOrUnknown(
              data['org_unit_uid']!, _orgUnitUidMeta));
    } else if (isInserting) {
      context.missing(_orgUnitUidMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dataSetUid, orgUnitUid};
  @override
  DataSetOrgUnit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DataSetOrgUnit(
      dataSetUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_set_uid'])!,
      orgUnitUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}org_unit_uid'])!,
    );
  }

  @override
  $DataSetOrgUnitsTableTable createAlias(String alias) {
    return $DataSetOrgUnitsTableTable(attachedDatabase, alias);
  }
}

class DataSetOrgUnit extends DataClass implements Insertable<DataSetOrgUnit> {
  final String dataSetUid;
  final String orgUnitUid;
  const DataSetOrgUnit({required this.dataSetUid, required this.orgUnitUid});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['data_set_uid'] = Variable<String>(dataSetUid);
    map['org_unit_uid'] = Variable<String>(orgUnitUid);
    return map;
  }

  DataSetOrgUnitsTableCompanion toCompanion(bool nullToAbsent) {
    return DataSetOrgUnitsTableCompanion(
      dataSetUid: Value(dataSetUid),
      orgUnitUid: Value(orgUnitUid),
    );
  }

  factory DataSetOrgUnit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DataSetOrgUnit(
      dataSetUid: serializer.fromJson<String>(json['dataSetUid']),
      orgUnitUid: serializer.fromJson<String>(json['orgUnitUid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataSetUid': serializer.toJson<String>(dataSetUid),
      'orgUnitUid': serializer.toJson<String>(orgUnitUid),
    };
  }

  DataSetOrgUnit copyWith({String? dataSetUid, String? orgUnitUid}) =>
      DataSetOrgUnit(
        dataSetUid: dataSetUid ?? this.dataSetUid,
        orgUnitUid: orgUnitUid ?? this.orgUnitUid,
      );
  DataSetOrgUnit copyWithCompanion(DataSetOrgUnitsTableCompanion data) {
    return DataSetOrgUnit(
      dataSetUid:
          data.dataSetUid.present ? data.dataSetUid.value : this.dataSetUid,
      orgUnitUid:
          data.orgUnitUid.present ? data.orgUnitUid.value : this.orgUnitUid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DataSetOrgUnit(')
          ..write('dataSetUid: $dataSetUid, ')
          ..write('orgUnitUid: $orgUnitUid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dataSetUid, orgUnitUid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataSetOrgUnit &&
          other.dataSetUid == this.dataSetUid &&
          other.orgUnitUid == this.orgUnitUid);
}

class DataSetOrgUnitsTableCompanion extends UpdateCompanion<DataSetOrgUnit> {
  final Value<String> dataSetUid;
  final Value<String> orgUnitUid;
  final Value<int> rowid;
  const DataSetOrgUnitsTableCompanion({
    this.dataSetUid = const Value.absent(),
    this.orgUnitUid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DataSetOrgUnitsTableCompanion.insert({
    required String dataSetUid,
    required String orgUnitUid,
    this.rowid = const Value.absent(),
  })  : dataSetUid = Value(dataSetUid),
        orgUnitUid = Value(orgUnitUid);
  static Insertable<DataSetOrgUnit> custom({
    Expression<String>? dataSetUid,
    Expression<String>? orgUnitUid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dataSetUid != null) 'data_set_uid': dataSetUid,
      if (orgUnitUid != null) 'org_unit_uid': orgUnitUid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DataSetOrgUnitsTableCompanion copyWith(
      {Value<String>? dataSetUid,
      Value<String>? orgUnitUid,
      Value<int>? rowid}) {
    return DataSetOrgUnitsTableCompanion(
      dataSetUid: dataSetUid ?? this.dataSetUid,
      orgUnitUid: orgUnitUid ?? this.orgUnitUid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dataSetUid.present) {
      map['data_set_uid'] = Variable<String>(dataSetUid.value);
    }
    if (orgUnitUid.present) {
      map['org_unit_uid'] = Variable<String>(orgUnitUid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DataSetOrgUnitsTableCompanion(')
          ..write('dataSetUid: $dataSetUid, ')
          ..write('orgUnitUid: $orgUnitUid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SectionDataElementsTableTable extends SectionDataElementsTable
    with TableInfo<$SectionDataElementsTableTable, SectionDataElement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectionDataElementsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sectionUidMeta =
      const VerificationMeta('sectionUid');
  @override
  late final GeneratedColumn<String> sectionUid = GeneratedColumn<String>(
      'section_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _dataElementUidMeta =
      const VerificationMeta('dataElementUid');
  @override
  late final GeneratedColumn<String> dataElementUid = GeneratedColumn<String>(
      'data_element_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [sectionUid, dataElementUid, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'section_data_elements_table';
  @override
  VerificationContext validateIntegrity(Insertable<SectionDataElement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('section_uid')) {
      context.handle(
          _sectionUidMeta,
          sectionUid.isAcceptableOrUnknown(
              data['section_uid']!, _sectionUidMeta));
    } else if (isInserting) {
      context.missing(_sectionUidMeta);
    }
    if (data.containsKey('data_element_uid')) {
      context.handle(
          _dataElementUidMeta,
          dataElementUid.isAcceptableOrUnknown(
              data['data_element_uid']!, _dataElementUidMeta));
    } else if (isInserting) {
      context.missing(_dataElementUidMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sectionUid, dataElementUid};
  @override
  SectionDataElement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectionDataElement(
      sectionUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_uid'])!,
      dataElementUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}data_element_uid'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $SectionDataElementsTableTable createAlias(String alias) {
    return $SectionDataElementsTableTable(attachedDatabase, alias);
  }
}

class SectionDataElement extends DataClass
    implements Insertable<SectionDataElement> {
  final String sectionUid;
  final String dataElementUid;
  final int sortOrder;
  const SectionDataElement(
      {required this.sectionUid,
      required this.dataElementUid,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['section_uid'] = Variable<String>(sectionUid);
    map['data_element_uid'] = Variable<String>(dataElementUid);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  SectionDataElementsTableCompanion toCompanion(bool nullToAbsent) {
    return SectionDataElementsTableCompanion(
      sectionUid: Value(sectionUid),
      dataElementUid: Value(dataElementUid),
      sortOrder: Value(sortOrder),
    );
  }

  factory SectionDataElement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectionDataElement(
      sectionUid: serializer.fromJson<String>(json['sectionUid']),
      dataElementUid: serializer.fromJson<String>(json['dataElementUid']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sectionUid': serializer.toJson<String>(sectionUid),
      'dataElementUid': serializer.toJson<String>(dataElementUid),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  SectionDataElement copyWith(
          {String? sectionUid, String? dataElementUid, int? sortOrder}) =>
      SectionDataElement(
        sectionUid: sectionUid ?? this.sectionUid,
        dataElementUid: dataElementUid ?? this.dataElementUid,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  SectionDataElement copyWithCompanion(SectionDataElementsTableCompanion data) {
    return SectionDataElement(
      sectionUid:
          data.sectionUid.present ? data.sectionUid.value : this.sectionUid,
      dataElementUid: data.dataElementUid.present
          ? data.dataElementUid.value
          : this.dataElementUid,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectionDataElement(')
          ..write('sectionUid: $sectionUid, ')
          ..write('dataElementUid: $dataElementUid, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sectionUid, dataElementUid, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectionDataElement &&
          other.sectionUid == this.sectionUid &&
          other.dataElementUid == this.dataElementUid &&
          other.sortOrder == this.sortOrder);
}

class SectionDataElementsTableCompanion
    extends UpdateCompanion<SectionDataElement> {
  final Value<String> sectionUid;
  final Value<String> dataElementUid;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const SectionDataElementsTableCompanion({
    this.sectionUid = const Value.absent(),
    this.dataElementUid = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SectionDataElementsTableCompanion.insert({
    required String sectionUid,
    required String dataElementUid,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : sectionUid = Value(sectionUid),
        dataElementUid = Value(dataElementUid);
  static Insertable<SectionDataElement> custom({
    Expression<String>? sectionUid,
    Expression<String>? dataElementUid,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sectionUid != null) 'section_uid': sectionUid,
      if (dataElementUid != null) 'data_element_uid': dataElementUid,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SectionDataElementsTableCompanion copyWith(
      {Value<String>? sectionUid,
      Value<String>? dataElementUid,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return SectionDataElementsTableCompanion(
      sectionUid: sectionUid ?? this.sectionUid,
      dataElementUid: dataElementUid ?? this.dataElementUid,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sectionUid.present) {
      map['section_uid'] = Variable<String>(sectionUid.value);
    }
    if (dataElementUid.present) {
      map['data_element_uid'] = Variable<String>(dataElementUid.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectionDataElementsTableCompanion(')
          ..write('sectionUid: $sectionUid, ')
          ..write('dataElementUid: $dataElementUid, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SectionIndicatorsTableTable extends SectionIndicatorsTable
    with TableInfo<$SectionIndicatorsTableTable, SectionIndicator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectionIndicatorsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sectionUidMeta =
      const VerificationMeta('sectionUid');
  @override
  late final GeneratedColumn<String> sectionUid = GeneratedColumn<String>(
      'section_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _indicatorUidMeta =
      const VerificationMeta('indicatorUid');
  @override
  late final GeneratedColumn<String> indicatorUid = GeneratedColumn<String>(
      'indicator_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [sectionUid, indicatorUid, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'section_indicators_table';
  @override
  VerificationContext validateIntegrity(Insertable<SectionIndicator> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('section_uid')) {
      context.handle(
          _sectionUidMeta,
          sectionUid.isAcceptableOrUnknown(
              data['section_uid']!, _sectionUidMeta));
    } else if (isInserting) {
      context.missing(_sectionUidMeta);
    }
    if (data.containsKey('indicator_uid')) {
      context.handle(
          _indicatorUidMeta,
          indicatorUid.isAcceptableOrUnknown(
              data['indicator_uid']!, _indicatorUidMeta));
    } else if (isInserting) {
      context.missing(_indicatorUidMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sectionUid, indicatorUid};
  @override
  SectionIndicator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectionIndicator(
      sectionUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_uid'])!,
      indicatorUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}indicator_uid'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $SectionIndicatorsTableTable createAlias(String alias) {
    return $SectionIndicatorsTableTable(attachedDatabase, alias);
  }
}

class SectionIndicator extends DataClass
    implements Insertable<SectionIndicator> {
  final String sectionUid;
  final String indicatorUid;
  final int sortOrder;
  const SectionIndicator(
      {required this.sectionUid,
      required this.indicatorUid,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['section_uid'] = Variable<String>(sectionUid);
    map['indicator_uid'] = Variable<String>(indicatorUid);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  SectionIndicatorsTableCompanion toCompanion(bool nullToAbsent) {
    return SectionIndicatorsTableCompanion(
      sectionUid: Value(sectionUid),
      indicatorUid: Value(indicatorUid),
      sortOrder: Value(sortOrder),
    );
  }

  factory SectionIndicator.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectionIndicator(
      sectionUid: serializer.fromJson<String>(json['sectionUid']),
      indicatorUid: serializer.fromJson<String>(json['indicatorUid']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sectionUid': serializer.toJson<String>(sectionUid),
      'indicatorUid': serializer.toJson<String>(indicatorUid),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  SectionIndicator copyWith(
          {String? sectionUid, String? indicatorUid, int? sortOrder}) =>
      SectionIndicator(
        sectionUid: sectionUid ?? this.sectionUid,
        indicatorUid: indicatorUid ?? this.indicatorUid,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  SectionIndicator copyWithCompanion(SectionIndicatorsTableCompanion data) {
    return SectionIndicator(
      sectionUid:
          data.sectionUid.present ? data.sectionUid.value : this.sectionUid,
      indicatorUid: data.indicatorUid.present
          ? data.indicatorUid.value
          : this.indicatorUid,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectionIndicator(')
          ..write('sectionUid: $sectionUid, ')
          ..write('indicatorUid: $indicatorUid, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sectionUid, indicatorUid, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectionIndicator &&
          other.sectionUid == this.sectionUid &&
          other.indicatorUid == this.indicatorUid &&
          other.sortOrder == this.sortOrder);
}

class SectionIndicatorsTableCompanion
    extends UpdateCompanion<SectionIndicator> {
  final Value<String> sectionUid;
  final Value<String> indicatorUid;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const SectionIndicatorsTableCompanion({
    this.sectionUid = const Value.absent(),
    this.indicatorUid = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SectionIndicatorsTableCompanion.insert({
    required String sectionUid,
    required String indicatorUid,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : sectionUid = Value(sectionUid),
        indicatorUid = Value(indicatorUid);
  static Insertable<SectionIndicator> custom({
    Expression<String>? sectionUid,
    Expression<String>? indicatorUid,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sectionUid != null) 'section_uid': sectionUid,
      if (indicatorUid != null) 'indicator_uid': indicatorUid,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SectionIndicatorsTableCompanion copyWith(
      {Value<String>? sectionUid,
      Value<String>? indicatorUid,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return SectionIndicatorsTableCompanion(
      sectionUid: sectionUid ?? this.sectionUid,
      indicatorUid: indicatorUid ?? this.indicatorUid,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sectionUid.present) {
      map['section_uid'] = Variable<String>(sectionUid.value);
    }
    if (indicatorUid.present) {
      map['indicator_uid'] = Variable<String>(indicatorUid.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectionIndicatorsTableCompanion(')
          ..write('sectionUid: $sectionUid, ')
          ..write('indicatorUid: $indicatorUid, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SectionGreyFieldsTableTable extends SectionGreyFieldsTable
    with TableInfo<$SectionGreyFieldsTableTable, SectionGreyField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectionGreyFieldsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sectionUidMeta =
      const VerificationMeta('sectionUid');
  @override
  late final GeneratedColumn<String> sectionUid = GeneratedColumn<String>(
      'section_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _dataElementUidMeta =
      const VerificationMeta('dataElementUid');
  @override
  late final GeneratedColumn<String> dataElementUid = GeneratedColumn<String>(
      'data_element_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryOptionComboUidMeta =
      const VerificationMeta('categoryOptionComboUid');
  @override
  late final GeneratedColumn<String> categoryOptionComboUid =
      GeneratedColumn<String>('category_option_combo_uid', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
              minTextLength: 11, maxTextLength: 11),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [sectionUid, dataElementUid, categoryOptionComboUid];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'section_grey_fields_table';
  @override
  VerificationContext validateIntegrity(Insertable<SectionGreyField> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('section_uid')) {
      context.handle(
          _sectionUidMeta,
          sectionUid.isAcceptableOrUnknown(
              data['section_uid']!, _sectionUidMeta));
    } else if (isInserting) {
      context.missing(_sectionUidMeta);
    }
    if (data.containsKey('data_element_uid')) {
      context.handle(
          _dataElementUidMeta,
          dataElementUid.isAcceptableOrUnknown(
              data['data_element_uid']!, _dataElementUidMeta));
    } else if (isInserting) {
      context.missing(_dataElementUidMeta);
    }
    if (data.containsKey('category_option_combo_uid')) {
      context.handle(
          _categoryOptionComboUidMeta,
          categoryOptionComboUid.isAcceptableOrUnknown(
              data['category_option_combo_uid']!, _categoryOptionComboUidMeta));
    } else if (isInserting) {
      context.missing(_categoryOptionComboUidMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey =>
      {sectionUid, dataElementUid, categoryOptionComboUid};
  @override
  SectionGreyField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectionGreyField(
      sectionUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_uid'])!,
      dataElementUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}data_element_uid'])!,
      categoryOptionComboUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category_option_combo_uid'])!,
    );
  }

  @override
  $SectionGreyFieldsTableTable createAlias(String alias) {
    return $SectionGreyFieldsTableTable(attachedDatabase, alias);
  }
}

class SectionGreyField extends DataClass
    implements Insertable<SectionGreyField> {
  final String sectionUid;
  final String dataElementUid;
  final String categoryOptionComboUid;
  const SectionGreyField(
      {required this.sectionUid,
      required this.dataElementUid,
      required this.categoryOptionComboUid});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['section_uid'] = Variable<String>(sectionUid);
    map['data_element_uid'] = Variable<String>(dataElementUid);
    map['category_option_combo_uid'] = Variable<String>(categoryOptionComboUid);
    return map;
  }

  SectionGreyFieldsTableCompanion toCompanion(bool nullToAbsent) {
    return SectionGreyFieldsTableCompanion(
      sectionUid: Value(sectionUid),
      dataElementUid: Value(dataElementUid),
      categoryOptionComboUid: Value(categoryOptionComboUid),
    );
  }

  factory SectionGreyField.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectionGreyField(
      sectionUid: serializer.fromJson<String>(json['sectionUid']),
      dataElementUid: serializer.fromJson<String>(json['dataElementUid']),
      categoryOptionComboUid:
          serializer.fromJson<String>(json['categoryOptionComboUid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sectionUid': serializer.toJson<String>(sectionUid),
      'dataElementUid': serializer.toJson<String>(dataElementUid),
      'categoryOptionComboUid':
          serializer.toJson<String>(categoryOptionComboUid),
    };
  }

  SectionGreyField copyWith(
          {String? sectionUid,
          String? dataElementUid,
          String? categoryOptionComboUid}) =>
      SectionGreyField(
        sectionUid: sectionUid ?? this.sectionUid,
        dataElementUid: dataElementUid ?? this.dataElementUid,
        categoryOptionComboUid:
            categoryOptionComboUid ?? this.categoryOptionComboUid,
      );
  SectionGreyField copyWithCompanion(SectionGreyFieldsTableCompanion data) {
    return SectionGreyField(
      sectionUid:
          data.sectionUid.present ? data.sectionUid.value : this.sectionUid,
      dataElementUid: data.dataElementUid.present
          ? data.dataElementUid.value
          : this.dataElementUid,
      categoryOptionComboUid: data.categoryOptionComboUid.present
          ? data.categoryOptionComboUid.value
          : this.categoryOptionComboUid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectionGreyField(')
          ..write('sectionUid: $sectionUid, ')
          ..write('dataElementUid: $dataElementUid, ')
          ..write('categoryOptionComboUid: $categoryOptionComboUid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sectionUid, dataElementUid, categoryOptionComboUid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectionGreyField &&
          other.sectionUid == this.sectionUid &&
          other.dataElementUid == this.dataElementUid &&
          other.categoryOptionComboUid == this.categoryOptionComboUid);
}

class SectionGreyFieldsTableCompanion
    extends UpdateCompanion<SectionGreyField> {
  final Value<String> sectionUid;
  final Value<String> dataElementUid;
  final Value<String> categoryOptionComboUid;
  final Value<int> rowid;
  const SectionGreyFieldsTableCompanion({
    this.sectionUid = const Value.absent(),
    this.dataElementUid = const Value.absent(),
    this.categoryOptionComboUid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SectionGreyFieldsTableCompanion.insert({
    required String sectionUid,
    required String dataElementUid,
    required String categoryOptionComboUid,
    this.rowid = const Value.absent(),
  })  : sectionUid = Value(sectionUid),
        dataElementUid = Value(dataElementUid),
        categoryOptionComboUid = Value(categoryOptionComboUid);
  static Insertable<SectionGreyField> custom({
    Expression<String>? sectionUid,
    Expression<String>? dataElementUid,
    Expression<String>? categoryOptionComboUid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sectionUid != null) 'section_uid': sectionUid,
      if (dataElementUid != null) 'data_element_uid': dataElementUid,
      if (categoryOptionComboUid != null)
        'category_option_combo_uid': categoryOptionComboUid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SectionGreyFieldsTableCompanion copyWith(
      {Value<String>? sectionUid,
      Value<String>? dataElementUid,
      Value<String>? categoryOptionComboUid,
      Value<int>? rowid}) {
    return SectionGreyFieldsTableCompanion(
      sectionUid: sectionUid ?? this.sectionUid,
      dataElementUid: dataElementUid ?? this.dataElementUid,
      categoryOptionComboUid:
          categoryOptionComboUid ?? this.categoryOptionComboUid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sectionUid.present) {
      map['section_uid'] = Variable<String>(sectionUid.value);
    }
    if (dataElementUid.present) {
      map['data_element_uid'] = Variable<String>(dataElementUid.value);
    }
    if (categoryOptionComboUid.present) {
      map['category_option_combo_uid'] =
          Variable<String>(categoryOptionComboUid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectionGreyFieldsTableCompanion(')
          ..write('sectionUid: $sectionUid, ')
          ..write('dataElementUid: $dataElementUid, ')
          ..write('categoryOptionComboUid: $categoryOptionComboUid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DataElementGroupMembersTableTable extends DataElementGroupMembersTable
    with TableInfo<$DataElementGroupMembersTableTable, DataElementGroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DataElementGroupMembersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dataElementGroupUidMeta =
      const VerificationMeta('dataElementGroupUid');
  @override
  late final GeneratedColumn<String> dataElementGroupUid =
      GeneratedColumn<String>('data_element_group_uid', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
              minTextLength: 11, maxTextLength: 11),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _dataElementUidMeta =
      const VerificationMeta('dataElementUid');
  @override
  late final GeneratedColumn<String> dataElementUid = GeneratedColumn<String>(
      'data_element_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [dataElementGroupUid, dataElementUid];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'data_element_group_members_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<DataElementGroupMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('data_element_group_uid')) {
      context.handle(
          _dataElementGroupUidMeta,
          dataElementGroupUid.isAcceptableOrUnknown(
              data['data_element_group_uid']!, _dataElementGroupUidMeta));
    } else if (isInserting) {
      context.missing(_dataElementGroupUidMeta);
    }
    if (data.containsKey('data_element_uid')) {
      context.handle(
          _dataElementUidMeta,
          dataElementUid.isAcceptableOrUnknown(
              data['data_element_uid']!, _dataElementUidMeta));
    } else if (isInserting) {
      context.missing(_dataElementUidMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dataElementGroupUid, dataElementUid};
  @override
  DataElementGroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DataElementGroupMember(
      dataElementGroupUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}data_element_group_uid'])!,
      dataElementUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}data_element_uid'])!,
    );
  }

  @override
  $DataElementGroupMembersTableTable createAlias(String alias) {
    return $DataElementGroupMembersTableTable(attachedDatabase, alias);
  }
}

class DataElementGroupMember extends DataClass
    implements Insertable<DataElementGroupMember> {
  final String dataElementGroupUid;
  final String dataElementUid;
  const DataElementGroupMember(
      {required this.dataElementGroupUid, required this.dataElementUid});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['data_element_group_uid'] = Variable<String>(dataElementGroupUid);
    map['data_element_uid'] = Variable<String>(dataElementUid);
    return map;
  }

  DataElementGroupMembersTableCompanion toCompanion(bool nullToAbsent) {
    return DataElementGroupMembersTableCompanion(
      dataElementGroupUid: Value(dataElementGroupUid),
      dataElementUid: Value(dataElementUid),
    );
  }

  factory DataElementGroupMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DataElementGroupMember(
      dataElementGroupUid:
          serializer.fromJson<String>(json['dataElementGroupUid']),
      dataElementUid: serializer.fromJson<String>(json['dataElementUid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataElementGroupUid': serializer.toJson<String>(dataElementGroupUid),
      'dataElementUid': serializer.toJson<String>(dataElementUid),
    };
  }

  DataElementGroupMember copyWith(
          {String? dataElementGroupUid, String? dataElementUid}) =>
      DataElementGroupMember(
        dataElementGroupUid: dataElementGroupUid ?? this.dataElementGroupUid,
        dataElementUid: dataElementUid ?? this.dataElementUid,
      );
  DataElementGroupMember copyWithCompanion(
      DataElementGroupMembersTableCompanion data) {
    return DataElementGroupMember(
      dataElementGroupUid: data.dataElementGroupUid.present
          ? data.dataElementGroupUid.value
          : this.dataElementGroupUid,
      dataElementUid: data.dataElementUid.present
          ? data.dataElementUid.value
          : this.dataElementUid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DataElementGroupMember(')
          ..write('dataElementGroupUid: $dataElementGroupUid, ')
          ..write('dataElementUid: $dataElementUid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dataElementGroupUid, dataElementUid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataElementGroupMember &&
          other.dataElementGroupUid == this.dataElementGroupUid &&
          other.dataElementUid == this.dataElementUid);
}

class DataElementGroupMembersTableCompanion
    extends UpdateCompanion<DataElementGroupMember> {
  final Value<String> dataElementGroupUid;
  final Value<String> dataElementUid;
  final Value<int> rowid;
  const DataElementGroupMembersTableCompanion({
    this.dataElementGroupUid = const Value.absent(),
    this.dataElementUid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DataElementGroupMembersTableCompanion.insert({
    required String dataElementGroupUid,
    required String dataElementUid,
    this.rowid = const Value.absent(),
  })  : dataElementGroupUid = Value(dataElementGroupUid),
        dataElementUid = Value(dataElementUid);
  static Insertable<DataElementGroupMember> custom({
    Expression<String>? dataElementGroupUid,
    Expression<String>? dataElementUid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dataElementGroupUid != null)
        'data_element_group_uid': dataElementGroupUid,
      if (dataElementUid != null) 'data_element_uid': dataElementUid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DataElementGroupMembersTableCompanion copyWith(
      {Value<String>? dataElementGroupUid,
      Value<String>? dataElementUid,
      Value<int>? rowid}) {
    return DataElementGroupMembersTableCompanion(
      dataElementGroupUid: dataElementGroupUid ?? this.dataElementGroupUid,
      dataElementUid: dataElementUid ?? this.dataElementUid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dataElementGroupUid.present) {
      map['data_element_group_uid'] =
          Variable<String>(dataElementGroupUid.value);
    }
    if (dataElementUid.present) {
      map['data_element_uid'] = Variable<String>(dataElementUid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DataElementGroupMembersTableCompanion(')
          ..write('dataElementGroupUid: $dataElementGroupUid, ')
          ..write('dataElementUid: $dataElementUid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryCategoryOptionsTableTable extends CategoryCategoryOptionsTable
    with TableInfo<$CategoryCategoryOptionsTableTable, CategoryCategoryOption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryCategoryOptionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryUidMeta =
      const VerificationMeta('categoryUid');
  @override
  late final GeneratedColumn<String> categoryUid = GeneratedColumn<String>(
      'category_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryOptionUidMeta =
      const VerificationMeta('categoryOptionUid');
  @override
  late final GeneratedColumn<String> categoryOptionUid =
      GeneratedColumn<String>('category_option_uid', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
              minTextLength: 11, maxTextLength: 11),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [categoryUid, categoryOptionUid, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_category_options_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<CategoryCategoryOption> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category_uid')) {
      context.handle(
          _categoryUidMeta,
          categoryUid.isAcceptableOrUnknown(
              data['category_uid']!, _categoryUidMeta));
    } else if (isInserting) {
      context.missing(_categoryUidMeta);
    }
    if (data.containsKey('category_option_uid')) {
      context.handle(
          _categoryOptionUidMeta,
          categoryOptionUid.isAcceptableOrUnknown(
              data['category_option_uid']!, _categoryOptionUidMeta));
    } else if (isInserting) {
      context.missing(_categoryOptionUidMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {categoryUid, categoryOptionUid};
  @override
  CategoryCategoryOption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryCategoryOption(
      categoryUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_uid'])!,
      categoryOptionUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}category_option_uid'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $CategoryCategoryOptionsTableTable createAlias(String alias) {
    return $CategoryCategoryOptionsTableTable(attachedDatabase, alias);
  }
}

class CategoryCategoryOption extends DataClass
    implements Insertable<CategoryCategoryOption> {
  final String categoryUid;
  final String categoryOptionUid;
  final int sortOrder;
  const CategoryCategoryOption(
      {required this.categoryUid,
      required this.categoryOptionUid,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category_uid'] = Variable<String>(categoryUid);
    map['category_option_uid'] = Variable<String>(categoryOptionUid);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoryCategoryOptionsTableCompanion toCompanion(bool nullToAbsent) {
    return CategoryCategoryOptionsTableCompanion(
      categoryUid: Value(categoryUid),
      categoryOptionUid: Value(categoryOptionUid),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryCategoryOption.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryCategoryOption(
      categoryUid: serializer.fromJson<String>(json['categoryUid']),
      categoryOptionUid: serializer.fromJson<String>(json['categoryOptionUid']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryUid': serializer.toJson<String>(categoryUid),
      'categoryOptionUid': serializer.toJson<String>(categoryOptionUid),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryCategoryOption copyWith(
          {String? categoryUid, String? categoryOptionUid, int? sortOrder}) =>
      CategoryCategoryOption(
        categoryUid: categoryUid ?? this.categoryUid,
        categoryOptionUid: categoryOptionUid ?? this.categoryOptionUid,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  CategoryCategoryOption copyWithCompanion(
      CategoryCategoryOptionsTableCompanion data) {
    return CategoryCategoryOption(
      categoryUid:
          data.categoryUid.present ? data.categoryUid.value : this.categoryUid,
      categoryOptionUid: data.categoryOptionUid.present
          ? data.categoryOptionUid.value
          : this.categoryOptionUid,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryCategoryOption(')
          ..write('categoryUid: $categoryUid, ')
          ..write('categoryOptionUid: $categoryOptionUid, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(categoryUid, categoryOptionUid, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryCategoryOption &&
          other.categoryUid == this.categoryUid &&
          other.categoryOptionUid == this.categoryOptionUid &&
          other.sortOrder == this.sortOrder);
}

class CategoryCategoryOptionsTableCompanion
    extends UpdateCompanion<CategoryCategoryOption> {
  final Value<String> categoryUid;
  final Value<String> categoryOptionUid;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoryCategoryOptionsTableCompanion({
    this.categoryUid = const Value.absent(),
    this.categoryOptionUid = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryCategoryOptionsTableCompanion.insert({
    required String categoryUid,
    required String categoryOptionUid,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : categoryUid = Value(categoryUid),
        categoryOptionUid = Value(categoryOptionUid);
  static Insertable<CategoryCategoryOption> custom({
    Expression<String>? categoryUid,
    Expression<String>? categoryOptionUid,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (categoryUid != null) 'category_uid': categoryUid,
      if (categoryOptionUid != null) 'category_option_uid': categoryOptionUid,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryCategoryOptionsTableCompanion copyWith(
      {Value<String>? categoryUid,
      Value<String>? categoryOptionUid,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return CategoryCategoryOptionsTableCompanion(
      categoryUid: categoryUid ?? this.categoryUid,
      categoryOptionUid: categoryOptionUid ?? this.categoryOptionUid,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (categoryUid.present) {
      map['category_uid'] = Variable<String>(categoryUid.value);
    }
    if (categoryOptionUid.present) {
      map['category_option_uid'] = Variable<String>(categoryOptionUid.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryCategoryOptionsTableCompanion(')
          ..write('categoryUid: $categoryUid, ')
          ..write('categoryOptionUid: $categoryOptionUid, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryComboCategoriesTableTable extends CategoryComboCategoriesTable
    with TableInfo<$CategoryComboCategoriesTableTable, CategoryComboCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryComboCategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryComboUidMeta =
      const VerificationMeta('categoryComboUid');
  @override
  late final GeneratedColumn<String> categoryComboUid = GeneratedColumn<String>(
      'category_combo_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryUidMeta =
      const VerificationMeta('categoryUid');
  @override
  late final GeneratedColumn<String> categoryUid = GeneratedColumn<String>(
      'category_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [categoryComboUid, categoryUid, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_combo_categories_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<CategoryComboCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category_combo_uid')) {
      context.handle(
          _categoryComboUidMeta,
          categoryComboUid.isAcceptableOrUnknown(
              data['category_combo_uid']!, _categoryComboUidMeta));
    } else if (isInserting) {
      context.missing(_categoryComboUidMeta);
    }
    if (data.containsKey('category_uid')) {
      context.handle(
          _categoryUidMeta,
          categoryUid.isAcceptableOrUnknown(
              data['category_uid']!, _categoryUidMeta));
    } else if (isInserting) {
      context.missing(_categoryUidMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {categoryComboUid, categoryUid};
  @override
  CategoryComboCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryComboCategory(
      categoryComboUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}category_combo_uid'])!,
      categoryUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_uid'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $CategoryComboCategoriesTableTable createAlias(String alias) {
    return $CategoryComboCategoriesTableTable(attachedDatabase, alias);
  }
}

class CategoryComboCategory extends DataClass
    implements Insertable<CategoryComboCategory> {
  final String categoryComboUid;
  final String categoryUid;
  final int sortOrder;
  const CategoryComboCategory(
      {required this.categoryComboUid,
      required this.categoryUid,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category_combo_uid'] = Variable<String>(categoryComboUid);
    map['category_uid'] = Variable<String>(categoryUid);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoryComboCategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return CategoryComboCategoriesTableCompanion(
      categoryComboUid: Value(categoryComboUid),
      categoryUid: Value(categoryUid),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryComboCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryComboCategory(
      categoryComboUid: serializer.fromJson<String>(json['categoryComboUid']),
      categoryUid: serializer.fromJson<String>(json['categoryUid']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryComboUid': serializer.toJson<String>(categoryComboUid),
      'categoryUid': serializer.toJson<String>(categoryUid),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryComboCategory copyWith(
          {String? categoryComboUid, String? categoryUid, int? sortOrder}) =>
      CategoryComboCategory(
        categoryComboUid: categoryComboUid ?? this.categoryComboUid,
        categoryUid: categoryUid ?? this.categoryUid,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  CategoryComboCategory copyWithCompanion(
      CategoryComboCategoriesTableCompanion data) {
    return CategoryComboCategory(
      categoryComboUid: data.categoryComboUid.present
          ? data.categoryComboUid.value
          : this.categoryComboUid,
      categoryUid:
          data.categoryUid.present ? data.categoryUid.value : this.categoryUid,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryComboCategory(')
          ..write('categoryComboUid: $categoryComboUid, ')
          ..write('categoryUid: $categoryUid, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(categoryComboUid, categoryUid, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryComboCategory &&
          other.categoryComboUid == this.categoryComboUid &&
          other.categoryUid == this.categoryUid &&
          other.sortOrder == this.sortOrder);
}

class CategoryComboCategoriesTableCompanion
    extends UpdateCompanion<CategoryComboCategory> {
  final Value<String> categoryComboUid;
  final Value<String> categoryUid;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoryComboCategoriesTableCompanion({
    this.categoryComboUid = const Value.absent(),
    this.categoryUid = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryComboCategoriesTableCompanion.insert({
    required String categoryComboUid,
    required String categoryUid,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : categoryComboUid = Value(categoryComboUid),
        categoryUid = Value(categoryUid);
  static Insertable<CategoryComboCategory> custom({
    Expression<String>? categoryComboUid,
    Expression<String>? categoryUid,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (categoryComboUid != null) 'category_combo_uid': categoryComboUid,
      if (categoryUid != null) 'category_uid': categoryUid,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryComboCategoriesTableCompanion copyWith(
      {Value<String>? categoryComboUid,
      Value<String>? categoryUid,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return CategoryComboCategoriesTableCompanion(
      categoryComboUid: categoryComboUid ?? this.categoryComboUid,
      categoryUid: categoryUid ?? this.categoryUid,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (categoryComboUid.present) {
      map['category_combo_uid'] = Variable<String>(categoryComboUid.value);
    }
    if (categoryUid.present) {
      map['category_uid'] = Variable<String>(categoryUid.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryComboCategoriesTableCompanion(')
          ..write('categoryComboUid: $categoryComboUid, ')
          ..write('categoryUid: $categoryUid, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryOptionComboOptionsTableTable
    extends CategoryOptionComboOptionsTable
    with
        TableInfo<$CategoryOptionComboOptionsTableTable,
            CategoryOptionComboOption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryOptionComboOptionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryOptionComboUidMeta =
      const VerificationMeta('categoryOptionComboUid');
  @override
  late final GeneratedColumn<String> categoryOptionComboUid =
      GeneratedColumn<String>('category_option_combo_uid', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
              minTextLength: 11, maxTextLength: 11),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _categoryOptionUidMeta =
      const VerificationMeta('categoryOptionUid');
  @override
  late final GeneratedColumn<String> categoryOptionUid =
      GeneratedColumn<String>('category_option_uid', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
              minTextLength: 11, maxTextLength: 11),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [categoryOptionComboUid, categoryOptionUid];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_option_combo_options_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<CategoryOptionComboOption> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category_option_combo_uid')) {
      context.handle(
          _categoryOptionComboUidMeta,
          categoryOptionComboUid.isAcceptableOrUnknown(
              data['category_option_combo_uid']!, _categoryOptionComboUidMeta));
    } else if (isInserting) {
      context.missing(_categoryOptionComboUidMeta);
    }
    if (data.containsKey('category_option_uid')) {
      context.handle(
          _categoryOptionUidMeta,
          categoryOptionUid.isAcceptableOrUnknown(
              data['category_option_uid']!, _categoryOptionUidMeta));
    } else if (isInserting) {
      context.missing(_categoryOptionUidMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey =>
      {categoryOptionComboUid, categoryOptionUid};
  @override
  CategoryOptionComboOption map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryOptionComboOption(
      categoryOptionComboUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category_option_combo_uid'])!,
      categoryOptionUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}category_option_uid'])!,
    );
  }

  @override
  $CategoryOptionComboOptionsTableTable createAlias(String alias) {
    return $CategoryOptionComboOptionsTableTable(attachedDatabase, alias);
  }
}

class CategoryOptionComboOption extends DataClass
    implements Insertable<CategoryOptionComboOption> {
  final String categoryOptionComboUid;
  final String categoryOptionUid;
  const CategoryOptionComboOption(
      {required this.categoryOptionComboUid, required this.categoryOptionUid});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category_option_combo_uid'] = Variable<String>(categoryOptionComboUid);
    map['category_option_uid'] = Variable<String>(categoryOptionUid);
    return map;
  }

  CategoryOptionComboOptionsTableCompanion toCompanion(bool nullToAbsent) {
    return CategoryOptionComboOptionsTableCompanion(
      categoryOptionComboUid: Value(categoryOptionComboUid),
      categoryOptionUid: Value(categoryOptionUid),
    );
  }

  factory CategoryOptionComboOption.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryOptionComboOption(
      categoryOptionComboUid:
          serializer.fromJson<String>(json['categoryOptionComboUid']),
      categoryOptionUid: serializer.fromJson<String>(json['categoryOptionUid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryOptionComboUid':
          serializer.toJson<String>(categoryOptionComboUid),
      'categoryOptionUid': serializer.toJson<String>(categoryOptionUid),
    };
  }

  CategoryOptionComboOption copyWith(
          {String? categoryOptionComboUid, String? categoryOptionUid}) =>
      CategoryOptionComboOption(
        categoryOptionComboUid:
            categoryOptionComboUid ?? this.categoryOptionComboUid,
        categoryOptionUid: categoryOptionUid ?? this.categoryOptionUid,
      );
  CategoryOptionComboOption copyWithCompanion(
      CategoryOptionComboOptionsTableCompanion data) {
    return CategoryOptionComboOption(
      categoryOptionComboUid: data.categoryOptionComboUid.present
          ? data.categoryOptionComboUid.value
          : this.categoryOptionComboUid,
      categoryOptionUid: data.categoryOptionUid.present
          ? data.categoryOptionUid.value
          : this.categoryOptionUid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOptionComboOption(')
          ..write('categoryOptionComboUid: $categoryOptionComboUid, ')
          ..write('categoryOptionUid: $categoryOptionUid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(categoryOptionComboUid, categoryOptionUid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryOptionComboOption &&
          other.categoryOptionComboUid == this.categoryOptionComboUid &&
          other.categoryOptionUid == this.categoryOptionUid);
}

class CategoryOptionComboOptionsTableCompanion
    extends UpdateCompanion<CategoryOptionComboOption> {
  final Value<String> categoryOptionComboUid;
  final Value<String> categoryOptionUid;
  final Value<int> rowid;
  const CategoryOptionComboOptionsTableCompanion({
    this.categoryOptionComboUid = const Value.absent(),
    this.categoryOptionUid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryOptionComboOptionsTableCompanion.insert({
    required String categoryOptionComboUid,
    required String categoryOptionUid,
    this.rowid = const Value.absent(),
  })  : categoryOptionComboUid = Value(categoryOptionComboUid),
        categoryOptionUid = Value(categoryOptionUid);
  static Insertable<CategoryOptionComboOption> custom({
    Expression<String>? categoryOptionComboUid,
    Expression<String>? categoryOptionUid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (categoryOptionComboUid != null)
        'category_option_combo_uid': categoryOptionComboUid,
      if (categoryOptionUid != null) 'category_option_uid': categoryOptionUid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryOptionComboOptionsTableCompanion copyWith(
      {Value<String>? categoryOptionComboUid,
      Value<String>? categoryOptionUid,
      Value<int>? rowid}) {
    return CategoryOptionComboOptionsTableCompanion(
      categoryOptionComboUid:
          categoryOptionComboUid ?? this.categoryOptionComboUid,
      categoryOptionUid: categoryOptionUid ?? this.categoryOptionUid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (categoryOptionComboUid.present) {
      map['category_option_combo_uid'] =
          Variable<String>(categoryOptionComboUid.value);
    }
    if (categoryOptionUid.present) {
      map['category_option_uid'] = Variable<String>(categoryOptionUid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOptionComboOptionsTableCompanion(')
          ..write('categoryOptionComboUid: $categoryOptionComboUid, ')
          ..write('categoryOptionUid: $categoryOptionUid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTableTable extends UsersTable
    with TableInfo<$UsersTableTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [uid, username, displayName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users_table';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
    );
  }

  @override
  $UsersTableTable createAlias(String alias) {
    return $UsersTableTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String uid;
  final String username;
  final String displayName;
  const User(
      {required this.uid, required this.username, required this.displayName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['username'] = Variable<String>(username);
    map['display_name'] = Variable<String>(displayName);
    return map;
  }

  UsersTableCompanion toCompanion(bool nullToAbsent) {
    return UsersTableCompanion(
      uid: Value(uid),
      username: Value(username),
      displayName: Value(displayName),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      uid: serializer.fromJson<String>(json['uid']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String>(json['displayName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String>(displayName),
    };
  }

  User copyWith({String? uid, String? username, String? displayName}) => User(
        uid: uid ?? this.uid,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
      );
  User copyWithCompanion(UsersTableCompanion data) {
    return User(
      uid: data.uid.present ? data.uid.value : this.uid,
      username: data.username.present ? data.username.value : this.username,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('uid: $uid, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, username, displayName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.uid == this.uid &&
          other.username == this.username &&
          other.displayName == this.displayName);
}

class UsersTableCompanion extends UpdateCompanion<User> {
  final Value<String> uid;
  final Value<String> username;
  final Value<String> displayName;
  final Value<int> rowid;
  const UsersTableCompanion({
    this.uid = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersTableCompanion.insert({
    required String uid,
    required String username,
    required String displayName,
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        username = Value(username),
        displayName = Value(displayName);
  static Insertable<User> custom({
    Expression<String>? uid,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? username,
      Value<String>? displayName,
      Value<int>? rowid}) {
    return UsersTableCompanion(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersTableCompanion(')
          ..write('uid: $uid, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttributesTableTable extends AttributesTable
    with TableInfo<$AttributesTableTable, AttributeDef> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttributesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
      'uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueTypeMeta =
      const VerificationMeta('valueType');
  @override
  late final GeneratedColumn<String> valueType = GeneratedColumn<String>(
      'value_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [uid, name, displayName, valueType];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attributes_table';
  @override
  VerificationContext validateIntegrity(Insertable<AttributeDef> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
          _uidMeta, uid.isAcceptableOrUnknown(data['uid']!, _uidMeta));
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('value_type')) {
      context.handle(_valueTypeMeta,
          valueType.isAcceptableOrUnknown(data['value_type']!, _valueTypeMeta));
    } else if (isInserting) {
      context.missing(_valueTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  AttributeDef map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttributeDef(
      uid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      valueType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value_type'])!,
    );
  }

  @override
  $AttributesTableTable createAlias(String alias) {
    return $AttributesTableTable(attachedDatabase, alias);
  }
}

class AttributeDef extends DataClass implements Insertable<AttributeDef> {
  final String uid;
  final String name;
  final String displayName;
  final String valueType;
  const AttributeDef(
      {required this.uid,
      required this.name,
      required this.displayName,
      required this.valueType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    map['value_type'] = Variable<String>(valueType);
    return map;
  }

  AttributesTableCompanion toCompanion(bool nullToAbsent) {
    return AttributesTableCompanion(
      uid: Value(uid),
      name: Value(name),
      displayName: Value(displayName),
      valueType: Value(valueType),
    );
  }

  factory AttributeDef.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttributeDef(
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      valueType: serializer.fromJson<String>(json['valueType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'valueType': serializer.toJson<String>(valueType),
    };
  }

  AttributeDef copyWith(
          {String? uid,
          String? name,
          String? displayName,
          String? valueType}) =>
      AttributeDef(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        valueType: valueType ?? this.valueType,
      );
  AttributeDef copyWithCompanion(AttributesTableCompanion data) {
    return AttributeDef(
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttributeDef(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('valueType: $valueType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, name, displayName, valueType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttributeDef &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.valueType == this.valueType);
}

class AttributesTableCompanion extends UpdateCompanion<AttributeDef> {
  final Value<String> uid;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String> valueType;
  final Value<int> rowid;
  const AttributesTableCompanion({
    this.uid = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.valueType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttributesTableCompanion.insert({
    required String uid,
    required String name,
    required String displayName,
    required String valueType,
    this.rowid = const Value.absent(),
  })  : uid = Value(uid),
        name = Value(name),
        displayName = Value(displayName),
        valueType = Value(valueType);
  static Insertable<AttributeDef> custom({
    Expression<String>? uid,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? valueType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (valueType != null) 'value_type': valueType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttributesTableCompanion copyWith(
      {Value<String>? uid,
      Value<String>? name,
      Value<String>? displayName,
      Value<String>? valueType,
      Value<int>? rowid}) {
    return AttributesTableCompanion(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      valueType: valueType ?? this.valueType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (valueType.present) {
      map['value_type'] = Variable<String>(valueType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttributesTableCompanion(')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('valueType: $valueType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttributeValuesTableTable extends AttributeValuesTable
    with TableInfo<$AttributeValuesTableTable, AttributeValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttributeValuesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _objectTypeMeta =
      const VerificationMeta('objectType');
  @override
  late final GeneratedColumn<String> objectType = GeneratedColumn<String>(
      'object_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _objectUidMeta =
      const VerificationMeta('objectUid');
  @override
  late final GeneratedColumn<String> objectUid = GeneratedColumn<String>(
      'object_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _attributeUidMeta =
      const VerificationMeta('attributeUid');
  @override
  late final GeneratedColumn<String> attributeUid = GeneratedColumn<String>(
      'attribute_uid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [objectType, objectUid, attributeUid, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attribute_values_table';
  @override
  VerificationContext validateIntegrity(Insertable<AttributeValue> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('object_type')) {
      context.handle(
          _objectTypeMeta,
          objectType.isAcceptableOrUnknown(
              data['object_type']!, _objectTypeMeta));
    } else if (isInserting) {
      context.missing(_objectTypeMeta);
    }
    if (data.containsKey('object_uid')) {
      context.handle(_objectUidMeta,
          objectUid.isAcceptableOrUnknown(data['object_uid']!, _objectUidMeta));
    } else if (isInserting) {
      context.missing(_objectUidMeta);
    }
    if (data.containsKey('attribute_uid')) {
      context.handle(
          _attributeUidMeta,
          attributeUid.isAcceptableOrUnknown(
              data['attribute_uid']!, _attributeUidMeta));
    } else if (isInserting) {
      context.missing(_attributeUidMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {objectType, objectUid, attributeUid};
  @override
  AttributeValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttributeValue(
      objectType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}object_type'])!,
      objectUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}object_uid'])!,
      attributeUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attribute_uid'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AttributeValuesTableTable createAlias(String alias) {
    return $AttributeValuesTableTable(attachedDatabase, alias);
  }
}

class AttributeValue extends DataClass implements Insertable<AttributeValue> {
  final String objectType;
  final String objectUid;
  final String attributeUid;
  final String value;
  const AttributeValue(
      {required this.objectType,
      required this.objectUid,
      required this.attributeUid,
      required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['object_type'] = Variable<String>(objectType);
    map['object_uid'] = Variable<String>(objectUid);
    map['attribute_uid'] = Variable<String>(attributeUid);
    map['value'] = Variable<String>(value);
    return map;
  }

  AttributeValuesTableCompanion toCompanion(bool nullToAbsent) {
    return AttributeValuesTableCompanion(
      objectType: Value(objectType),
      objectUid: Value(objectUid),
      attributeUid: Value(attributeUid),
      value: Value(value),
    );
  }

  factory AttributeValue.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttributeValue(
      objectType: serializer.fromJson<String>(json['objectType']),
      objectUid: serializer.fromJson<String>(json['objectUid']),
      attributeUid: serializer.fromJson<String>(json['attributeUid']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'objectType': serializer.toJson<String>(objectType),
      'objectUid': serializer.toJson<String>(objectUid),
      'attributeUid': serializer.toJson<String>(attributeUid),
      'value': serializer.toJson<String>(value),
    };
  }

  AttributeValue copyWith(
          {String? objectType,
          String? objectUid,
          String? attributeUid,
          String? value}) =>
      AttributeValue(
        objectType: objectType ?? this.objectType,
        objectUid: objectUid ?? this.objectUid,
        attributeUid: attributeUid ?? this.attributeUid,
        value: value ?? this.value,
      );
  AttributeValue copyWithCompanion(AttributeValuesTableCompanion data) {
    return AttributeValue(
      objectType:
          data.objectType.present ? data.objectType.value : this.objectType,
      objectUid: data.objectUid.present ? data.objectUid.value : this.objectUid,
      attributeUid: data.attributeUid.present
          ? data.attributeUid.value
          : this.attributeUid,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttributeValue(')
          ..write('objectType: $objectType, ')
          ..write('objectUid: $objectUid, ')
          ..write('attributeUid: $attributeUid, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(objectType, objectUid, attributeUid, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttributeValue &&
          other.objectType == this.objectType &&
          other.objectUid == this.objectUid &&
          other.attributeUid == this.attributeUid &&
          other.value == this.value);
}

class AttributeValuesTableCompanion extends UpdateCompanion<AttributeValue> {
  final Value<String> objectType;
  final Value<String> objectUid;
  final Value<String> attributeUid;
  final Value<String> value;
  final Value<int> rowid;
  const AttributeValuesTableCompanion({
    this.objectType = const Value.absent(),
    this.objectUid = const Value.absent(),
    this.attributeUid = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttributeValuesTableCompanion.insert({
    required String objectType,
    required String objectUid,
    required String attributeUid,
    required String value,
    this.rowid = const Value.absent(),
  })  : objectType = Value(objectType),
        objectUid = Value(objectUid),
        attributeUid = Value(attributeUid),
        value = Value(value);
  static Insertable<AttributeValue> custom({
    Expression<String>? objectType,
    Expression<String>? objectUid,
    Expression<String>? attributeUid,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (objectType != null) 'object_type': objectType,
      if (objectUid != null) 'object_uid': objectUid,
      if (attributeUid != null) 'attribute_uid': attributeUid,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttributeValuesTableCompanion copyWith(
      {Value<String>? objectType,
      Value<String>? objectUid,
      Value<String>? attributeUid,
      Value<String>? value,
      Value<int>? rowid}) {
    return AttributeValuesTableCompanion(
      objectType: objectType ?? this.objectType,
      objectUid: objectUid ?? this.objectUid,
      attributeUid: attributeUid ?? this.attributeUid,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (objectType.present) {
      map['object_type'] = Variable<String>(objectType.value);
    }
    if (objectUid.present) {
      map['object_uid'] = Variable<String>(objectUid.value);
    }
    if (attributeUid.present) {
      map['attribute_uid'] = Variable<String>(attributeUid.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttributeValuesTableCompanion(')
          ..write('objectType: $objectType, ')
          ..write('objectUid: $objectUid, ')
          ..write('attributeUid: $attributeUid, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncInfoTableTable extends SyncInfoTable
    with TableInfo<$SyncInfoTableTable, SyncInfoEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncInfoTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_info_table';
  @override
  VerificationContext validateIntegrity(Insertable<SyncInfoEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncInfoEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncInfoEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SyncInfoTableTable createAlias(String alias) {
    return $SyncInfoTableTable(attachedDatabase, alias);
  }
}

class SyncInfoEntry extends DataClass implements Insertable<SyncInfoEntry> {
  final String key;
  final String value;
  const SyncInfoEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncInfoTableCompanion toCompanion(bool nullToAbsent) {
    return SyncInfoTableCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SyncInfoEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncInfoEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncInfoEntry copyWith({String? key, String? value}) => SyncInfoEntry(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SyncInfoEntry copyWithCompanion(SyncInfoTableCompanion data) {
    return SyncInfoEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncInfoEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncInfoEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncInfoTableCompanion extends UpdateCompanion<SyncInfoEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncInfoTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncInfoTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SyncInfoEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncInfoTableCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SyncInfoTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncInfoTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DataValuesTableTable extends DataValuesTable
    with TableInfo<$DataValuesTableTable, DataValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DataValuesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dataElementUidMeta =
      const VerificationMeta('dataElementUid');
  @override
  late final GeneratedColumn<String> dataElementUid = GeneratedColumn<String>(
      'data_element_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
      'period', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orgUnitUidMeta =
      const VerificationMeta('orgUnitUid');
  @override
  late final GeneratedColumn<String> orgUnitUid = GeneratedColumn<String>(
      'org_unit_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryOptionComboUidMeta =
      const VerificationMeta('categoryOptionComboUid');
  @override
  late final GeneratedColumn<String> categoryOptionComboUid =
      GeneratedColumn<String>('category_option_combo_uid', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
              minTextLength: 11, maxTextLength: 11),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _attributeOptionComboUidMeta =
      const VerificationMeta('attributeOptionComboUid');
  @override
  late final GeneratedColumn<String> attributeOptionComboUid =
      GeneratedColumn<String>('attribute_option_combo_uid', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
              minTextLength: 11, maxTextLength: 11),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _storedByMeta =
      const VerificationMeta('storedBy');
  @override
  late final GeneratedColumn<String> storedBy = GeneratedColumn<String>(
      'stored_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _commentMeta =
      const VerificationMeta('comment');
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
      'comment', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, int> syncState =
      GeneratedColumn<int>('sync_state', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<SyncState>($DataValuesTableTable.$convertersyncState);
  static const VerificationMeta _syncErrorMeta =
      const VerificationMeta('syncError');
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
      'sync_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        dataElementUid,
        period,
        orgUnitUid,
        categoryOptionComboUid,
        attributeOptionComboUid,
        storedBy,
        value,
        comment,
        syncState,
        syncError,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'data_values_table';
  @override
  VerificationContext validateIntegrity(Insertable<DataValue> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('data_element_uid')) {
      context.handle(
          _dataElementUidMeta,
          dataElementUid.isAcceptableOrUnknown(
              data['data_element_uid']!, _dataElementUidMeta));
    } else if (isInserting) {
      context.missing(_dataElementUidMeta);
    }
    if (data.containsKey('period')) {
      context.handle(_periodMeta,
          period.isAcceptableOrUnknown(data['period']!, _periodMeta));
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('org_unit_uid')) {
      context.handle(
          _orgUnitUidMeta,
          orgUnitUid.isAcceptableOrUnknown(
              data['org_unit_uid']!, _orgUnitUidMeta));
    } else if (isInserting) {
      context.missing(_orgUnitUidMeta);
    }
    if (data.containsKey('category_option_combo_uid')) {
      context.handle(
          _categoryOptionComboUidMeta,
          categoryOptionComboUid.isAcceptableOrUnknown(
              data['category_option_combo_uid']!, _categoryOptionComboUidMeta));
    } else if (isInserting) {
      context.missing(_categoryOptionComboUidMeta);
    }
    if (data.containsKey('attribute_option_combo_uid')) {
      context.handle(
          _attributeOptionComboUidMeta,
          attributeOptionComboUid.isAcceptableOrUnknown(
              data['attribute_option_combo_uid']!,
              _attributeOptionComboUidMeta));
    } else if (isInserting) {
      context.missing(_attributeOptionComboUidMeta);
    }
    if (data.containsKey('stored_by')) {
      context.handle(_storedByMeta,
          storedBy.isAcceptableOrUnknown(data['stored_by']!, _storedByMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('comment')) {
      context.handle(_commentMeta,
          comment.isAcceptableOrUnknown(data['comment']!, _commentMeta));
    }
    if (data.containsKey('sync_error')) {
      context.handle(_syncErrorMeta,
          syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
        dataElementUid,
        period,
        orgUnitUid,
        categoryOptionComboUid,
        attributeOptionComboUid
      };
  @override
  DataValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DataValue(
      dataElementUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}data_element_uid'])!,
      period: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}period'])!,
      orgUnitUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}org_unit_uid'])!,
      categoryOptionComboUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category_option_combo_uid'])!,
      attributeOptionComboUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}attribute_option_combo_uid'])!,
      storedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stored_by']),
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
      comment: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}comment']),
      syncState: $DataValuesTableTable.$convertersyncState.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}sync_state'])!),
      syncError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_error']),
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $DataValuesTableTable createAlias(String alias) {
    return $DataValuesTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class DataValue extends DataClass implements Insertable<DataValue> {
  final String dataElementUid;
  final String period;
  final String orgUnitUid;
  final String categoryOptionComboUid;
  final String attributeOptionComboUid;
  final String? storedBy;
  final String? value;
  final String? comment;
  final SyncState syncState;
  final String? syncError;
  final DateTime lastModified;
  const DataValue(
      {required this.dataElementUid,
      required this.period,
      required this.orgUnitUid,
      required this.categoryOptionComboUid,
      required this.attributeOptionComboUid,
      this.storedBy,
      this.value,
      this.comment,
      required this.syncState,
      this.syncError,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['data_element_uid'] = Variable<String>(dataElementUid);
    map['period'] = Variable<String>(period);
    map['org_unit_uid'] = Variable<String>(orgUnitUid);
    map['category_option_combo_uid'] = Variable<String>(categoryOptionComboUid);
    map['attribute_option_combo_uid'] =
        Variable<String>(attributeOptionComboUid);
    if (!nullToAbsent || storedBy != null) {
      map['stored_by'] = Variable<String>(storedBy);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    {
      map['sync_state'] = Variable<int>(
          $DataValuesTableTable.$convertersyncState.toSql(syncState));
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  DataValuesTableCompanion toCompanion(bool nullToAbsent) {
    return DataValuesTableCompanion(
      dataElementUid: Value(dataElementUid),
      period: Value(period),
      orgUnitUid: Value(orgUnitUid),
      categoryOptionComboUid: Value(categoryOptionComboUid),
      attributeOptionComboUid: Value(attributeOptionComboUid),
      storedBy: storedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(storedBy),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      syncState: Value(syncState),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      lastModified: Value(lastModified),
    );
  }

  factory DataValue.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DataValue(
      dataElementUid: serializer.fromJson<String>(json['dataElementUid']),
      period: serializer.fromJson<String>(json['period']),
      orgUnitUid: serializer.fromJson<String>(json['orgUnitUid']),
      categoryOptionComboUid:
          serializer.fromJson<String>(json['categoryOptionComboUid']),
      attributeOptionComboUid:
          serializer.fromJson<String>(json['attributeOptionComboUid']),
      storedBy: serializer.fromJson<String?>(json['storedBy']),
      value: serializer.fromJson<String?>(json['value']),
      comment: serializer.fromJson<String?>(json['comment']),
      syncState: $DataValuesTableTable.$convertersyncState
          .fromJson(serializer.fromJson<int>(json['syncState'])),
      syncError: serializer.fromJson<String?>(json['syncError']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataElementUid': serializer.toJson<String>(dataElementUid),
      'period': serializer.toJson<String>(period),
      'orgUnitUid': serializer.toJson<String>(orgUnitUid),
      'categoryOptionComboUid':
          serializer.toJson<String>(categoryOptionComboUid),
      'attributeOptionComboUid':
          serializer.toJson<String>(attributeOptionComboUid),
      'storedBy': serializer.toJson<String?>(storedBy),
      'value': serializer.toJson<String?>(value),
      'comment': serializer.toJson<String?>(comment),
      'syncState': serializer.toJson<int>(
          $DataValuesTableTable.$convertersyncState.toJson(syncState)),
      'syncError': serializer.toJson<String?>(syncError),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  DataValue copyWith(
          {String? dataElementUid,
          String? period,
          String? orgUnitUid,
          String? categoryOptionComboUid,
          String? attributeOptionComboUid,
          Value<String?> storedBy = const Value.absent(),
          Value<String?> value = const Value.absent(),
          Value<String?> comment = const Value.absent(),
          SyncState? syncState,
          Value<String?> syncError = const Value.absent(),
          DateTime? lastModified}) =>
      DataValue(
        dataElementUid: dataElementUid ?? this.dataElementUid,
        period: period ?? this.period,
        orgUnitUid: orgUnitUid ?? this.orgUnitUid,
        categoryOptionComboUid:
            categoryOptionComboUid ?? this.categoryOptionComboUid,
        attributeOptionComboUid:
            attributeOptionComboUid ?? this.attributeOptionComboUid,
        storedBy: storedBy.present ? storedBy.value : this.storedBy,
        value: value.present ? value.value : this.value,
        comment: comment.present ? comment.value : this.comment,
        syncState: syncState ?? this.syncState,
        syncError: syncError.present ? syncError.value : this.syncError,
        lastModified: lastModified ?? this.lastModified,
      );
  DataValue copyWithCompanion(DataValuesTableCompanion data) {
    return DataValue(
      dataElementUid: data.dataElementUid.present
          ? data.dataElementUid.value
          : this.dataElementUid,
      period: data.period.present ? data.period.value : this.period,
      orgUnitUid:
          data.orgUnitUid.present ? data.orgUnitUid.value : this.orgUnitUid,
      categoryOptionComboUid: data.categoryOptionComboUid.present
          ? data.categoryOptionComboUid.value
          : this.categoryOptionComboUid,
      attributeOptionComboUid: data.attributeOptionComboUid.present
          ? data.attributeOptionComboUid.value
          : this.attributeOptionComboUid,
      storedBy: data.storedBy.present ? data.storedBy.value : this.storedBy,
      value: data.value.present ? data.value.value : this.value,
      comment: data.comment.present ? data.comment.value : this.comment,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DataValue(')
          ..write('dataElementUid: $dataElementUid, ')
          ..write('period: $period, ')
          ..write('orgUnitUid: $orgUnitUid, ')
          ..write('categoryOptionComboUid: $categoryOptionComboUid, ')
          ..write('attributeOptionComboUid: $attributeOptionComboUid, ')
          ..write('storedBy: $storedBy, ')
          ..write('value: $value, ')
          ..write('comment: $comment, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      dataElementUid,
      period,
      orgUnitUid,
      categoryOptionComboUid,
      attributeOptionComboUid,
      storedBy,
      value,
      comment,
      syncState,
      syncError,
      lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataValue &&
          other.dataElementUid == this.dataElementUid &&
          other.period == this.period &&
          other.orgUnitUid == this.orgUnitUid &&
          other.categoryOptionComboUid == this.categoryOptionComboUid &&
          other.attributeOptionComboUid == this.attributeOptionComboUid &&
          other.storedBy == this.storedBy &&
          other.value == this.value &&
          other.comment == this.comment &&
          other.syncState == this.syncState &&
          other.syncError == this.syncError &&
          other.lastModified == this.lastModified);
}

class DataValuesTableCompanion extends UpdateCompanion<DataValue> {
  final Value<String> dataElementUid;
  final Value<String> period;
  final Value<String> orgUnitUid;
  final Value<String> categoryOptionComboUid;
  final Value<String> attributeOptionComboUid;
  final Value<String?> storedBy;
  final Value<String?> value;
  final Value<String?> comment;
  final Value<SyncState> syncState;
  final Value<String?> syncError;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const DataValuesTableCompanion({
    this.dataElementUid = const Value.absent(),
    this.period = const Value.absent(),
    this.orgUnitUid = const Value.absent(),
    this.categoryOptionComboUid = const Value.absent(),
    this.attributeOptionComboUid = const Value.absent(),
    this.storedBy = const Value.absent(),
    this.value = const Value.absent(),
    this.comment = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DataValuesTableCompanion.insert({
    required String dataElementUid,
    required String period,
    required String orgUnitUid,
    required String categoryOptionComboUid,
    required String attributeOptionComboUid,
    this.storedBy = const Value.absent(),
    this.value = const Value.absent(),
    this.comment = const Value.absent(),
    required SyncState syncState,
    this.syncError = const Value.absent(),
    required DateTime lastModified,
    this.rowid = const Value.absent(),
  })  : dataElementUid = Value(dataElementUid),
        period = Value(period),
        orgUnitUid = Value(orgUnitUid),
        categoryOptionComboUid = Value(categoryOptionComboUid),
        attributeOptionComboUid = Value(attributeOptionComboUid),
        syncState = Value(syncState),
        lastModified = Value(lastModified);
  static Insertable<DataValue> custom({
    Expression<String>? dataElementUid,
    Expression<String>? period,
    Expression<String>? orgUnitUid,
    Expression<String>? categoryOptionComboUid,
    Expression<String>? attributeOptionComboUid,
    Expression<String>? storedBy,
    Expression<String>? value,
    Expression<String>? comment,
    Expression<int>? syncState,
    Expression<String>? syncError,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dataElementUid != null) 'data_element_uid': dataElementUid,
      if (period != null) 'period': period,
      if (orgUnitUid != null) 'org_unit_uid': orgUnitUid,
      if (categoryOptionComboUid != null)
        'category_option_combo_uid': categoryOptionComboUid,
      if (attributeOptionComboUid != null)
        'attribute_option_combo_uid': attributeOptionComboUid,
      if (storedBy != null) 'stored_by': storedBy,
      if (value != null) 'value': value,
      if (comment != null) 'comment': comment,
      if (syncState != null) 'sync_state': syncState,
      if (syncError != null) 'sync_error': syncError,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DataValuesTableCompanion copyWith(
      {Value<String>? dataElementUid,
      Value<String>? period,
      Value<String>? orgUnitUid,
      Value<String>? categoryOptionComboUid,
      Value<String>? attributeOptionComboUid,
      Value<String?>? storedBy,
      Value<String?>? value,
      Value<String?>? comment,
      Value<SyncState>? syncState,
      Value<String?>? syncError,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return DataValuesTableCompanion(
      dataElementUid: dataElementUid ?? this.dataElementUid,
      period: period ?? this.period,
      orgUnitUid: orgUnitUid ?? this.orgUnitUid,
      categoryOptionComboUid:
          categoryOptionComboUid ?? this.categoryOptionComboUid,
      attributeOptionComboUid:
          attributeOptionComboUid ?? this.attributeOptionComboUid,
      storedBy: storedBy ?? this.storedBy,
      value: value ?? this.value,
      comment: comment ?? this.comment,
      syncState: syncState ?? this.syncState,
      syncError: syncError ?? this.syncError,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dataElementUid.present) {
      map['data_element_uid'] = Variable<String>(dataElementUid.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (orgUnitUid.present) {
      map['org_unit_uid'] = Variable<String>(orgUnitUid.value);
    }
    if (categoryOptionComboUid.present) {
      map['category_option_combo_uid'] =
          Variable<String>(categoryOptionComboUid.value);
    }
    if (attributeOptionComboUid.present) {
      map['attribute_option_combo_uid'] =
          Variable<String>(attributeOptionComboUid.value);
    }
    if (storedBy.present) {
      map['stored_by'] = Variable<String>(storedBy.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
          $DataValuesTableTable.$convertersyncState.toSql(syncState.value));
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DataValuesTableCompanion(')
          ..write('dataElementUid: $dataElementUid, ')
          ..write('period: $period, ')
          ..write('orgUnitUid: $orgUnitUid, ')
          ..write('categoryOptionComboUid: $categoryOptionComboUid, ')
          ..write('attributeOptionComboUid: $attributeOptionComboUid, ')
          ..write('storedBy: $storedBy, ')
          ..write('value: $value, ')
          ..write('comment: $comment, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompleteDataSetRegistrationsTableTable
    extends CompleteDataSetRegistrationsTable
    with
        TableInfo<$CompleteDataSetRegistrationsTableTable,
            CompleteDataSetRegistration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompleteDataSetRegistrationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dataSetUidMeta =
      const VerificationMeta('dataSetUid');
  @override
  late final GeneratedColumn<String> dataSetUid = GeneratedColumn<String>(
      'data_set_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
      'period', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orgUnitUidMeta =
      const VerificationMeta('orgUnitUid');
  @override
  late final GeneratedColumn<String> orgUnitUid = GeneratedColumn<String>(
      'org_unit_uid', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _attributeOptionComboUidMeta =
      const VerificationMeta('attributeOptionComboUid');
  @override
  late final GeneratedColumn<String> attributeOptionComboUid =
      GeneratedColumn<String>('attribute_option_combo_uid', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
              minTextLength: 11, maxTextLength: 11),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'));
  static const VerificationMeta _storedByMeta =
      const VerificationMeta('storedBy');
  @override
  late final GeneratedColumn<String> storedBy = GeneratedColumn<String>(
      'stored_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, int> syncState =
      GeneratedColumn<int>('sync_state', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<SyncState>(
              $CompleteDataSetRegistrationsTableTable.$convertersyncState);
  static const VerificationMeta _syncErrorMeta =
      const VerificationMeta('syncError');
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
      'sync_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        dataSetUid,
        period,
        orgUnitUid,
        attributeOptionComboUid,
        completed,
        storedBy,
        date,
        syncState,
        syncError,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'complete_data_set_registrations_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<CompleteDataSetRegistration> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('data_set_uid')) {
      context.handle(
          _dataSetUidMeta,
          dataSetUid.isAcceptableOrUnknown(
              data['data_set_uid']!, _dataSetUidMeta));
    } else if (isInserting) {
      context.missing(_dataSetUidMeta);
    }
    if (data.containsKey('period')) {
      context.handle(_periodMeta,
          period.isAcceptableOrUnknown(data['period']!, _periodMeta));
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('org_unit_uid')) {
      context.handle(
          _orgUnitUidMeta,
          orgUnitUid.isAcceptableOrUnknown(
              data['org_unit_uid']!, _orgUnitUidMeta));
    } else if (isInserting) {
      context.missing(_orgUnitUidMeta);
    }
    if (data.containsKey('attribute_option_combo_uid')) {
      context.handle(
          _attributeOptionComboUidMeta,
          attributeOptionComboUid.isAcceptableOrUnknown(
              data['attribute_option_combo_uid']!,
              _attributeOptionComboUidMeta));
    } else if (isInserting) {
      context.missing(_attributeOptionComboUidMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('stored_by')) {
      context.handle(_storedByMeta,
          storedBy.isAcceptableOrUnknown(data['stored_by']!, _storedByMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('sync_error')) {
      context.handle(_syncErrorMeta,
          syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey =>
      {dataSetUid, period, orgUnitUid, attributeOptionComboUid};
  @override
  CompleteDataSetRegistration map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompleteDataSetRegistration(
      dataSetUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_set_uid'])!,
      period: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}period'])!,
      orgUnitUid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}org_unit_uid'])!,
      attributeOptionComboUid: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}attribute_option_combo_uid'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      storedBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stored_by']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      syncState: $CompleteDataSetRegistrationsTableTable.$convertersyncState
          .fromSql(attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}sync_state'])!),
      syncError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_error']),
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $CompleteDataSetRegistrationsTableTable createAlias(String alias) {
    return $CompleteDataSetRegistrationsTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class CompleteDataSetRegistration extends DataClass
    implements Insertable<CompleteDataSetRegistration> {
  final String dataSetUid;
  final String period;
  final String orgUnitUid;
  final String attributeOptionComboUid;
  final bool completed;
  final String? storedBy;
  final DateTime date;
  final SyncState syncState;
  final String? syncError;
  final DateTime lastModified;
  const CompleteDataSetRegistration(
      {required this.dataSetUid,
      required this.period,
      required this.orgUnitUid,
      required this.attributeOptionComboUid,
      required this.completed,
      this.storedBy,
      required this.date,
      required this.syncState,
      this.syncError,
      required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['data_set_uid'] = Variable<String>(dataSetUid);
    map['period'] = Variable<String>(period);
    map['org_unit_uid'] = Variable<String>(orgUnitUid);
    map['attribute_option_combo_uid'] =
        Variable<String>(attributeOptionComboUid);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || storedBy != null) {
      map['stored_by'] = Variable<String>(storedBy);
    }
    map['date'] = Variable<DateTime>(date);
    {
      map['sync_state'] = Variable<int>($CompleteDataSetRegistrationsTableTable
          .$convertersyncState
          .toSql(syncState));
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  CompleteDataSetRegistrationsTableCompanion toCompanion(bool nullToAbsent) {
    return CompleteDataSetRegistrationsTableCompanion(
      dataSetUid: Value(dataSetUid),
      period: Value(period),
      orgUnitUid: Value(orgUnitUid),
      attributeOptionComboUid: Value(attributeOptionComboUid),
      completed: Value(completed),
      storedBy: storedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(storedBy),
      date: Value(date),
      syncState: Value(syncState),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      lastModified: Value(lastModified),
    );
  }

  factory CompleteDataSetRegistration.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompleteDataSetRegistration(
      dataSetUid: serializer.fromJson<String>(json['dataSetUid']),
      period: serializer.fromJson<String>(json['period']),
      orgUnitUid: serializer.fromJson<String>(json['orgUnitUid']),
      attributeOptionComboUid:
          serializer.fromJson<String>(json['attributeOptionComboUid']),
      completed: serializer.fromJson<bool>(json['completed']),
      storedBy: serializer.fromJson<String?>(json['storedBy']),
      date: serializer.fromJson<DateTime>(json['date']),
      syncState: $CompleteDataSetRegistrationsTableTable.$convertersyncState
          .fromJson(serializer.fromJson<int>(json['syncState'])),
      syncError: serializer.fromJson<String?>(json['syncError']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataSetUid': serializer.toJson<String>(dataSetUid),
      'period': serializer.toJson<String>(period),
      'orgUnitUid': serializer.toJson<String>(orgUnitUid),
      'attributeOptionComboUid':
          serializer.toJson<String>(attributeOptionComboUid),
      'completed': serializer.toJson<bool>(completed),
      'storedBy': serializer.toJson<String?>(storedBy),
      'date': serializer.toJson<DateTime>(date),
      'syncState': serializer.toJson<int>(
          $CompleteDataSetRegistrationsTableTable.$convertersyncState
              .toJson(syncState)),
      'syncError': serializer.toJson<String?>(syncError),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  CompleteDataSetRegistration copyWith(
          {String? dataSetUid,
          String? period,
          String? orgUnitUid,
          String? attributeOptionComboUid,
          bool? completed,
          Value<String?> storedBy = const Value.absent(),
          DateTime? date,
          SyncState? syncState,
          Value<String?> syncError = const Value.absent(),
          DateTime? lastModified}) =>
      CompleteDataSetRegistration(
        dataSetUid: dataSetUid ?? this.dataSetUid,
        period: period ?? this.period,
        orgUnitUid: orgUnitUid ?? this.orgUnitUid,
        attributeOptionComboUid:
            attributeOptionComboUid ?? this.attributeOptionComboUid,
        completed: completed ?? this.completed,
        storedBy: storedBy.present ? storedBy.value : this.storedBy,
        date: date ?? this.date,
        syncState: syncState ?? this.syncState,
        syncError: syncError.present ? syncError.value : this.syncError,
        lastModified: lastModified ?? this.lastModified,
      );
  CompleteDataSetRegistration copyWithCompanion(
      CompleteDataSetRegistrationsTableCompanion data) {
    return CompleteDataSetRegistration(
      dataSetUid:
          data.dataSetUid.present ? data.dataSetUid.value : this.dataSetUid,
      period: data.period.present ? data.period.value : this.period,
      orgUnitUid:
          data.orgUnitUid.present ? data.orgUnitUid.value : this.orgUnitUid,
      attributeOptionComboUid: data.attributeOptionComboUid.present
          ? data.attributeOptionComboUid.value
          : this.attributeOptionComboUid,
      completed: data.completed.present ? data.completed.value : this.completed,
      storedBy: data.storedBy.present ? data.storedBy.value : this.storedBy,
      date: data.date.present ? data.date.value : this.date,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompleteDataSetRegistration(')
          ..write('dataSetUid: $dataSetUid, ')
          ..write('period: $period, ')
          ..write('orgUnitUid: $orgUnitUid, ')
          ..write('attributeOptionComboUid: $attributeOptionComboUid, ')
          ..write('completed: $completed, ')
          ..write('storedBy: $storedBy, ')
          ..write('date: $date, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      dataSetUid,
      period,
      orgUnitUid,
      attributeOptionComboUid,
      completed,
      storedBy,
      date,
      syncState,
      syncError,
      lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompleteDataSetRegistration &&
          other.dataSetUid == this.dataSetUid &&
          other.period == this.period &&
          other.orgUnitUid == this.orgUnitUid &&
          other.attributeOptionComboUid == this.attributeOptionComboUid &&
          other.completed == this.completed &&
          other.storedBy == this.storedBy &&
          other.date == this.date &&
          other.syncState == this.syncState &&
          other.syncError == this.syncError &&
          other.lastModified == this.lastModified);
}

class CompleteDataSetRegistrationsTableCompanion
    extends UpdateCompanion<CompleteDataSetRegistration> {
  final Value<String> dataSetUid;
  final Value<String> period;
  final Value<String> orgUnitUid;
  final Value<String> attributeOptionComboUid;
  final Value<bool> completed;
  final Value<String?> storedBy;
  final Value<DateTime> date;
  final Value<SyncState> syncState;
  final Value<String?> syncError;
  final Value<DateTime> lastModified;
  final Value<int> rowid;
  const CompleteDataSetRegistrationsTableCompanion({
    this.dataSetUid = const Value.absent(),
    this.period = const Value.absent(),
    this.orgUnitUid = const Value.absent(),
    this.attributeOptionComboUid = const Value.absent(),
    this.completed = const Value.absent(),
    this.storedBy = const Value.absent(),
    this.date = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompleteDataSetRegistrationsTableCompanion.insert({
    required String dataSetUid,
    required String period,
    required String orgUnitUid,
    required String attributeOptionComboUid,
    required bool completed,
    this.storedBy = const Value.absent(),
    required DateTime date,
    required SyncState syncState,
    this.syncError = const Value.absent(),
    required DateTime lastModified,
    this.rowid = const Value.absent(),
  })  : dataSetUid = Value(dataSetUid),
        period = Value(period),
        orgUnitUid = Value(orgUnitUid),
        attributeOptionComboUid = Value(attributeOptionComboUid),
        completed = Value(completed),
        date = Value(date),
        syncState = Value(syncState),
        lastModified = Value(lastModified);
  static Insertable<CompleteDataSetRegistration> custom({
    Expression<String>? dataSetUid,
    Expression<String>? period,
    Expression<String>? orgUnitUid,
    Expression<String>? attributeOptionComboUid,
    Expression<bool>? completed,
    Expression<String>? storedBy,
    Expression<DateTime>? date,
    Expression<int>? syncState,
    Expression<String>? syncError,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dataSetUid != null) 'data_set_uid': dataSetUid,
      if (period != null) 'period': period,
      if (orgUnitUid != null) 'org_unit_uid': orgUnitUid,
      if (attributeOptionComboUid != null)
        'attribute_option_combo_uid': attributeOptionComboUid,
      if (completed != null) 'completed': completed,
      if (storedBy != null) 'stored_by': storedBy,
      if (date != null) 'date': date,
      if (syncState != null) 'sync_state': syncState,
      if (syncError != null) 'sync_error': syncError,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompleteDataSetRegistrationsTableCompanion copyWith(
      {Value<String>? dataSetUid,
      Value<String>? period,
      Value<String>? orgUnitUid,
      Value<String>? attributeOptionComboUid,
      Value<bool>? completed,
      Value<String?>? storedBy,
      Value<DateTime>? date,
      Value<SyncState>? syncState,
      Value<String?>? syncError,
      Value<DateTime>? lastModified,
      Value<int>? rowid}) {
    return CompleteDataSetRegistrationsTableCompanion(
      dataSetUid: dataSetUid ?? this.dataSetUid,
      period: period ?? this.period,
      orgUnitUid: orgUnitUid ?? this.orgUnitUid,
      attributeOptionComboUid:
          attributeOptionComboUid ?? this.attributeOptionComboUid,
      completed: completed ?? this.completed,
      storedBy: storedBy ?? this.storedBy,
      date: date ?? this.date,
      syncState: syncState ?? this.syncState,
      syncError: syncError ?? this.syncError,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dataSetUid.present) {
      map['data_set_uid'] = Variable<String>(dataSetUid.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (orgUnitUid.present) {
      map['org_unit_uid'] = Variable<String>(orgUnitUid.value);
    }
    if (attributeOptionComboUid.present) {
      map['attribute_option_combo_uid'] =
          Variable<String>(attributeOptionComboUid.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (storedBy.present) {
      map['stored_by'] = Variable<String>(storedBy.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>($CompleteDataSetRegistrationsTableTable
          .$convertersyncState
          .toSql(syncState.value));
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompleteDataSetRegistrationsTableCompanion(')
          ..write('dataSetUid: $dataSetUid, ')
          ..write('period: $period, ')
          ..write('orgUnitUid: $orgUnitUid, ')
          ..write('attributeOptionComboUid: $attributeOptionComboUid, ')
          ..write('completed: $completed, ')
          ..write('storedBy: $storedBy, ')
          ..write('date: $date, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OrgUnitsTableTable orgUnitsTable = $OrgUnitsTableTable(this);
  late final $DataSetsTableTable dataSetsTable = $DataSetsTableTable(this);
  late final $DataElementsTableTable dataElementsTable =
      $DataElementsTableTable(this);
  late final $SectionsTableTable sectionsTable = $SectionsTableTable(this);
  late final $IndicatorsTableTable indicatorsTable =
      $IndicatorsTableTable(this);
  late final $CategoriesTableTable categoriesTable =
      $CategoriesTableTable(this);
  late final $CategoryOptionsTableTable categoryOptionsTable =
      $CategoryOptionsTableTable(this);
  late final $CategoryCombosTableTable categoryCombosTable =
      $CategoryCombosTableTable(this);
  late final $CategoryOptionCombosTableTable categoryOptionCombosTable =
      $CategoryOptionCombosTableTable(this);
  late final $OptionSetsTableTable optionSetsTable =
      $OptionSetsTableTable(this);
  late final $OptionsTableTable optionsTable = $OptionsTableTable(this);
  late final $DataElementGroupsTableTable dataElementGroupsTable =
      $DataElementGroupsTableTable(this);
  late final $ValidationRulesTableTable validationRulesTable =
      $ValidationRulesTableTable(this);
  late final $DataSetElementsTableTable dataSetElementsTable =
      $DataSetElementsTableTable(this);
  late final $DataSetOrgUnitsTableTable dataSetOrgUnitsTable =
      $DataSetOrgUnitsTableTable(this);
  late final $SectionDataElementsTableTable sectionDataElementsTable =
      $SectionDataElementsTableTable(this);
  late final $SectionIndicatorsTableTable sectionIndicatorsTable =
      $SectionIndicatorsTableTable(this);
  late final $SectionGreyFieldsTableTable sectionGreyFieldsTable =
      $SectionGreyFieldsTableTable(this);
  late final $DataElementGroupMembersTableTable dataElementGroupMembersTable =
      $DataElementGroupMembersTableTable(this);
  late final $CategoryCategoryOptionsTableTable categoryCategoryOptionsTable =
      $CategoryCategoryOptionsTableTable(this);
  late final $CategoryComboCategoriesTableTable categoryComboCategoriesTable =
      $CategoryComboCategoriesTableTable(this);
  late final $CategoryOptionComboOptionsTableTable
      categoryOptionComboOptionsTable =
      $CategoryOptionComboOptionsTableTable(this);
  late final $UsersTableTable usersTable = $UsersTableTable(this);
  late final $AttributesTableTable attributesTable =
      $AttributesTableTable(this);
  late final $AttributeValuesTableTable attributeValuesTable =
      $AttributeValuesTableTable(this);
  late final $SyncInfoTableTable syncInfoTable = $SyncInfoTableTable(this);
  late final $DataValuesTableTable dataValuesTable =
      $DataValuesTableTable(this);
  late final $CompleteDataSetRegistrationsTableTable
      completeDataSetRegistrationsTable =
      $CompleteDataSetRegistrationsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        orgUnitsTable,
        dataSetsTable,
        dataElementsTable,
        sectionsTable,
        indicatorsTable,
        categoriesTable,
        categoryOptionsTable,
        categoryCombosTable,
        categoryOptionCombosTable,
        optionSetsTable,
        optionsTable,
        dataElementGroupsTable,
        validationRulesTable,
        dataSetElementsTable,
        dataSetOrgUnitsTable,
        sectionDataElementsTable,
        sectionIndicatorsTable,
        sectionGreyFieldsTable,
        dataElementGroupMembersTable,
        categoryCategoryOptionsTable,
        categoryComboCategoriesTable,
        categoryOptionComboOptionsTable,
        usersTable,
        attributesTable,
        attributeValuesTable,
        syncInfoTable,
        dataValuesTable,
        completeDataSetRegistrationsTable
      ];
}

typedef $$OrgUnitsTableTableCreateCompanionBuilder = OrgUnitsTableCompanion
    Function({
  required String uid,
  required String name,
  required String displayName,
  Value<String?> parentUid,
  Value<String?> parentName,
  required String path,
  Value<String?> code,
  Value<String?> openingDate,
  Value<String?> closedDate,
  Value<DateTime?> lastUpdated,
  Value<bool> isUserCaptureRoot,
  Value<int> rowid,
});
typedef $$OrgUnitsTableTableUpdateCompanionBuilder = OrgUnitsTableCompanion
    Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<String?> parentUid,
  Value<String?> parentName,
  Value<String> path,
  Value<String?> code,
  Value<String?> openingDate,
  Value<String?> closedDate,
  Value<DateTime?> lastUpdated,
  Value<bool> isUserCaptureRoot,
  Value<int> rowid,
});

class $$OrgUnitsTableTableFilterComposer
    extends Composer<_$AppDatabase, $OrgUnitsTableTable> {
  $$OrgUnitsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentUid => $composableBuilder(
      column: $table.parentUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get openingDate => $composableBuilder(
      column: $table.openingDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get closedDate => $composableBuilder(
      column: $table.closedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isUserCaptureRoot => $composableBuilder(
      column: $table.isUserCaptureRoot,
      builder: (column) => ColumnFilters(column));
}

class $$OrgUnitsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OrgUnitsTableTable> {
  $$OrgUnitsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentUid => $composableBuilder(
      column: $table.parentUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get openingDate => $composableBuilder(
      column: $table.openingDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get closedDate => $composableBuilder(
      column: $table.closedDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isUserCaptureRoot => $composableBuilder(
      column: $table.isUserCaptureRoot,
      builder: (column) => ColumnOrderings(column));
}

class $$OrgUnitsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrgUnitsTableTable> {
  $$OrgUnitsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get parentUid =>
      $composableBuilder(column: $table.parentUid, builder: (column) => column);

  GeneratedColumn<String> get parentName => $composableBuilder(
      column: $table.parentName, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get openingDate => $composableBuilder(
      column: $table.openingDate, builder: (column) => column);

  GeneratedColumn<String> get closedDate => $composableBuilder(
      column: $table.closedDate, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);

  GeneratedColumn<bool> get isUserCaptureRoot => $composableBuilder(
      column: $table.isUserCaptureRoot, builder: (column) => column);
}

class $$OrgUnitsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrgUnitsTableTable,
    OrgUnit,
    $$OrgUnitsTableTableFilterComposer,
    $$OrgUnitsTableTableOrderingComposer,
    $$OrgUnitsTableTableAnnotationComposer,
    $$OrgUnitsTableTableCreateCompanionBuilder,
    $$OrgUnitsTableTableUpdateCompanionBuilder,
    (OrgUnit, BaseReferences<_$AppDatabase, $OrgUnitsTableTable, OrgUnit>),
    OrgUnit,
    PrefetchHooks Function()> {
  $$OrgUnitsTableTableTableManager(_$AppDatabase db, $OrgUnitsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrgUnitsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrgUnitsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrgUnitsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String?> parentUid = const Value.absent(),
            Value<String?> parentName = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String?> code = const Value.absent(),
            Value<String?> openingDate = const Value.absent(),
            Value<String?> closedDate = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<bool> isUserCaptureRoot = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrgUnitsTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            parentUid: parentUid,
            parentName: parentName,
            path: path,
            code: code,
            openingDate: openingDate,
            closedDate: closedDate,
            lastUpdated: lastUpdated,
            isUserCaptureRoot: isUserCaptureRoot,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            Value<String?> parentUid = const Value.absent(),
            Value<String?> parentName = const Value.absent(),
            required String path,
            Value<String?> code = const Value.absent(),
            Value<String?> openingDate = const Value.absent(),
            Value<String?> closedDate = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<bool> isUserCaptureRoot = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrgUnitsTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            parentUid: parentUid,
            parentName: parentName,
            path: path,
            code: code,
            openingDate: openingDate,
            closedDate: closedDate,
            lastUpdated: lastUpdated,
            isUserCaptureRoot: isUserCaptureRoot,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OrgUnitsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrgUnitsTableTable,
    OrgUnit,
    $$OrgUnitsTableTableFilterComposer,
    $$OrgUnitsTableTableOrderingComposer,
    $$OrgUnitsTableTableAnnotationComposer,
    $$OrgUnitsTableTableCreateCompanionBuilder,
    $$OrgUnitsTableTableUpdateCompanionBuilder,
    (OrgUnit, BaseReferences<_$AppDatabase, $OrgUnitsTableTable, OrgUnit>),
    OrgUnit,
    PrefetchHooks Function()>;
typedef $$DataSetsTableTableCreateCompanionBuilder = DataSetsTableCompanion
    Function({
  required String uid,
  required String name,
  required String displayName,
  required String periodType,
  Value<int> version,
  required String categoryComboUid,
  Value<int> openFuturePeriods,
  Value<int> expiryDays,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$DataSetsTableTableUpdateCompanionBuilder = DataSetsTableCompanion
    Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<String> periodType,
  Value<int> version,
  Value<String> categoryComboUid,
  Value<int> openFuturePeriods,
  Value<int> expiryDays,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$DataSetsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DataSetsTableTable> {
  $$DataSetsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openFuturePeriods => $composableBuilder(
      column: $table.openFuturePeriods,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiryDays => $composableBuilder(
      column: $table.expiryDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$DataSetsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DataSetsTableTable> {
  $$DataSetsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openFuturePeriods => $composableBuilder(
      column: $table.openFuturePeriods,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiryDays => $composableBuilder(
      column: $table.expiryDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$DataSetsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DataSetsTableTable> {
  $$DataSetsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid, builder: (column) => column);

  GeneratedColumn<int> get openFuturePeriods => $composableBuilder(
      column: $table.openFuturePeriods, builder: (column) => column);

  GeneratedColumn<int> get expiryDays => $composableBuilder(
      column: $table.expiryDays, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$DataSetsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DataSetsTableTable,
    DataSet,
    $$DataSetsTableTableFilterComposer,
    $$DataSetsTableTableOrderingComposer,
    $$DataSetsTableTableAnnotationComposer,
    $$DataSetsTableTableCreateCompanionBuilder,
    $$DataSetsTableTableUpdateCompanionBuilder,
    (DataSet, BaseReferences<_$AppDatabase, $DataSetsTableTable, DataSet>),
    DataSet,
    PrefetchHooks Function()> {
  $$DataSetsTableTableTableManager(_$AppDatabase db, $DataSetsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DataSetsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DataSetsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DataSetsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> periodType = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<String> categoryComboUid = const Value.absent(),
            Value<int> openFuturePeriods = const Value.absent(),
            Value<int> expiryDays = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DataSetsTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            periodType: periodType,
            version: version,
            categoryComboUid: categoryComboUid,
            openFuturePeriods: openFuturePeriods,
            expiryDays: expiryDays,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            required String periodType,
            Value<int> version = const Value.absent(),
            required String categoryComboUid,
            Value<int> openFuturePeriods = const Value.absent(),
            Value<int> expiryDays = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DataSetsTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            periodType: periodType,
            version: version,
            categoryComboUid: categoryComboUid,
            openFuturePeriods: openFuturePeriods,
            expiryDays: expiryDays,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DataSetsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DataSetsTableTable,
    DataSet,
    $$DataSetsTableTableFilterComposer,
    $$DataSetsTableTableOrderingComposer,
    $$DataSetsTableTableAnnotationComposer,
    $$DataSetsTableTableCreateCompanionBuilder,
    $$DataSetsTableTableUpdateCompanionBuilder,
    (DataSet, BaseReferences<_$AppDatabase, $DataSetsTableTable, DataSet>),
    DataSet,
    PrefetchHooks Function()>;
typedef $$DataElementsTableTableCreateCompanionBuilder
    = DataElementsTableCompanion Function({
  required String uid,
  required String name,
  required String displayName,
  required String formName,
  Value<String?> description,
  required String valueType,
  required String categoryComboUid,
  Value<String?> optionSetUid,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$DataElementsTableTableUpdateCompanionBuilder
    = DataElementsTableCompanion Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<String> formName,
  Value<String?> description,
  Value<String> valueType,
  Value<String> categoryComboUid,
  Value<String?> optionSetUid,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$DataElementsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DataElementsTableTable> {
  $$DataElementsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formName => $composableBuilder(
      column: $table.formName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get valueType => $composableBuilder(
      column: $table.valueType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get optionSetUid => $composableBuilder(
      column: $table.optionSetUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$DataElementsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DataElementsTableTable> {
  $$DataElementsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formName => $composableBuilder(
      column: $table.formName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get valueType => $composableBuilder(
      column: $table.valueType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get optionSetUid => $composableBuilder(
      column: $table.optionSetUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$DataElementsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DataElementsTableTable> {
  $$DataElementsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get formName =>
      $composableBuilder(column: $table.formName, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get valueType =>
      $composableBuilder(column: $table.valueType, builder: (column) => column);

  GeneratedColumn<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid, builder: (column) => column);

  GeneratedColumn<String> get optionSetUid => $composableBuilder(
      column: $table.optionSetUid, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$DataElementsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DataElementsTableTable,
    DataElement,
    $$DataElementsTableTableFilterComposer,
    $$DataElementsTableTableOrderingComposer,
    $$DataElementsTableTableAnnotationComposer,
    $$DataElementsTableTableCreateCompanionBuilder,
    $$DataElementsTableTableUpdateCompanionBuilder,
    (
      DataElement,
      BaseReferences<_$AppDatabase, $DataElementsTableTable, DataElement>
    ),
    DataElement,
    PrefetchHooks Function()> {
  $$DataElementsTableTableTableManager(
      _$AppDatabase db, $DataElementsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DataElementsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DataElementsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DataElementsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> formName = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> valueType = const Value.absent(),
            Value<String> categoryComboUid = const Value.absent(),
            Value<String?> optionSetUid = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DataElementsTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            formName: formName,
            description: description,
            valueType: valueType,
            categoryComboUid: categoryComboUid,
            optionSetUid: optionSetUid,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            required String formName,
            Value<String?> description = const Value.absent(),
            required String valueType,
            required String categoryComboUid,
            Value<String?> optionSetUid = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DataElementsTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            formName: formName,
            description: description,
            valueType: valueType,
            categoryComboUid: categoryComboUid,
            optionSetUid: optionSetUid,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DataElementsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DataElementsTableTable,
    DataElement,
    $$DataElementsTableTableFilterComposer,
    $$DataElementsTableTableOrderingComposer,
    $$DataElementsTableTableAnnotationComposer,
    $$DataElementsTableTableCreateCompanionBuilder,
    $$DataElementsTableTableUpdateCompanionBuilder,
    (
      DataElement,
      BaseReferences<_$AppDatabase, $DataElementsTableTable, DataElement>
    ),
    DataElement,
    PrefetchHooks Function()>;
typedef $$SectionsTableTableCreateCompanionBuilder = SectionsTableCompanion
    Function({
  required String uid,
  required String name,
  required String displayName,
  required String dataSetUid,
  Value<int> sortOrder,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$SectionsTableTableUpdateCompanionBuilder = SectionsTableCompanion
    Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<String> dataSetUid,
  Value<int> sortOrder,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$SectionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SectionsTableTable> {
  $$SectionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$SectionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SectionsTableTable> {
  $$SectionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$SectionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SectionsTableTable> {
  $$SectionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$SectionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SectionsTableTable,
    Section,
    $$SectionsTableTableFilterComposer,
    $$SectionsTableTableOrderingComposer,
    $$SectionsTableTableAnnotationComposer,
    $$SectionsTableTableCreateCompanionBuilder,
    $$SectionsTableTableUpdateCompanionBuilder,
    (Section, BaseReferences<_$AppDatabase, $SectionsTableTable, Section>),
    Section,
    PrefetchHooks Function()> {
  $$SectionsTableTableTableManager(_$AppDatabase db, $SectionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SectionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SectionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SectionsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> dataSetUid = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SectionsTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            dataSetUid: dataSetUid,
            sortOrder: sortOrder,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            required String dataSetUid,
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SectionsTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            dataSetUid: dataSetUid,
            sortOrder: sortOrder,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SectionsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SectionsTableTable,
    Section,
    $$SectionsTableTableFilterComposer,
    $$SectionsTableTableOrderingComposer,
    $$SectionsTableTableAnnotationComposer,
    $$SectionsTableTableCreateCompanionBuilder,
    $$SectionsTableTableUpdateCompanionBuilder,
    (Section, BaseReferences<_$AppDatabase, $SectionsTableTable, Section>),
    Section,
    PrefetchHooks Function()>;
typedef $$IndicatorsTableTableCreateCompanionBuilder = IndicatorsTableCompanion
    Function({
  required String uid,
  required String name,
  required String displayName,
  required String numerator,
  required String denominator,
  Value<String?> description,
  Value<int> indicatorTypeFactor,
  Value<bool> annualized,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$IndicatorsTableTableUpdateCompanionBuilder = IndicatorsTableCompanion
    Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<String> numerator,
  Value<String> denominator,
  Value<String?> description,
  Value<int> indicatorTypeFactor,
  Value<bool> annualized,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$IndicatorsTableTableFilterComposer
    extends Composer<_$AppDatabase, $IndicatorsTableTable> {
  $$IndicatorsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get numerator => $composableBuilder(
      column: $table.numerator, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get denominator => $composableBuilder(
      column: $table.denominator, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get indicatorTypeFactor => $composableBuilder(
      column: $table.indicatorTypeFactor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get annualized => $composableBuilder(
      column: $table.annualized, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$IndicatorsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $IndicatorsTableTable> {
  $$IndicatorsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get numerator => $composableBuilder(
      column: $table.numerator, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get denominator => $composableBuilder(
      column: $table.denominator, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get indicatorTypeFactor => $composableBuilder(
      column: $table.indicatorTypeFactor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get annualized => $composableBuilder(
      column: $table.annualized, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$IndicatorsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $IndicatorsTableTable> {
  $$IndicatorsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get numerator =>
      $composableBuilder(column: $table.numerator, builder: (column) => column);

  GeneratedColumn<String> get denominator => $composableBuilder(
      column: $table.denominator, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get indicatorTypeFactor => $composableBuilder(
      column: $table.indicatorTypeFactor, builder: (column) => column);

  GeneratedColumn<bool> get annualized => $composableBuilder(
      column: $table.annualized, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$IndicatorsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IndicatorsTableTable,
    Indicator,
    $$IndicatorsTableTableFilterComposer,
    $$IndicatorsTableTableOrderingComposer,
    $$IndicatorsTableTableAnnotationComposer,
    $$IndicatorsTableTableCreateCompanionBuilder,
    $$IndicatorsTableTableUpdateCompanionBuilder,
    (
      Indicator,
      BaseReferences<_$AppDatabase, $IndicatorsTableTable, Indicator>
    ),
    Indicator,
    PrefetchHooks Function()> {
  $$IndicatorsTableTableTableManager(
      _$AppDatabase db, $IndicatorsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IndicatorsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IndicatorsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IndicatorsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> numerator = const Value.absent(),
            Value<String> denominator = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> indicatorTypeFactor = const Value.absent(),
            Value<bool> annualized = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IndicatorsTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            numerator: numerator,
            denominator: denominator,
            description: description,
            indicatorTypeFactor: indicatorTypeFactor,
            annualized: annualized,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            required String numerator,
            required String denominator,
            Value<String?> description = const Value.absent(),
            Value<int> indicatorTypeFactor = const Value.absent(),
            Value<bool> annualized = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IndicatorsTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            numerator: numerator,
            denominator: denominator,
            description: description,
            indicatorTypeFactor: indicatorTypeFactor,
            annualized: annualized,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IndicatorsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IndicatorsTableTable,
    Indicator,
    $$IndicatorsTableTableFilterComposer,
    $$IndicatorsTableTableOrderingComposer,
    $$IndicatorsTableTableAnnotationComposer,
    $$IndicatorsTableTableCreateCompanionBuilder,
    $$IndicatorsTableTableUpdateCompanionBuilder,
    (
      Indicator,
      BaseReferences<_$AppDatabase, $IndicatorsTableTable, Indicator>
    ),
    Indicator,
    PrefetchHooks Function()>;
typedef $$CategoriesTableTableCreateCompanionBuilder = CategoriesTableCompanion
    Function({
  required String uid,
  required String name,
  required String displayName,
  Value<String?> dataDimensionType,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$CategoriesTableTableUpdateCompanionBuilder = CategoriesTableCompanion
    Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<String?> dataDimensionType,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$CategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataDimensionType => $composableBuilder(
      column: $table.dataDimensionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$CategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataDimensionType => $composableBuilder(
      column: $table.dataDimensionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get dataDimensionType => $composableBuilder(
      column: $table.dataDimensionType, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$CategoriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTableTable,
    Category,
    $$CategoriesTableTableFilterComposer,
    $$CategoriesTableTableOrderingComposer,
    $$CategoriesTableTableAnnotationComposer,
    $$CategoriesTableTableCreateCompanionBuilder,
    $$CategoriesTableTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTableTable, Category>),
    Category,
    PrefetchHooks Function()> {
  $$CategoriesTableTableTableManager(
      _$AppDatabase db, $CategoriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String?> dataDimensionType = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            dataDimensionType: dataDimensionType,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            Value<String?> dataDimensionType = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            dataDimensionType: dataDimensionType,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTableTable,
    Category,
    $$CategoriesTableTableFilterComposer,
    $$CategoriesTableTableOrderingComposer,
    $$CategoriesTableTableAnnotationComposer,
    $$CategoriesTableTableCreateCompanionBuilder,
    $$CategoriesTableTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTableTable, Category>),
    Category,
    PrefetchHooks Function()>;
typedef $$CategoryOptionsTableTableCreateCompanionBuilder
    = CategoryOptionsTableCompanion Function({
  required String uid,
  required String name,
  required String displayName,
  Value<String?> shortName,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$CategoryOptionsTableTableUpdateCompanionBuilder
    = CategoryOptionsTableCompanion Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<String?> shortName,
  Value<String?> startDate,
  Value<String?> endDate,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$CategoryOptionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryOptionsTableTable> {
  $$CategoryOptionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shortName => $composableBuilder(
      column: $table.shortName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$CategoryOptionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryOptionsTableTable> {
  $$CategoryOptionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shortName => $composableBuilder(
      column: $table.shortName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$CategoryOptionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryOptionsTableTable> {
  $$CategoryOptionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get shortName =>
      $composableBuilder(column: $table.shortName, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$CategoryOptionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoryOptionsTableTable,
    CategoryOption,
    $$CategoryOptionsTableTableFilterComposer,
    $$CategoryOptionsTableTableOrderingComposer,
    $$CategoryOptionsTableTableAnnotationComposer,
    $$CategoryOptionsTableTableCreateCompanionBuilder,
    $$CategoryOptionsTableTableUpdateCompanionBuilder,
    (
      CategoryOption,
      BaseReferences<_$AppDatabase, $CategoryOptionsTableTable, CategoryOption>
    ),
    CategoryOption,
    PrefetchHooks Function()> {
  $$CategoryOptionsTableTableTableManager(
      _$AppDatabase db, $CategoryOptionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryOptionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryOptionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryOptionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String?> shortName = const Value.absent(),
            Value<String?> startDate = const Value.absent(),
            Value<String?> endDate = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryOptionsTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            shortName: shortName,
            startDate: startDate,
            endDate: endDate,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            Value<String?> shortName = const Value.absent(),
            Value<String?> startDate = const Value.absent(),
            Value<String?> endDate = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryOptionsTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            shortName: shortName,
            startDate: startDate,
            endDate: endDate,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoryOptionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CategoryOptionsTableTable,
        CategoryOption,
        $$CategoryOptionsTableTableFilterComposer,
        $$CategoryOptionsTableTableOrderingComposer,
        $$CategoryOptionsTableTableAnnotationComposer,
        $$CategoryOptionsTableTableCreateCompanionBuilder,
        $$CategoryOptionsTableTableUpdateCompanionBuilder,
        (
          CategoryOption,
          BaseReferences<_$AppDatabase, $CategoryOptionsTableTable,
              CategoryOption>
        ),
        CategoryOption,
        PrefetchHooks Function()>;
typedef $$CategoryCombosTableTableCreateCompanionBuilder
    = CategoryCombosTableCompanion Function({
  required String uid,
  required String name,
  required String displayName,
  Value<String?> dataDimensionType,
  Value<bool> skipTotal,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$CategoryCombosTableTableUpdateCompanionBuilder
    = CategoryCombosTableCompanion Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<String?> dataDimensionType,
  Value<bool> skipTotal,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$CategoryCombosTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryCombosTableTable> {
  $$CategoryCombosTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataDimensionType => $composableBuilder(
      column: $table.dataDimensionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get skipTotal => $composableBuilder(
      column: $table.skipTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$CategoryCombosTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryCombosTableTable> {
  $$CategoryCombosTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataDimensionType => $composableBuilder(
      column: $table.dataDimensionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get skipTotal => $composableBuilder(
      column: $table.skipTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$CategoryCombosTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryCombosTableTable> {
  $$CategoryCombosTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get dataDimensionType => $composableBuilder(
      column: $table.dataDimensionType, builder: (column) => column);

  GeneratedColumn<bool> get skipTotal =>
      $composableBuilder(column: $table.skipTotal, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$CategoryCombosTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoryCombosTableTable,
    CategoryCombo,
    $$CategoryCombosTableTableFilterComposer,
    $$CategoryCombosTableTableOrderingComposer,
    $$CategoryCombosTableTableAnnotationComposer,
    $$CategoryCombosTableTableCreateCompanionBuilder,
    $$CategoryCombosTableTableUpdateCompanionBuilder,
    (
      CategoryCombo,
      BaseReferences<_$AppDatabase, $CategoryCombosTableTable, CategoryCombo>
    ),
    CategoryCombo,
    PrefetchHooks Function()> {
  $$CategoryCombosTableTableTableManager(
      _$AppDatabase db, $CategoryCombosTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryCombosTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryCombosTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryCombosTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String?> dataDimensionType = const Value.absent(),
            Value<bool> skipTotal = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryCombosTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            dataDimensionType: dataDimensionType,
            skipTotal: skipTotal,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            Value<String?> dataDimensionType = const Value.absent(),
            Value<bool> skipTotal = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryCombosTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            dataDimensionType: dataDimensionType,
            skipTotal: skipTotal,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoryCombosTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoryCombosTableTable,
    CategoryCombo,
    $$CategoryCombosTableTableFilterComposer,
    $$CategoryCombosTableTableOrderingComposer,
    $$CategoryCombosTableTableAnnotationComposer,
    $$CategoryCombosTableTableCreateCompanionBuilder,
    $$CategoryCombosTableTableUpdateCompanionBuilder,
    (
      CategoryCombo,
      BaseReferences<_$AppDatabase, $CategoryCombosTableTable, CategoryCombo>
    ),
    CategoryCombo,
    PrefetchHooks Function()>;
typedef $$CategoryOptionCombosTableTableCreateCompanionBuilder
    = CategoryOptionCombosTableCompanion Function({
  required String uid,
  required String name,
  required String categoryComboUid,
  Value<int> sortOrder,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$CategoryOptionCombosTableTableUpdateCompanionBuilder
    = CategoryOptionCombosTableCompanion Function({
  Value<String> uid,
  Value<String> name,
  Value<String> categoryComboUid,
  Value<int> sortOrder,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$CategoryOptionCombosTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryOptionCombosTableTable> {
  $$CategoryOptionCombosTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$CategoryOptionCombosTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryOptionCombosTableTable> {
  $$CategoryOptionCombosTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$CategoryOptionCombosTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryOptionCombosTableTable> {
  $$CategoryOptionCombosTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$CategoryOptionCombosTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoryOptionCombosTableTable,
    CategoryOptionCombo,
    $$CategoryOptionCombosTableTableFilterComposer,
    $$CategoryOptionCombosTableTableOrderingComposer,
    $$CategoryOptionCombosTableTableAnnotationComposer,
    $$CategoryOptionCombosTableTableCreateCompanionBuilder,
    $$CategoryOptionCombosTableTableUpdateCompanionBuilder,
    (
      CategoryOptionCombo,
      BaseReferences<_$AppDatabase, $CategoryOptionCombosTableTable,
          CategoryOptionCombo>
    ),
    CategoryOptionCombo,
    PrefetchHooks Function()> {
  $$CategoryOptionCombosTableTableTableManager(
      _$AppDatabase db, $CategoryOptionCombosTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryOptionCombosTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryOptionCombosTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryOptionCombosTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> categoryComboUid = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryOptionCombosTableCompanion(
            uid: uid,
            name: name,
            categoryComboUid: categoryComboUid,
            sortOrder: sortOrder,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String categoryComboUid,
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryOptionCombosTableCompanion.insert(
            uid: uid,
            name: name,
            categoryComboUid: categoryComboUid,
            sortOrder: sortOrder,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoryOptionCombosTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CategoryOptionCombosTableTable,
        CategoryOptionCombo,
        $$CategoryOptionCombosTableTableFilterComposer,
        $$CategoryOptionCombosTableTableOrderingComposer,
        $$CategoryOptionCombosTableTableAnnotationComposer,
        $$CategoryOptionCombosTableTableCreateCompanionBuilder,
        $$CategoryOptionCombosTableTableUpdateCompanionBuilder,
        (
          CategoryOptionCombo,
          BaseReferences<_$AppDatabase, $CategoryOptionCombosTableTable,
              CategoryOptionCombo>
        ),
        CategoryOptionCombo,
        PrefetchHooks Function()>;
typedef $$OptionSetsTableTableCreateCompanionBuilder = OptionSetsTableCompanion
    Function({
  required String uid,
  required String name,
  required String displayName,
  required String valueType,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$OptionSetsTableTableUpdateCompanionBuilder = OptionSetsTableCompanion
    Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<String> valueType,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$OptionSetsTableTableFilterComposer
    extends Composer<_$AppDatabase, $OptionSetsTableTable> {
  $$OptionSetsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get valueType => $composableBuilder(
      column: $table.valueType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$OptionSetsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OptionSetsTableTable> {
  $$OptionSetsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get valueType => $composableBuilder(
      column: $table.valueType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$OptionSetsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OptionSetsTableTable> {
  $$OptionSetsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get valueType =>
      $composableBuilder(column: $table.valueType, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$OptionSetsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OptionSetsTableTable,
    OptionSet,
    $$OptionSetsTableTableFilterComposer,
    $$OptionSetsTableTableOrderingComposer,
    $$OptionSetsTableTableAnnotationComposer,
    $$OptionSetsTableTableCreateCompanionBuilder,
    $$OptionSetsTableTableUpdateCompanionBuilder,
    (
      OptionSet,
      BaseReferences<_$AppDatabase, $OptionSetsTableTable, OptionSet>
    ),
    OptionSet,
    PrefetchHooks Function()> {
  $$OptionSetsTableTableTableManager(
      _$AppDatabase db, $OptionSetsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OptionSetsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OptionSetsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OptionSetsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> valueType = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OptionSetsTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            valueType: valueType,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            required String valueType,
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OptionSetsTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            valueType: valueType,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OptionSetsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OptionSetsTableTable,
    OptionSet,
    $$OptionSetsTableTableFilterComposer,
    $$OptionSetsTableTableOrderingComposer,
    $$OptionSetsTableTableAnnotationComposer,
    $$OptionSetsTableTableCreateCompanionBuilder,
    $$OptionSetsTableTableUpdateCompanionBuilder,
    (
      OptionSet,
      BaseReferences<_$AppDatabase, $OptionSetsTableTable, OptionSet>
    ),
    OptionSet,
    PrefetchHooks Function()>;
typedef $$OptionsTableTableCreateCompanionBuilder = OptionsTableCompanion
    Function({
  required String uid,
  required String code,
  required String name,
  required String displayName,
  Value<int> sortOrder,
  required String optionSetUid,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$OptionsTableTableUpdateCompanionBuilder = OptionsTableCompanion
    Function({
  Value<String> uid,
  Value<String> code,
  Value<String> name,
  Value<String> displayName,
  Value<int> sortOrder,
  Value<String> optionSetUid,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$OptionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $OptionsTableTable> {
  $$OptionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get optionSetUid => $composableBuilder(
      column: $table.optionSetUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$OptionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OptionsTableTable> {
  $$OptionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get optionSetUid => $composableBuilder(
      column: $table.optionSetUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$OptionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OptionsTableTable> {
  $$OptionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get optionSetUid => $composableBuilder(
      column: $table.optionSetUid, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$OptionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OptionsTableTable,
    OptionItem,
    $$OptionsTableTableFilterComposer,
    $$OptionsTableTableOrderingComposer,
    $$OptionsTableTableAnnotationComposer,
    $$OptionsTableTableCreateCompanionBuilder,
    $$OptionsTableTableUpdateCompanionBuilder,
    (OptionItem, BaseReferences<_$AppDatabase, $OptionsTableTable, OptionItem>),
    OptionItem,
    PrefetchHooks Function()> {
  $$OptionsTableTableTableManager(_$AppDatabase db, $OptionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OptionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OptionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OptionsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String> optionSetUid = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OptionsTableCompanion(
            uid: uid,
            code: code,
            name: name,
            displayName: displayName,
            sortOrder: sortOrder,
            optionSetUid: optionSetUid,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String code,
            required String name,
            required String displayName,
            Value<int> sortOrder = const Value.absent(),
            required String optionSetUid,
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OptionsTableCompanion.insert(
            uid: uid,
            code: code,
            name: name,
            displayName: displayName,
            sortOrder: sortOrder,
            optionSetUid: optionSetUid,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OptionsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OptionsTableTable,
    OptionItem,
    $$OptionsTableTableFilterComposer,
    $$OptionsTableTableOrderingComposer,
    $$OptionsTableTableAnnotationComposer,
    $$OptionsTableTableCreateCompanionBuilder,
    $$OptionsTableTableUpdateCompanionBuilder,
    (OptionItem, BaseReferences<_$AppDatabase, $OptionsTableTable, OptionItem>),
    OptionItem,
    PrefetchHooks Function()>;
typedef $$DataElementGroupsTableTableCreateCompanionBuilder
    = DataElementGroupsTableCompanion Function({
  required String uid,
  required String name,
  required String displayName,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$DataElementGroupsTableTableUpdateCompanionBuilder
    = DataElementGroupsTableCompanion Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$DataElementGroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DataElementGroupsTableTable> {
  $$DataElementGroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$DataElementGroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DataElementGroupsTableTable> {
  $$DataElementGroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$DataElementGroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DataElementGroupsTableTable> {
  $$DataElementGroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$DataElementGroupsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DataElementGroupsTableTable,
    DataElementGroup,
    $$DataElementGroupsTableTableFilterComposer,
    $$DataElementGroupsTableTableOrderingComposer,
    $$DataElementGroupsTableTableAnnotationComposer,
    $$DataElementGroupsTableTableCreateCompanionBuilder,
    $$DataElementGroupsTableTableUpdateCompanionBuilder,
    (
      DataElementGroup,
      BaseReferences<_$AppDatabase, $DataElementGroupsTableTable,
          DataElementGroup>
    ),
    DataElementGroup,
    PrefetchHooks Function()> {
  $$DataElementGroupsTableTableTableManager(
      _$AppDatabase db, $DataElementGroupsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DataElementGroupsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$DataElementGroupsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DataElementGroupsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DataElementGroupsTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DataElementGroupsTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DataElementGroupsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DataElementGroupsTableTable,
        DataElementGroup,
        $$DataElementGroupsTableTableFilterComposer,
        $$DataElementGroupsTableTableOrderingComposer,
        $$DataElementGroupsTableTableAnnotationComposer,
        $$DataElementGroupsTableTableCreateCompanionBuilder,
        $$DataElementGroupsTableTableUpdateCompanionBuilder,
        (
          DataElementGroup,
          BaseReferences<_$AppDatabase, $DataElementGroupsTableTable,
              DataElementGroup>
        ),
        DataElementGroup,
        PrefetchHooks Function()>;
typedef $$ValidationRulesTableTableCreateCompanionBuilder
    = ValidationRulesTableCompanion Function({
  required String uid,
  required String name,
  required String displayName,
  Value<String?> description,
  Value<String?> importance,
  required String operator,
  Value<String?> instruction,
  Value<String?> periodType,
  required String leftExpression,
  Value<String?> leftDescription,
  Value<String?> leftMissingValueStrategy,
  required String rightExpression,
  Value<String?> rightDescription,
  Value<String?> rightMissingValueStrategy,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});
typedef $$ValidationRulesTableTableUpdateCompanionBuilder
    = ValidationRulesTableCompanion Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<String?> description,
  Value<String?> importance,
  Value<String> operator,
  Value<String?> instruction,
  Value<String?> periodType,
  Value<String> leftExpression,
  Value<String?> leftDescription,
  Value<String?> leftMissingValueStrategy,
  Value<String> rightExpression,
  Value<String?> rightDescription,
  Value<String?> rightMissingValueStrategy,
  Value<DateTime?> lastUpdated,
  Value<int> rowid,
});

class $$ValidationRulesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ValidationRulesTableTable> {
  $$ValidationRulesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operator => $composableBuilder(
      column: $table.operator, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instruction => $composableBuilder(
      column: $table.instruction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get leftExpression => $composableBuilder(
      column: $table.leftExpression,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get leftDescription => $composableBuilder(
      column: $table.leftDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get leftMissingValueStrategy => $composableBuilder(
      column: $table.leftMissingValueStrategy,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rightExpression => $composableBuilder(
      column: $table.rightExpression,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rightDescription => $composableBuilder(
      column: $table.rightDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rightMissingValueStrategy => $composableBuilder(
      column: $table.rightMissingValueStrategy,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnFilters(column));
}

class $$ValidationRulesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ValidationRulesTableTable> {
  $$ValidationRulesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operator => $composableBuilder(
      column: $table.operator, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instruction => $composableBuilder(
      column: $table.instruction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get leftExpression => $composableBuilder(
      column: $table.leftExpression,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get leftDescription => $composableBuilder(
      column: $table.leftDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get leftMissingValueStrategy => $composableBuilder(
      column: $table.leftMissingValueStrategy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rightExpression => $composableBuilder(
      column: $table.rightExpression,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rightDescription => $composableBuilder(
      column: $table.rightDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rightMissingValueStrategy => $composableBuilder(
      column: $table.rightMissingValueStrategy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => ColumnOrderings(column));
}

class $$ValidationRulesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ValidationRulesTableTable> {
  $$ValidationRulesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => column);

  GeneratedColumn<String> get operator =>
      $composableBuilder(column: $table.operator, builder: (column) => column);

  GeneratedColumn<String> get instruction => $composableBuilder(
      column: $table.instruction, builder: (column) => column);

  GeneratedColumn<String> get periodType => $composableBuilder(
      column: $table.periodType, builder: (column) => column);

  GeneratedColumn<String> get leftExpression => $composableBuilder(
      column: $table.leftExpression, builder: (column) => column);

  GeneratedColumn<String> get leftDescription => $composableBuilder(
      column: $table.leftDescription, builder: (column) => column);

  GeneratedColumn<String> get leftMissingValueStrategy => $composableBuilder(
      column: $table.leftMissingValueStrategy, builder: (column) => column);

  GeneratedColumn<String> get rightExpression => $composableBuilder(
      column: $table.rightExpression, builder: (column) => column);

  GeneratedColumn<String> get rightDescription => $composableBuilder(
      column: $table.rightDescription, builder: (column) => column);

  GeneratedColumn<String> get rightMissingValueStrategy => $composableBuilder(
      column: $table.rightMissingValueStrategy, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
      column: $table.lastUpdated, builder: (column) => column);
}

class $$ValidationRulesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ValidationRulesTableTable,
    ValidationRule,
    $$ValidationRulesTableTableFilterComposer,
    $$ValidationRulesTableTableOrderingComposer,
    $$ValidationRulesTableTableAnnotationComposer,
    $$ValidationRulesTableTableCreateCompanionBuilder,
    $$ValidationRulesTableTableUpdateCompanionBuilder,
    (
      ValidationRule,
      BaseReferences<_$AppDatabase, $ValidationRulesTableTable, ValidationRule>
    ),
    ValidationRule,
    PrefetchHooks Function()> {
  $$ValidationRulesTableTableTableManager(
      _$AppDatabase db, $ValidationRulesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ValidationRulesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ValidationRulesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ValidationRulesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> importance = const Value.absent(),
            Value<String> operator = const Value.absent(),
            Value<String?> instruction = const Value.absent(),
            Value<String?> periodType = const Value.absent(),
            Value<String> leftExpression = const Value.absent(),
            Value<String?> leftDescription = const Value.absent(),
            Value<String?> leftMissingValueStrategy = const Value.absent(),
            Value<String> rightExpression = const Value.absent(),
            Value<String?> rightDescription = const Value.absent(),
            Value<String?> rightMissingValueStrategy = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ValidationRulesTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            description: description,
            importance: importance,
            operator: operator,
            instruction: instruction,
            periodType: periodType,
            leftExpression: leftExpression,
            leftDescription: leftDescription,
            leftMissingValueStrategy: leftMissingValueStrategy,
            rightExpression: rightExpression,
            rightDescription: rightDescription,
            rightMissingValueStrategy: rightMissingValueStrategy,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            Value<String?> description = const Value.absent(),
            Value<String?> importance = const Value.absent(),
            required String operator,
            Value<String?> instruction = const Value.absent(),
            Value<String?> periodType = const Value.absent(),
            required String leftExpression,
            Value<String?> leftDescription = const Value.absent(),
            Value<String?> leftMissingValueStrategy = const Value.absent(),
            required String rightExpression,
            Value<String?> rightDescription = const Value.absent(),
            Value<String?> rightMissingValueStrategy = const Value.absent(),
            Value<DateTime?> lastUpdated = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ValidationRulesTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            description: description,
            importance: importance,
            operator: operator,
            instruction: instruction,
            periodType: periodType,
            leftExpression: leftExpression,
            leftDescription: leftDescription,
            leftMissingValueStrategy: leftMissingValueStrategy,
            rightExpression: rightExpression,
            rightDescription: rightDescription,
            rightMissingValueStrategy: rightMissingValueStrategy,
            lastUpdated: lastUpdated,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ValidationRulesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ValidationRulesTableTable,
        ValidationRule,
        $$ValidationRulesTableTableFilterComposer,
        $$ValidationRulesTableTableOrderingComposer,
        $$ValidationRulesTableTableAnnotationComposer,
        $$ValidationRulesTableTableCreateCompanionBuilder,
        $$ValidationRulesTableTableUpdateCompanionBuilder,
        (
          ValidationRule,
          BaseReferences<_$AppDatabase, $ValidationRulesTableTable,
              ValidationRule>
        ),
        ValidationRule,
        PrefetchHooks Function()>;
typedef $$DataSetElementsTableTableCreateCompanionBuilder
    = DataSetElementsTableCompanion Function({
  required String dataSetUid,
  required String dataElementUid,
  required String categoryComboUid,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$DataSetElementsTableTableUpdateCompanionBuilder
    = DataSetElementsTableCompanion Function({
  Value<String> dataSetUid,
  Value<String> dataElementUid,
  Value<String> categoryComboUid,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$DataSetElementsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DataSetElementsTableTable> {
  $$DataSetElementsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$DataSetElementsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DataSetElementsTableTable> {
  $$DataSetElementsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$DataSetElementsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DataSetElementsTableTable> {
  $$DataSetElementsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => column);

  GeneratedColumn<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid, builder: (column) => column);

  GeneratedColumn<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$DataSetElementsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DataSetElementsTableTable,
    DataSetElement,
    $$DataSetElementsTableTableFilterComposer,
    $$DataSetElementsTableTableOrderingComposer,
    $$DataSetElementsTableTableAnnotationComposer,
    $$DataSetElementsTableTableCreateCompanionBuilder,
    $$DataSetElementsTableTableUpdateCompanionBuilder,
    (
      DataSetElement,
      BaseReferences<_$AppDatabase, $DataSetElementsTableTable, DataSetElement>
    ),
    DataSetElement,
    PrefetchHooks Function()> {
  $$DataSetElementsTableTableTableManager(
      _$AppDatabase db, $DataSetElementsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DataSetElementsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DataSetElementsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DataSetElementsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> dataSetUid = const Value.absent(),
            Value<String> dataElementUid = const Value.absent(),
            Value<String> categoryComboUid = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DataSetElementsTableCompanion(
            dataSetUid: dataSetUid,
            dataElementUid: dataElementUid,
            categoryComboUid: categoryComboUid,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String dataSetUid,
            required String dataElementUid,
            required String categoryComboUid,
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DataSetElementsTableCompanion.insert(
            dataSetUid: dataSetUid,
            dataElementUid: dataElementUid,
            categoryComboUid: categoryComboUid,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DataSetElementsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DataSetElementsTableTable,
        DataSetElement,
        $$DataSetElementsTableTableFilterComposer,
        $$DataSetElementsTableTableOrderingComposer,
        $$DataSetElementsTableTableAnnotationComposer,
        $$DataSetElementsTableTableCreateCompanionBuilder,
        $$DataSetElementsTableTableUpdateCompanionBuilder,
        (
          DataSetElement,
          BaseReferences<_$AppDatabase, $DataSetElementsTableTable,
              DataSetElement>
        ),
        DataSetElement,
        PrefetchHooks Function()>;
typedef $$DataSetOrgUnitsTableTableCreateCompanionBuilder
    = DataSetOrgUnitsTableCompanion Function({
  required String dataSetUid,
  required String orgUnitUid,
  Value<int> rowid,
});
typedef $$DataSetOrgUnitsTableTableUpdateCompanionBuilder
    = DataSetOrgUnitsTableCompanion Function({
  Value<String> dataSetUid,
  Value<String> orgUnitUid,
  Value<int> rowid,
});

class $$DataSetOrgUnitsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DataSetOrgUnitsTableTable> {
  $$DataSetOrgUnitsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orgUnitUid => $composableBuilder(
      column: $table.orgUnitUid, builder: (column) => ColumnFilters(column));
}

class $$DataSetOrgUnitsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DataSetOrgUnitsTableTable> {
  $$DataSetOrgUnitsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orgUnitUid => $composableBuilder(
      column: $table.orgUnitUid, builder: (column) => ColumnOrderings(column));
}

class $$DataSetOrgUnitsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DataSetOrgUnitsTableTable> {
  $$DataSetOrgUnitsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => column);

  GeneratedColumn<String> get orgUnitUid => $composableBuilder(
      column: $table.orgUnitUid, builder: (column) => column);
}

class $$DataSetOrgUnitsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DataSetOrgUnitsTableTable,
    DataSetOrgUnit,
    $$DataSetOrgUnitsTableTableFilterComposer,
    $$DataSetOrgUnitsTableTableOrderingComposer,
    $$DataSetOrgUnitsTableTableAnnotationComposer,
    $$DataSetOrgUnitsTableTableCreateCompanionBuilder,
    $$DataSetOrgUnitsTableTableUpdateCompanionBuilder,
    (
      DataSetOrgUnit,
      BaseReferences<_$AppDatabase, $DataSetOrgUnitsTableTable, DataSetOrgUnit>
    ),
    DataSetOrgUnit,
    PrefetchHooks Function()> {
  $$DataSetOrgUnitsTableTableTableManager(
      _$AppDatabase db, $DataSetOrgUnitsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DataSetOrgUnitsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DataSetOrgUnitsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DataSetOrgUnitsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> dataSetUid = const Value.absent(),
            Value<String> orgUnitUid = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DataSetOrgUnitsTableCompanion(
            dataSetUid: dataSetUid,
            orgUnitUid: orgUnitUid,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String dataSetUid,
            required String orgUnitUid,
            Value<int> rowid = const Value.absent(),
          }) =>
              DataSetOrgUnitsTableCompanion.insert(
            dataSetUid: dataSetUid,
            orgUnitUid: orgUnitUid,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DataSetOrgUnitsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DataSetOrgUnitsTableTable,
        DataSetOrgUnit,
        $$DataSetOrgUnitsTableTableFilterComposer,
        $$DataSetOrgUnitsTableTableOrderingComposer,
        $$DataSetOrgUnitsTableTableAnnotationComposer,
        $$DataSetOrgUnitsTableTableCreateCompanionBuilder,
        $$DataSetOrgUnitsTableTableUpdateCompanionBuilder,
        (
          DataSetOrgUnit,
          BaseReferences<_$AppDatabase, $DataSetOrgUnitsTableTable,
              DataSetOrgUnit>
        ),
        DataSetOrgUnit,
        PrefetchHooks Function()>;
typedef $$SectionDataElementsTableTableCreateCompanionBuilder
    = SectionDataElementsTableCompanion Function({
  required String sectionUid,
  required String dataElementUid,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$SectionDataElementsTableTableUpdateCompanionBuilder
    = SectionDataElementsTableCompanion Function({
  Value<String> sectionUid,
  Value<String> dataElementUid,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$SectionDataElementsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SectionDataElementsTableTable> {
  $$SectionDataElementsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sectionUid => $composableBuilder(
      column: $table.sectionUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$SectionDataElementsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SectionDataElementsTableTable> {
  $$SectionDataElementsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sectionUid => $composableBuilder(
      column: $table.sectionUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$SectionDataElementsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SectionDataElementsTableTable> {
  $$SectionDataElementsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sectionUid => $composableBuilder(
      column: $table.sectionUid, builder: (column) => column);

  GeneratedColumn<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$SectionDataElementsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SectionDataElementsTableTable,
    SectionDataElement,
    $$SectionDataElementsTableTableFilterComposer,
    $$SectionDataElementsTableTableOrderingComposer,
    $$SectionDataElementsTableTableAnnotationComposer,
    $$SectionDataElementsTableTableCreateCompanionBuilder,
    $$SectionDataElementsTableTableUpdateCompanionBuilder,
    (
      SectionDataElement,
      BaseReferences<_$AppDatabase, $SectionDataElementsTableTable,
          SectionDataElement>
    ),
    SectionDataElement,
    PrefetchHooks Function()> {
  $$SectionDataElementsTableTableTableManager(
      _$AppDatabase db, $SectionDataElementsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SectionDataElementsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SectionDataElementsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SectionDataElementsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sectionUid = const Value.absent(),
            Value<String> dataElementUid = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SectionDataElementsTableCompanion(
            sectionUid: sectionUid,
            dataElementUid: dataElementUid,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sectionUid,
            required String dataElementUid,
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SectionDataElementsTableCompanion.insert(
            sectionUid: sectionUid,
            dataElementUid: dataElementUid,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SectionDataElementsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $SectionDataElementsTableTable,
        SectionDataElement,
        $$SectionDataElementsTableTableFilterComposer,
        $$SectionDataElementsTableTableOrderingComposer,
        $$SectionDataElementsTableTableAnnotationComposer,
        $$SectionDataElementsTableTableCreateCompanionBuilder,
        $$SectionDataElementsTableTableUpdateCompanionBuilder,
        (
          SectionDataElement,
          BaseReferences<_$AppDatabase, $SectionDataElementsTableTable,
              SectionDataElement>
        ),
        SectionDataElement,
        PrefetchHooks Function()>;
typedef $$SectionIndicatorsTableTableCreateCompanionBuilder
    = SectionIndicatorsTableCompanion Function({
  required String sectionUid,
  required String indicatorUid,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$SectionIndicatorsTableTableUpdateCompanionBuilder
    = SectionIndicatorsTableCompanion Function({
  Value<String> sectionUid,
  Value<String> indicatorUid,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$SectionIndicatorsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SectionIndicatorsTableTable> {
  $$SectionIndicatorsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sectionUid => $composableBuilder(
      column: $table.sectionUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get indicatorUid => $composableBuilder(
      column: $table.indicatorUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$SectionIndicatorsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SectionIndicatorsTableTable> {
  $$SectionIndicatorsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sectionUid => $composableBuilder(
      column: $table.sectionUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get indicatorUid => $composableBuilder(
      column: $table.indicatorUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$SectionIndicatorsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SectionIndicatorsTableTable> {
  $$SectionIndicatorsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sectionUid => $composableBuilder(
      column: $table.sectionUid, builder: (column) => column);

  GeneratedColumn<String> get indicatorUid => $composableBuilder(
      column: $table.indicatorUid, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$SectionIndicatorsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SectionIndicatorsTableTable,
    SectionIndicator,
    $$SectionIndicatorsTableTableFilterComposer,
    $$SectionIndicatorsTableTableOrderingComposer,
    $$SectionIndicatorsTableTableAnnotationComposer,
    $$SectionIndicatorsTableTableCreateCompanionBuilder,
    $$SectionIndicatorsTableTableUpdateCompanionBuilder,
    (
      SectionIndicator,
      BaseReferences<_$AppDatabase, $SectionIndicatorsTableTable,
          SectionIndicator>
    ),
    SectionIndicator,
    PrefetchHooks Function()> {
  $$SectionIndicatorsTableTableTableManager(
      _$AppDatabase db, $SectionIndicatorsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SectionIndicatorsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SectionIndicatorsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SectionIndicatorsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sectionUid = const Value.absent(),
            Value<String> indicatorUid = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SectionIndicatorsTableCompanion(
            sectionUid: sectionUid,
            indicatorUid: indicatorUid,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sectionUid,
            required String indicatorUid,
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SectionIndicatorsTableCompanion.insert(
            sectionUid: sectionUid,
            indicatorUid: indicatorUid,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SectionIndicatorsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $SectionIndicatorsTableTable,
        SectionIndicator,
        $$SectionIndicatorsTableTableFilterComposer,
        $$SectionIndicatorsTableTableOrderingComposer,
        $$SectionIndicatorsTableTableAnnotationComposer,
        $$SectionIndicatorsTableTableCreateCompanionBuilder,
        $$SectionIndicatorsTableTableUpdateCompanionBuilder,
        (
          SectionIndicator,
          BaseReferences<_$AppDatabase, $SectionIndicatorsTableTable,
              SectionIndicator>
        ),
        SectionIndicator,
        PrefetchHooks Function()>;
typedef $$SectionGreyFieldsTableTableCreateCompanionBuilder
    = SectionGreyFieldsTableCompanion Function({
  required String sectionUid,
  required String dataElementUid,
  required String categoryOptionComboUid,
  Value<int> rowid,
});
typedef $$SectionGreyFieldsTableTableUpdateCompanionBuilder
    = SectionGreyFieldsTableCompanion Function({
  Value<String> sectionUid,
  Value<String> dataElementUid,
  Value<String> categoryOptionComboUid,
  Value<int> rowid,
});

class $$SectionGreyFieldsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SectionGreyFieldsTableTable> {
  $$SectionGreyFieldsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sectionUid => $composableBuilder(
      column: $table.sectionUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryOptionComboUid => $composableBuilder(
      column: $table.categoryOptionComboUid,
      builder: (column) => ColumnFilters(column));
}

class $$SectionGreyFieldsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SectionGreyFieldsTableTable> {
  $$SectionGreyFieldsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sectionUid => $composableBuilder(
      column: $table.sectionUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryOptionComboUid => $composableBuilder(
      column: $table.categoryOptionComboUid,
      builder: (column) => ColumnOrderings(column));
}

class $$SectionGreyFieldsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SectionGreyFieldsTableTable> {
  $$SectionGreyFieldsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sectionUid => $composableBuilder(
      column: $table.sectionUid, builder: (column) => column);

  GeneratedColumn<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid, builder: (column) => column);

  GeneratedColumn<String> get categoryOptionComboUid => $composableBuilder(
      column: $table.categoryOptionComboUid, builder: (column) => column);
}

class $$SectionGreyFieldsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SectionGreyFieldsTableTable,
    SectionGreyField,
    $$SectionGreyFieldsTableTableFilterComposer,
    $$SectionGreyFieldsTableTableOrderingComposer,
    $$SectionGreyFieldsTableTableAnnotationComposer,
    $$SectionGreyFieldsTableTableCreateCompanionBuilder,
    $$SectionGreyFieldsTableTableUpdateCompanionBuilder,
    (
      SectionGreyField,
      BaseReferences<_$AppDatabase, $SectionGreyFieldsTableTable,
          SectionGreyField>
    ),
    SectionGreyField,
    PrefetchHooks Function()> {
  $$SectionGreyFieldsTableTableTableManager(
      _$AppDatabase db, $SectionGreyFieldsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SectionGreyFieldsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SectionGreyFieldsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SectionGreyFieldsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sectionUid = const Value.absent(),
            Value<String> dataElementUid = const Value.absent(),
            Value<String> categoryOptionComboUid = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SectionGreyFieldsTableCompanion(
            sectionUid: sectionUid,
            dataElementUid: dataElementUid,
            categoryOptionComboUid: categoryOptionComboUid,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sectionUid,
            required String dataElementUid,
            required String categoryOptionComboUid,
            Value<int> rowid = const Value.absent(),
          }) =>
              SectionGreyFieldsTableCompanion.insert(
            sectionUid: sectionUid,
            dataElementUid: dataElementUid,
            categoryOptionComboUid: categoryOptionComboUid,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SectionGreyFieldsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $SectionGreyFieldsTableTable,
        SectionGreyField,
        $$SectionGreyFieldsTableTableFilterComposer,
        $$SectionGreyFieldsTableTableOrderingComposer,
        $$SectionGreyFieldsTableTableAnnotationComposer,
        $$SectionGreyFieldsTableTableCreateCompanionBuilder,
        $$SectionGreyFieldsTableTableUpdateCompanionBuilder,
        (
          SectionGreyField,
          BaseReferences<_$AppDatabase, $SectionGreyFieldsTableTable,
              SectionGreyField>
        ),
        SectionGreyField,
        PrefetchHooks Function()>;
typedef $$DataElementGroupMembersTableTableCreateCompanionBuilder
    = DataElementGroupMembersTableCompanion Function({
  required String dataElementGroupUid,
  required String dataElementUid,
  Value<int> rowid,
});
typedef $$DataElementGroupMembersTableTableUpdateCompanionBuilder
    = DataElementGroupMembersTableCompanion Function({
  Value<String> dataElementGroupUid,
  Value<String> dataElementUid,
  Value<int> rowid,
});

class $$DataElementGroupMembersTableTableFilterComposer
    extends Composer<_$AppDatabase, $DataElementGroupMembersTableTable> {
  $$DataElementGroupMembersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dataElementGroupUid => $composableBuilder(
      column: $table.dataElementGroupUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid,
      builder: (column) => ColumnFilters(column));
}

class $$DataElementGroupMembersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DataElementGroupMembersTableTable> {
  $$DataElementGroupMembersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dataElementGroupUid => $composableBuilder(
      column: $table.dataElementGroupUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid,
      builder: (column) => ColumnOrderings(column));
}

class $$DataElementGroupMembersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DataElementGroupMembersTableTable> {
  $$DataElementGroupMembersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dataElementGroupUid => $composableBuilder(
      column: $table.dataElementGroupUid, builder: (column) => column);

  GeneratedColumn<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid, builder: (column) => column);
}

class $$DataElementGroupMembersTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DataElementGroupMembersTableTable,
    DataElementGroupMember,
    $$DataElementGroupMembersTableTableFilterComposer,
    $$DataElementGroupMembersTableTableOrderingComposer,
    $$DataElementGroupMembersTableTableAnnotationComposer,
    $$DataElementGroupMembersTableTableCreateCompanionBuilder,
    $$DataElementGroupMembersTableTableUpdateCompanionBuilder,
    (
      DataElementGroupMember,
      BaseReferences<_$AppDatabase, $DataElementGroupMembersTableTable,
          DataElementGroupMember>
    ),
    DataElementGroupMember,
    PrefetchHooks Function()> {
  $$DataElementGroupMembersTableTableTableManager(
      _$AppDatabase db, $DataElementGroupMembersTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DataElementGroupMembersTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$DataElementGroupMembersTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DataElementGroupMembersTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> dataElementGroupUid = const Value.absent(),
            Value<String> dataElementUid = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DataElementGroupMembersTableCompanion(
            dataElementGroupUid: dataElementGroupUid,
            dataElementUid: dataElementUid,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String dataElementGroupUid,
            required String dataElementUid,
            Value<int> rowid = const Value.absent(),
          }) =>
              DataElementGroupMembersTableCompanion.insert(
            dataElementGroupUid: dataElementGroupUid,
            dataElementUid: dataElementUid,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DataElementGroupMembersTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DataElementGroupMembersTableTable,
        DataElementGroupMember,
        $$DataElementGroupMembersTableTableFilterComposer,
        $$DataElementGroupMembersTableTableOrderingComposer,
        $$DataElementGroupMembersTableTableAnnotationComposer,
        $$DataElementGroupMembersTableTableCreateCompanionBuilder,
        $$DataElementGroupMembersTableTableUpdateCompanionBuilder,
        (
          DataElementGroupMember,
          BaseReferences<_$AppDatabase, $DataElementGroupMembersTableTable,
              DataElementGroupMember>
        ),
        DataElementGroupMember,
        PrefetchHooks Function()>;
typedef $$CategoryCategoryOptionsTableTableCreateCompanionBuilder
    = CategoryCategoryOptionsTableCompanion Function({
  required String categoryUid,
  required String categoryOptionUid,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$CategoryCategoryOptionsTableTableUpdateCompanionBuilder
    = CategoryCategoryOptionsTableCompanion Function({
  Value<String> categoryUid,
  Value<String> categoryOptionUid,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$CategoryCategoryOptionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryCategoryOptionsTableTable> {
  $$CategoryCategoryOptionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get categoryUid => $composableBuilder(
      column: $table.categoryUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryOptionUid => $composableBuilder(
      column: $table.categoryOptionUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$CategoryCategoryOptionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryCategoryOptionsTableTable> {
  $$CategoryCategoryOptionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get categoryUid => $composableBuilder(
      column: $table.categoryUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryOptionUid => $composableBuilder(
      column: $table.categoryOptionUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$CategoryCategoryOptionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryCategoryOptionsTableTable> {
  $$CategoryCategoryOptionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get categoryUid => $composableBuilder(
      column: $table.categoryUid, builder: (column) => column);

  GeneratedColumn<String> get categoryOptionUid => $composableBuilder(
      column: $table.categoryOptionUid, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CategoryCategoryOptionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoryCategoryOptionsTableTable,
    CategoryCategoryOption,
    $$CategoryCategoryOptionsTableTableFilterComposer,
    $$CategoryCategoryOptionsTableTableOrderingComposer,
    $$CategoryCategoryOptionsTableTableAnnotationComposer,
    $$CategoryCategoryOptionsTableTableCreateCompanionBuilder,
    $$CategoryCategoryOptionsTableTableUpdateCompanionBuilder,
    (
      CategoryCategoryOption,
      BaseReferences<_$AppDatabase, $CategoryCategoryOptionsTableTable,
          CategoryCategoryOption>
    ),
    CategoryCategoryOption,
    PrefetchHooks Function()> {
  $$CategoryCategoryOptionsTableTableTableManager(
      _$AppDatabase db, $CategoryCategoryOptionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryCategoryOptionsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryCategoryOptionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryCategoryOptionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> categoryUid = const Value.absent(),
            Value<String> categoryOptionUid = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryCategoryOptionsTableCompanion(
            categoryUid: categoryUid,
            categoryOptionUid: categoryOptionUid,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String categoryUid,
            required String categoryOptionUid,
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryCategoryOptionsTableCompanion.insert(
            categoryUid: categoryUid,
            categoryOptionUid: categoryOptionUid,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoryCategoryOptionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CategoryCategoryOptionsTableTable,
        CategoryCategoryOption,
        $$CategoryCategoryOptionsTableTableFilterComposer,
        $$CategoryCategoryOptionsTableTableOrderingComposer,
        $$CategoryCategoryOptionsTableTableAnnotationComposer,
        $$CategoryCategoryOptionsTableTableCreateCompanionBuilder,
        $$CategoryCategoryOptionsTableTableUpdateCompanionBuilder,
        (
          CategoryCategoryOption,
          BaseReferences<_$AppDatabase, $CategoryCategoryOptionsTableTable,
              CategoryCategoryOption>
        ),
        CategoryCategoryOption,
        PrefetchHooks Function()>;
typedef $$CategoryComboCategoriesTableTableCreateCompanionBuilder
    = CategoryComboCategoriesTableCompanion Function({
  required String categoryComboUid,
  required String categoryUid,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$CategoryComboCategoriesTableTableUpdateCompanionBuilder
    = CategoryComboCategoriesTableCompanion Function({
  Value<String> categoryComboUid,
  Value<String> categoryUid,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$CategoryComboCategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryComboCategoriesTableTable> {
  $$CategoryComboCategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryUid => $composableBuilder(
      column: $table.categoryUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$CategoryComboCategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryComboCategoriesTableTable> {
  $$CategoryComboCategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryUid => $composableBuilder(
      column: $table.categoryUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$CategoryComboCategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryComboCategoriesTableTable> {
  $$CategoryComboCategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get categoryComboUid => $composableBuilder(
      column: $table.categoryComboUid, builder: (column) => column);

  GeneratedColumn<String> get categoryUid => $composableBuilder(
      column: $table.categoryUid, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CategoryComboCategoriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoryComboCategoriesTableTable,
    CategoryComboCategory,
    $$CategoryComboCategoriesTableTableFilterComposer,
    $$CategoryComboCategoriesTableTableOrderingComposer,
    $$CategoryComboCategoriesTableTableAnnotationComposer,
    $$CategoryComboCategoriesTableTableCreateCompanionBuilder,
    $$CategoryComboCategoriesTableTableUpdateCompanionBuilder,
    (
      CategoryComboCategory,
      BaseReferences<_$AppDatabase, $CategoryComboCategoriesTableTable,
          CategoryComboCategory>
    ),
    CategoryComboCategory,
    PrefetchHooks Function()> {
  $$CategoryComboCategoriesTableTableTableManager(
      _$AppDatabase db, $CategoryComboCategoriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryComboCategoriesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryComboCategoriesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryComboCategoriesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> categoryComboUid = const Value.absent(),
            Value<String> categoryUid = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryComboCategoriesTableCompanion(
            categoryComboUid: categoryComboUid,
            categoryUid: categoryUid,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String categoryComboUid,
            required String categoryUid,
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryComboCategoriesTableCompanion.insert(
            categoryComboUid: categoryComboUid,
            categoryUid: categoryUid,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoryComboCategoriesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CategoryComboCategoriesTableTable,
        CategoryComboCategory,
        $$CategoryComboCategoriesTableTableFilterComposer,
        $$CategoryComboCategoriesTableTableOrderingComposer,
        $$CategoryComboCategoriesTableTableAnnotationComposer,
        $$CategoryComboCategoriesTableTableCreateCompanionBuilder,
        $$CategoryComboCategoriesTableTableUpdateCompanionBuilder,
        (
          CategoryComboCategory,
          BaseReferences<_$AppDatabase, $CategoryComboCategoriesTableTable,
              CategoryComboCategory>
        ),
        CategoryComboCategory,
        PrefetchHooks Function()>;
typedef $$CategoryOptionComboOptionsTableTableCreateCompanionBuilder
    = CategoryOptionComboOptionsTableCompanion Function({
  required String categoryOptionComboUid,
  required String categoryOptionUid,
  Value<int> rowid,
});
typedef $$CategoryOptionComboOptionsTableTableUpdateCompanionBuilder
    = CategoryOptionComboOptionsTableCompanion Function({
  Value<String> categoryOptionComboUid,
  Value<String> categoryOptionUid,
  Value<int> rowid,
});

class $$CategoryOptionComboOptionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryOptionComboOptionsTableTable> {
  $$CategoryOptionComboOptionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get categoryOptionComboUid => $composableBuilder(
      column: $table.categoryOptionComboUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryOptionUid => $composableBuilder(
      column: $table.categoryOptionUid,
      builder: (column) => ColumnFilters(column));
}

class $$CategoryOptionComboOptionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryOptionComboOptionsTableTable> {
  $$CategoryOptionComboOptionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get categoryOptionComboUid => $composableBuilder(
      column: $table.categoryOptionComboUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryOptionUid => $composableBuilder(
      column: $table.categoryOptionUid,
      builder: (column) => ColumnOrderings(column));
}

class $$CategoryOptionComboOptionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryOptionComboOptionsTableTable> {
  $$CategoryOptionComboOptionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get categoryOptionComboUid => $composableBuilder(
      column: $table.categoryOptionComboUid, builder: (column) => column);

  GeneratedColumn<String> get categoryOptionUid => $composableBuilder(
      column: $table.categoryOptionUid, builder: (column) => column);
}

class $$CategoryOptionComboOptionsTableTableTableManager
    extends RootTableManager<
        _$AppDatabase,
        $CategoryOptionComboOptionsTableTable,
        CategoryOptionComboOption,
        $$CategoryOptionComboOptionsTableTableFilterComposer,
        $$CategoryOptionComboOptionsTableTableOrderingComposer,
        $$CategoryOptionComboOptionsTableTableAnnotationComposer,
        $$CategoryOptionComboOptionsTableTableCreateCompanionBuilder,
        $$CategoryOptionComboOptionsTableTableUpdateCompanionBuilder,
        (
          CategoryOptionComboOption,
          BaseReferences<_$AppDatabase, $CategoryOptionComboOptionsTableTable,
              CategoryOptionComboOption>
        ),
        CategoryOptionComboOption,
        PrefetchHooks Function()> {
  $$CategoryOptionComboOptionsTableTableTableManager(
      _$AppDatabase db, $CategoryOptionComboOptionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryOptionComboOptionsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryOptionComboOptionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryOptionComboOptionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> categoryOptionComboUid = const Value.absent(),
            Value<String> categoryOptionUid = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryOptionComboOptionsTableCompanion(
            categoryOptionComboUid: categoryOptionComboUid,
            categoryOptionUid: categoryOptionUid,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String categoryOptionComboUid,
            required String categoryOptionUid,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryOptionComboOptionsTableCompanion.insert(
            categoryOptionComboUid: categoryOptionComboUid,
            categoryOptionUid: categoryOptionUid,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoryOptionComboOptionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CategoryOptionComboOptionsTableTable,
        CategoryOptionComboOption,
        $$CategoryOptionComboOptionsTableTableFilterComposer,
        $$CategoryOptionComboOptionsTableTableOrderingComposer,
        $$CategoryOptionComboOptionsTableTableAnnotationComposer,
        $$CategoryOptionComboOptionsTableTableCreateCompanionBuilder,
        $$CategoryOptionComboOptionsTableTableUpdateCompanionBuilder,
        (
          CategoryOptionComboOption,
          BaseReferences<_$AppDatabase, $CategoryOptionComboOptionsTableTable,
              CategoryOptionComboOption>
        ),
        CategoryOptionComboOption,
        PrefetchHooks Function()>;
typedef $$UsersTableTableCreateCompanionBuilder = UsersTableCompanion Function({
  required String uid,
  required String username,
  required String displayName,
  Value<int> rowid,
});
typedef $$UsersTableTableUpdateCompanionBuilder = UsersTableCompanion Function({
  Value<String> uid,
  Value<String> username,
  Value<String> displayName,
  Value<int> rowid,
});

class $$UsersTableTableFilterComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));
}

class $$UsersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTableTable> {
  $$UsersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);
}

class $$UsersTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTableTable,
    User,
    $$UsersTableTableFilterComposer,
    $$UsersTableTableOrderingComposer,
    $$UsersTableTableAnnotationComposer,
    $$UsersTableTableCreateCompanionBuilder,
    $$UsersTableTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTableTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableTableManager(_$AppDatabase db, $UsersTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersTableCompanion(
            uid: uid,
            username: username,
            displayName: displayName,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String username,
            required String displayName,
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersTableCompanion.insert(
            uid: uid,
            username: username,
            displayName: displayName,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTableTable,
    User,
    $$UsersTableTableFilterComposer,
    $$UsersTableTableOrderingComposer,
    $$UsersTableTableAnnotationComposer,
    $$UsersTableTableCreateCompanionBuilder,
    $$UsersTableTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTableTable, User>),
    User,
    PrefetchHooks Function()>;
typedef $$AttributesTableTableCreateCompanionBuilder = AttributesTableCompanion
    Function({
  required String uid,
  required String name,
  required String displayName,
  required String valueType,
  Value<int> rowid,
});
typedef $$AttributesTableTableUpdateCompanionBuilder = AttributesTableCompanion
    Function({
  Value<String> uid,
  Value<String> name,
  Value<String> displayName,
  Value<String> valueType,
  Value<int> rowid,
});

class $$AttributesTableTableFilterComposer
    extends Composer<_$AppDatabase, $AttributesTableTable> {
  $$AttributesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get valueType => $composableBuilder(
      column: $table.valueType, builder: (column) => ColumnFilters(column));
}

class $$AttributesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AttributesTableTable> {
  $$AttributesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
      column: $table.uid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get valueType => $composableBuilder(
      column: $table.valueType, builder: (column) => ColumnOrderings(column));
}

class $$AttributesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttributesTableTable> {
  $$AttributesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get valueType =>
      $composableBuilder(column: $table.valueType, builder: (column) => column);
}

class $$AttributesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttributesTableTable,
    AttributeDef,
    $$AttributesTableTableFilterComposer,
    $$AttributesTableTableOrderingComposer,
    $$AttributesTableTableAnnotationComposer,
    $$AttributesTableTableCreateCompanionBuilder,
    $$AttributesTableTableUpdateCompanionBuilder,
    (
      AttributeDef,
      BaseReferences<_$AppDatabase, $AttributesTableTable, AttributeDef>
    ),
    AttributeDef,
    PrefetchHooks Function()> {
  $$AttributesTableTableTableManager(
      _$AppDatabase db, $AttributesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttributesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttributesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttributesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> valueType = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttributesTableCompanion(
            uid: uid,
            name: name,
            displayName: displayName,
            valueType: valueType,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uid,
            required String name,
            required String displayName,
            required String valueType,
            Value<int> rowid = const Value.absent(),
          }) =>
              AttributesTableCompanion.insert(
            uid: uid,
            name: name,
            displayName: displayName,
            valueType: valueType,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttributesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttributesTableTable,
    AttributeDef,
    $$AttributesTableTableFilterComposer,
    $$AttributesTableTableOrderingComposer,
    $$AttributesTableTableAnnotationComposer,
    $$AttributesTableTableCreateCompanionBuilder,
    $$AttributesTableTableUpdateCompanionBuilder,
    (
      AttributeDef,
      BaseReferences<_$AppDatabase, $AttributesTableTable, AttributeDef>
    ),
    AttributeDef,
    PrefetchHooks Function()>;
typedef $$AttributeValuesTableTableCreateCompanionBuilder
    = AttributeValuesTableCompanion Function({
  required String objectType,
  required String objectUid,
  required String attributeUid,
  required String value,
  Value<int> rowid,
});
typedef $$AttributeValuesTableTableUpdateCompanionBuilder
    = AttributeValuesTableCompanion Function({
  Value<String> objectType,
  Value<String> objectUid,
  Value<String> attributeUid,
  Value<String> value,
  Value<int> rowid,
});

class $$AttributeValuesTableTableFilterComposer
    extends Composer<_$AppDatabase, $AttributeValuesTableTable> {
  $$AttributeValuesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get objectType => $composableBuilder(
      column: $table.objectType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get objectUid => $composableBuilder(
      column: $table.objectUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attributeUid => $composableBuilder(
      column: $table.attributeUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AttributeValuesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AttributeValuesTableTable> {
  $$AttributeValuesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get objectType => $composableBuilder(
      column: $table.objectType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get objectUid => $composableBuilder(
      column: $table.objectUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attributeUid => $composableBuilder(
      column: $table.attributeUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AttributeValuesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttributeValuesTableTable> {
  $$AttributeValuesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get objectType => $composableBuilder(
      column: $table.objectType, builder: (column) => column);

  GeneratedColumn<String> get objectUid =>
      $composableBuilder(column: $table.objectUid, builder: (column) => column);

  GeneratedColumn<String> get attributeUid => $composableBuilder(
      column: $table.attributeUid, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AttributeValuesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttributeValuesTableTable,
    AttributeValue,
    $$AttributeValuesTableTableFilterComposer,
    $$AttributeValuesTableTableOrderingComposer,
    $$AttributeValuesTableTableAnnotationComposer,
    $$AttributeValuesTableTableCreateCompanionBuilder,
    $$AttributeValuesTableTableUpdateCompanionBuilder,
    (
      AttributeValue,
      BaseReferences<_$AppDatabase, $AttributeValuesTableTable, AttributeValue>
    ),
    AttributeValue,
    PrefetchHooks Function()> {
  $$AttributeValuesTableTableTableManager(
      _$AppDatabase db, $AttributeValuesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttributeValuesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttributeValuesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttributeValuesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> objectType = const Value.absent(),
            Value<String> objectUid = const Value.absent(),
            Value<String> attributeUid = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttributeValuesTableCompanion(
            objectType: objectType,
            objectUid: objectUid,
            attributeUid: attributeUid,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String objectType,
            required String objectUid,
            required String attributeUid,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AttributeValuesTableCompanion.insert(
            objectType: objectType,
            objectUid: objectUid,
            attributeUid: attributeUid,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttributeValuesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $AttributeValuesTableTable,
        AttributeValue,
        $$AttributeValuesTableTableFilterComposer,
        $$AttributeValuesTableTableOrderingComposer,
        $$AttributeValuesTableTableAnnotationComposer,
        $$AttributeValuesTableTableCreateCompanionBuilder,
        $$AttributeValuesTableTableUpdateCompanionBuilder,
        (
          AttributeValue,
          BaseReferences<_$AppDatabase, $AttributeValuesTableTable,
              AttributeValue>
        ),
        AttributeValue,
        PrefetchHooks Function()>;
typedef $$SyncInfoTableTableCreateCompanionBuilder = SyncInfoTableCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncInfoTableTableUpdateCompanionBuilder = SyncInfoTableCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncInfoTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncInfoTableTable> {
  $$SyncInfoTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SyncInfoTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncInfoTableTable> {
  $$SyncInfoTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SyncInfoTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncInfoTableTable> {
  $$SyncInfoTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncInfoTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncInfoTableTable,
    SyncInfoEntry,
    $$SyncInfoTableTableFilterComposer,
    $$SyncInfoTableTableOrderingComposer,
    $$SyncInfoTableTableAnnotationComposer,
    $$SyncInfoTableTableCreateCompanionBuilder,
    $$SyncInfoTableTableUpdateCompanionBuilder,
    (
      SyncInfoEntry,
      BaseReferences<_$AppDatabase, $SyncInfoTableTable, SyncInfoEntry>
    ),
    SyncInfoEntry,
    PrefetchHooks Function()> {
  $$SyncInfoTableTableTableManager(_$AppDatabase db, $SyncInfoTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncInfoTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncInfoTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncInfoTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncInfoTableCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncInfoTableCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncInfoTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncInfoTableTable,
    SyncInfoEntry,
    $$SyncInfoTableTableFilterComposer,
    $$SyncInfoTableTableOrderingComposer,
    $$SyncInfoTableTableAnnotationComposer,
    $$SyncInfoTableTableCreateCompanionBuilder,
    $$SyncInfoTableTableUpdateCompanionBuilder,
    (
      SyncInfoEntry,
      BaseReferences<_$AppDatabase, $SyncInfoTableTable, SyncInfoEntry>
    ),
    SyncInfoEntry,
    PrefetchHooks Function()>;
typedef $$DataValuesTableTableCreateCompanionBuilder = DataValuesTableCompanion
    Function({
  required String dataElementUid,
  required String period,
  required String orgUnitUid,
  required String categoryOptionComboUid,
  required String attributeOptionComboUid,
  Value<String?> storedBy,
  Value<String?> value,
  Value<String?> comment,
  required SyncState syncState,
  Value<String?> syncError,
  required DateTime lastModified,
  Value<int> rowid,
});
typedef $$DataValuesTableTableUpdateCompanionBuilder = DataValuesTableCompanion
    Function({
  Value<String> dataElementUid,
  Value<String> period,
  Value<String> orgUnitUid,
  Value<String> categoryOptionComboUid,
  Value<String> attributeOptionComboUid,
  Value<String?> storedBy,
  Value<String?> value,
  Value<String?> comment,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

class $$DataValuesTableTableFilterComposer
    extends Composer<_$AppDatabase, $DataValuesTableTable> {
  $$DataValuesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orgUnitUid => $composableBuilder(
      column: $table.orgUnitUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryOptionComboUid => $composableBuilder(
      column: $table.categoryOptionComboUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attributeOptionComboUid => $composableBuilder(
      column: $table.attributeOptionComboUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storedBy => $composableBuilder(
      column: $table.storedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get comment => $composableBuilder(
      column: $table.comment, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SyncState, SyncState, int> get syncState =>
      $composableBuilder(
          column: $table.syncState,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));
}

class $$DataValuesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DataValuesTableTable> {
  $$DataValuesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orgUnitUid => $composableBuilder(
      column: $table.orgUnitUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryOptionComboUid => $composableBuilder(
      column: $table.categoryOptionComboUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attributeOptionComboUid => $composableBuilder(
      column: $table.attributeOptionComboUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storedBy => $composableBuilder(
      column: $table.storedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get comment => $composableBuilder(
      column: $table.comment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));
}

class $$DataValuesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DataValuesTableTable> {
  $$DataValuesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dataElementUid => $composableBuilder(
      column: $table.dataElementUid, builder: (column) => column);

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<String> get orgUnitUid => $composableBuilder(
      column: $table.orgUnitUid, builder: (column) => column);

  GeneratedColumn<String> get categoryOptionComboUid => $composableBuilder(
      column: $table.categoryOptionComboUid, builder: (column) => column);

  GeneratedColumn<String> get attributeOptionComboUid => $composableBuilder(
      column: $table.attributeOptionComboUid, builder: (column) => column);

  GeneratedColumn<String> get storedBy =>
      $composableBuilder(column: $table.storedBy, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);
}

class $$DataValuesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DataValuesTableTable,
    DataValue,
    $$DataValuesTableTableFilterComposer,
    $$DataValuesTableTableOrderingComposer,
    $$DataValuesTableTableAnnotationComposer,
    $$DataValuesTableTableCreateCompanionBuilder,
    $$DataValuesTableTableUpdateCompanionBuilder,
    (
      DataValue,
      BaseReferences<_$AppDatabase, $DataValuesTableTable, DataValue>
    ),
    DataValue,
    PrefetchHooks Function()> {
  $$DataValuesTableTableTableManager(
      _$AppDatabase db, $DataValuesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DataValuesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DataValuesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DataValuesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> dataElementUid = const Value.absent(),
            Value<String> period = const Value.absent(),
            Value<String> orgUnitUid = const Value.absent(),
            Value<String> categoryOptionComboUid = const Value.absent(),
            Value<String> attributeOptionComboUid = const Value.absent(),
            Value<String?> storedBy = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<String?> comment = const Value.absent(),
            Value<SyncState> syncState = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DataValuesTableCompanion(
            dataElementUid: dataElementUid,
            period: period,
            orgUnitUid: orgUnitUid,
            categoryOptionComboUid: categoryOptionComboUid,
            attributeOptionComboUid: attributeOptionComboUid,
            storedBy: storedBy,
            value: value,
            comment: comment,
            syncState: syncState,
            syncError: syncError,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String dataElementUid,
            required String period,
            required String orgUnitUid,
            required String categoryOptionComboUid,
            required String attributeOptionComboUid,
            Value<String?> storedBy = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<String?> comment = const Value.absent(),
            required SyncState syncState,
            Value<String?> syncError = const Value.absent(),
            required DateTime lastModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              DataValuesTableCompanion.insert(
            dataElementUid: dataElementUid,
            period: period,
            orgUnitUid: orgUnitUid,
            categoryOptionComboUid: categoryOptionComboUid,
            attributeOptionComboUid: attributeOptionComboUid,
            storedBy: storedBy,
            value: value,
            comment: comment,
            syncState: syncState,
            syncError: syncError,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DataValuesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DataValuesTableTable,
    DataValue,
    $$DataValuesTableTableFilterComposer,
    $$DataValuesTableTableOrderingComposer,
    $$DataValuesTableTableAnnotationComposer,
    $$DataValuesTableTableCreateCompanionBuilder,
    $$DataValuesTableTableUpdateCompanionBuilder,
    (
      DataValue,
      BaseReferences<_$AppDatabase, $DataValuesTableTable, DataValue>
    ),
    DataValue,
    PrefetchHooks Function()>;
typedef $$CompleteDataSetRegistrationsTableTableCreateCompanionBuilder
    = CompleteDataSetRegistrationsTableCompanion Function({
  required String dataSetUid,
  required String period,
  required String orgUnitUid,
  required String attributeOptionComboUid,
  required bool completed,
  Value<String?> storedBy,
  required DateTime date,
  required SyncState syncState,
  Value<String?> syncError,
  required DateTime lastModified,
  Value<int> rowid,
});
typedef $$CompleteDataSetRegistrationsTableTableUpdateCompanionBuilder
    = CompleteDataSetRegistrationsTableCompanion Function({
  Value<String> dataSetUid,
  Value<String> period,
  Value<String> orgUnitUid,
  Value<String> attributeOptionComboUid,
  Value<bool> completed,
  Value<String?> storedBy,
  Value<DateTime> date,
  Value<SyncState> syncState,
  Value<String?> syncError,
  Value<DateTime> lastModified,
  Value<int> rowid,
});

class $$CompleteDataSetRegistrationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CompleteDataSetRegistrationsTableTable> {
  $$CompleteDataSetRegistrationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orgUnitUid => $composableBuilder(
      column: $table.orgUnitUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attributeOptionComboUid => $composableBuilder(
      column: $table.attributeOptionComboUid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storedBy => $composableBuilder(
      column: $table.storedBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SyncState, SyncState, int> get syncState =>
      $composableBuilder(
          column: $table.syncState,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));
}

class $$CompleteDataSetRegistrationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CompleteDataSetRegistrationsTableTable> {
  $$CompleteDataSetRegistrationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orgUnitUid => $composableBuilder(
      column: $table.orgUnitUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attributeOptionComboUid => $composableBuilder(
      column: $table.attributeOptionComboUid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storedBy => $composableBuilder(
      column: $table.storedBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncError => $composableBuilder(
      column: $table.syncError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));
}

class $$CompleteDataSetRegistrationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompleteDataSetRegistrationsTableTable> {
  $$CompleteDataSetRegistrationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dataSetUid => $composableBuilder(
      column: $table.dataSetUid, builder: (column) => column);

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<String> get orgUnitUid => $composableBuilder(
      column: $table.orgUnitUid, builder: (column) => column);

  GeneratedColumn<String> get attributeOptionComboUid => $composableBuilder(
      column: $table.attributeOptionComboUid, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<String> get storedBy =>
      $composableBuilder(column: $table.storedBy, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);
}

class $$CompleteDataSetRegistrationsTableTableTableManager
    extends RootTableManager<
        _$AppDatabase,
        $CompleteDataSetRegistrationsTableTable,
        CompleteDataSetRegistration,
        $$CompleteDataSetRegistrationsTableTableFilterComposer,
        $$CompleteDataSetRegistrationsTableTableOrderingComposer,
        $$CompleteDataSetRegistrationsTableTableAnnotationComposer,
        $$CompleteDataSetRegistrationsTableTableCreateCompanionBuilder,
        $$CompleteDataSetRegistrationsTableTableUpdateCompanionBuilder,
        (
          CompleteDataSetRegistration,
          BaseReferences<_$AppDatabase, $CompleteDataSetRegistrationsTableTable,
              CompleteDataSetRegistration>
        ),
        CompleteDataSetRegistration,
        PrefetchHooks Function()> {
  $$CompleteDataSetRegistrationsTableTableTableManager(
      _$AppDatabase db, $CompleteDataSetRegistrationsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompleteDataSetRegistrationsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CompleteDataSetRegistrationsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompleteDataSetRegistrationsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> dataSetUid = const Value.absent(),
            Value<String> period = const Value.absent(),
            Value<String> orgUnitUid = const Value.absent(),
            Value<String> attributeOptionComboUid = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<String?> storedBy = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<SyncState> syncState = const Value.absent(),
            Value<String?> syncError = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CompleteDataSetRegistrationsTableCompanion(
            dataSetUid: dataSetUid,
            period: period,
            orgUnitUid: orgUnitUid,
            attributeOptionComboUid: attributeOptionComboUid,
            completed: completed,
            storedBy: storedBy,
            date: date,
            syncState: syncState,
            syncError: syncError,
            lastModified: lastModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String dataSetUid,
            required String period,
            required String orgUnitUid,
            required String attributeOptionComboUid,
            required bool completed,
            Value<String?> storedBy = const Value.absent(),
            required DateTime date,
            required SyncState syncState,
            Value<String?> syncError = const Value.absent(),
            required DateTime lastModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              CompleteDataSetRegistrationsTableCompanion.insert(
            dataSetUid: dataSetUid,
            period: period,
            orgUnitUid: orgUnitUid,
            attributeOptionComboUid: attributeOptionComboUid,
            completed: completed,
            storedBy: storedBy,
            date: date,
            syncState: syncState,
            syncError: syncError,
            lastModified: lastModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CompleteDataSetRegistrationsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CompleteDataSetRegistrationsTableTable,
        CompleteDataSetRegistration,
        $$CompleteDataSetRegistrationsTableTableFilterComposer,
        $$CompleteDataSetRegistrationsTableTableOrderingComposer,
        $$CompleteDataSetRegistrationsTableTableAnnotationComposer,
        $$CompleteDataSetRegistrationsTableTableCreateCompanionBuilder,
        $$CompleteDataSetRegistrationsTableTableUpdateCompanionBuilder,
        (
          CompleteDataSetRegistration,
          BaseReferences<_$AppDatabase, $CompleteDataSetRegistrationsTableTable,
              CompleteDataSetRegistration>
        ),
        CompleteDataSetRegistration,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OrgUnitsTableTableTableManager get orgUnitsTable =>
      $$OrgUnitsTableTableTableManager(_db, _db.orgUnitsTable);
  $$DataSetsTableTableTableManager get dataSetsTable =>
      $$DataSetsTableTableTableManager(_db, _db.dataSetsTable);
  $$DataElementsTableTableTableManager get dataElementsTable =>
      $$DataElementsTableTableTableManager(_db, _db.dataElementsTable);
  $$SectionsTableTableTableManager get sectionsTable =>
      $$SectionsTableTableTableManager(_db, _db.sectionsTable);
  $$IndicatorsTableTableTableManager get indicatorsTable =>
      $$IndicatorsTableTableTableManager(_db, _db.indicatorsTable);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(_db, _db.categoriesTable);
  $$CategoryOptionsTableTableTableManager get categoryOptionsTable =>
      $$CategoryOptionsTableTableTableManager(_db, _db.categoryOptionsTable);
  $$CategoryCombosTableTableTableManager get categoryCombosTable =>
      $$CategoryCombosTableTableTableManager(_db, _db.categoryCombosTable);
  $$CategoryOptionCombosTableTableTableManager get categoryOptionCombosTable =>
      $$CategoryOptionCombosTableTableTableManager(
          _db, _db.categoryOptionCombosTable);
  $$OptionSetsTableTableTableManager get optionSetsTable =>
      $$OptionSetsTableTableTableManager(_db, _db.optionSetsTable);
  $$OptionsTableTableTableManager get optionsTable =>
      $$OptionsTableTableTableManager(_db, _db.optionsTable);
  $$DataElementGroupsTableTableTableManager get dataElementGroupsTable =>
      $$DataElementGroupsTableTableTableManager(
          _db, _db.dataElementGroupsTable);
  $$ValidationRulesTableTableTableManager get validationRulesTable =>
      $$ValidationRulesTableTableTableManager(_db, _db.validationRulesTable);
  $$DataSetElementsTableTableTableManager get dataSetElementsTable =>
      $$DataSetElementsTableTableTableManager(_db, _db.dataSetElementsTable);
  $$DataSetOrgUnitsTableTableTableManager get dataSetOrgUnitsTable =>
      $$DataSetOrgUnitsTableTableTableManager(_db, _db.dataSetOrgUnitsTable);
  $$SectionDataElementsTableTableTableManager get sectionDataElementsTable =>
      $$SectionDataElementsTableTableTableManager(
          _db, _db.sectionDataElementsTable);
  $$SectionIndicatorsTableTableTableManager get sectionIndicatorsTable =>
      $$SectionIndicatorsTableTableTableManager(
          _db, _db.sectionIndicatorsTable);
  $$SectionGreyFieldsTableTableTableManager get sectionGreyFieldsTable =>
      $$SectionGreyFieldsTableTableTableManager(
          _db, _db.sectionGreyFieldsTable);
  $$DataElementGroupMembersTableTableTableManager
      get dataElementGroupMembersTable =>
          $$DataElementGroupMembersTableTableTableManager(
              _db, _db.dataElementGroupMembersTable);
  $$CategoryCategoryOptionsTableTableTableManager
      get categoryCategoryOptionsTable =>
          $$CategoryCategoryOptionsTableTableTableManager(
              _db, _db.categoryCategoryOptionsTable);
  $$CategoryComboCategoriesTableTableTableManager
      get categoryComboCategoriesTable =>
          $$CategoryComboCategoriesTableTableTableManager(
              _db, _db.categoryComboCategoriesTable);
  $$CategoryOptionComboOptionsTableTableTableManager
      get categoryOptionComboOptionsTable =>
          $$CategoryOptionComboOptionsTableTableTableManager(
              _db, _db.categoryOptionComboOptionsTable);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db, _db.usersTable);
  $$AttributesTableTableTableManager get attributesTable =>
      $$AttributesTableTableTableManager(_db, _db.attributesTable);
  $$AttributeValuesTableTableTableManager get attributeValuesTable =>
      $$AttributeValuesTableTableTableManager(_db, _db.attributeValuesTable);
  $$SyncInfoTableTableTableManager get syncInfoTable =>
      $$SyncInfoTableTableTableManager(_db, _db.syncInfoTable);
  $$DataValuesTableTableTableManager get dataValuesTable =>
      $$DataValuesTableTableTableManager(_db, _db.dataValuesTable);
  $$CompleteDataSetRegistrationsTableTableTableManager
      get completeDataSetRegistrationsTable =>
          $$CompleteDataSetRegistrationsTableTableTableManager(
              _db, _db.completeDataSetRegistrationsTable);
}
