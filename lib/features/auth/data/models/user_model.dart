import '../../domain/entities/user_entity.dart';

class OrgUnitModel extends OrgUnitEntity {
  const OrgUnitModel({
    required super.id,
    required super.name,
    super.shortName,
    super.code,
    super.level,
    super.path,
  });

  factory OrgUnitModel.fromJson(Map<String, dynamic> json) {
    return OrgUnitModel(
      id: json['id'] as String? ?? '',
      name: json['displayName'] as String? ??
          json['name'] as String? ?? '',
      shortName: json['shortName'] as String?,
      code: json['code'] as String?,
      level: json['level'] as int?,
      path: json['path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'code': code,
        'level': level,
        'path': path,
      };
}

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.firstName,
    required super.surname,
    super.email,
    super.phoneNumber,
    super.avatar,
    super.authorities,
    super.organisationUnits,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse organisation units list
    final orgUnits = (json['organisationUnits'] as List<dynamic>?)
            ?.map((e) =>
                OrgUnitModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      avatar: json['avatar']?['id'] as String?,
      authorities: (json['authorities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      organisationUnits: orgUnits,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'firstName': firstName,
        'surname': surname,
        'email': email,
        'phoneNumber': phoneNumber,
        'organisationUnits': organisationUnits
            .map((o) => (o as OrgUnitModel).toJson())
            .toList(),
      };
}
