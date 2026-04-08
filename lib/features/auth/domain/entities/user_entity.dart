class UserEntity {
  final String id;
  final String username;
  final String firstName;
  final String surname;
  final String? email;
  final String? phoneNumber;
  final String? avatar;
  final List<String> authorities;
  final String? organisationUnit;

  const UserEntity({
    required this.id,
    required this.username,
    required this.firstName,
    required this.surname,
    this.email,
    this.phoneNumber,
    this.avatar,
    this.authorities = const [],
    this.organisationUnit,
  });

  String get fullName => '$firstName $surname'.trim();

  bool get isAdmin => authorities.contains('ALL');

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
