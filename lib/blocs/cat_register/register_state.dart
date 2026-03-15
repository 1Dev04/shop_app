part of 'register_bloc.dart';

abstract class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object?> get props => [];
}

/// ยังไม่ได้ทำอะไร
class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

/// กำลังสมัคร
class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

/// สมัครสำเร็จ
class RegisterSuccess extends RegisterState {
  const RegisterSuccess();
}

/// สมัครล้มเหลว
class RegisterFailure extends RegisterState {
  final String message;
  const RegisterFailure(this.message);

  @override
  List<Object?> get props => [message];
}