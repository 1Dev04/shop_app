part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// ยังไม่ได้ทำอะไร
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// กำลัง login
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Login สำเร็จ
class AuthSuccess extends AuthState {
  const AuthSuccess();
}

/// Login ล้มเหลว
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}