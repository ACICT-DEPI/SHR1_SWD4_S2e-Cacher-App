class AuthState {}

class AuthStateLoading extends AuthState {}

class AuthStateSuccess extends AuthState {}

class AuthStateError extends AuthState {
  String error;
  AuthStateError(this.error);
}

class AuthStateLogout extends AuthState {}

class UploadImageSuccess extends AuthState {}

class UploadImageError extends AuthState {
  String error;
  UploadImageError(this.error);
}

class AuthStateLoggedOut extends AuthState {}
