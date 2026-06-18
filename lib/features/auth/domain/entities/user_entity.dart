class OrgUnitEntity {
  final String id;
  final String name;
  final String? shortName;
  final String? code;
  final int? level;
  final String? path;

  const OrgUnitEntity({
    required this.id,
    required this.name,
    this.shortName,
    this.code,
    this.level,
    this.path,
  });

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrgUnitEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class UserEntity {
  final String id;
  final String username;
  final String firstName;
  final String surname;
  final String? email;
  final String? phoneNumber;
  final String? avatar;
  final List<String> authorities;
  final List<OrgUnitEntity> organisationUnits;

  const UserEntity({
    required this.id,
    required this.username,
    required this.firstName,
    required this.surname,
    this.email,
    this.phoneNumber,
    this.avatar,
    this.authorities = const [],
    this.organisationUnits = const [],
  });

  String get fullName => '$firstName $surname'.trim();

  bool get isAdmin => authorities.contains('ALL');

  /// Returns first assigned org unit (most common case)
  OrgUnitEntity? get primaryOrgUnit =>
      organisationUnits.isNotEmpty ? organisationUnits.first : null;

  @override
  String toString() => 'UserEntity(id: $id, username: $username)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
