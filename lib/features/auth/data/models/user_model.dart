import '../../domain/entities/user_entity.dart';

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
    super.organisationUnit,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
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
      organisationUnit:
          (json['organisationUnits'] as List<dynamic>?)?.isNotEmpty == true
              ? (json['organisationUnits'][0]['id'] as String?)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'surname': surname,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatar': avatar != null ? {'id': avatar} : null,
      'authorities': authorities,
    };
  }
}
