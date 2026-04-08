part of 'auth_bloc.dart';

abstract class AuthState {
  const AuthState();
}

/// Initial state — checking auth status
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Checking if user is already logged in
class AuthCheckInProgress extends AuthState {
  const AuthCheckInProgress();
}

/// Login request in progress
class AuthLoginInProgress extends AuthState {
  const AuthLoginInProgress();
}

/// User successfully authenticated
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Login failed
class AuthFailureState extends AuthState {
  final String message;
  const AuthFailureState(this.message);
}

/// Logout completed
class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}
