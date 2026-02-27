part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

class RegisterSubmitted extends RegisterEvent {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String phone;
  final String postal;
  final DateTime? birthdate;
  final String? gender;
  final bool subscribeNewsletter;
  final bool acceptTerms;

  const RegisterSubmitted({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phone,
    required this.postal,
    required this.birthdate,
    required this.gender,
    required this.subscribeNewsletter,
    required this.acceptTerms,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        confirmPassword,
        phone,
        postal,
        birthdate,
        gender,
        subscribeNewsletter,
        acceptTerms,
      ];
}