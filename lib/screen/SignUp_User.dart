// lib/screen/signup_user.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/blocs/cat_register/register_bloc.dart';

import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/provider/theme.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:flutter_application_1/screen/Auth_Page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class regisUser extends StatelessWidget {
  const regisUser({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterBloc(),
      child: const _RegisterView(),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _RegisterView
// ════════════════════════════════════════════════════════════════════════════

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();

  // ── UI state ──────────────────────────────────────────────────────────────
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _subscribeNewsletter = false;
  bool _acceptTerms = false;
  bool _visiblePass = false;
  bool _visibleConfirm = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit(BuildContext blocCtx) {
    if (!_formKey.currentState!.validate()) return;

    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    if (!_acceptTerms) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: languageProvider.translate(
            en: 'Please accept the member agreement.',
            th: 'กรุณายอมรับข้อตกลงสมาชิก',
          ),
        ),
        animationDuration: const Duration(milliseconds: 1000),
        reverseAnimationDuration: const Duration(milliseconds: 200),
        displayDuration: const Duration(milliseconds: 1000),
      );
      return;
    }

    blocCtx.read<RegisterBloc>().add(RegisterSubmitted(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          confirmPassword: _confirmPasswordCtrl.text,
          phone: _phoneCtrl.text,
          postal: _postalCtrl.text,
          birthdate: _selectedDate,
          gender: _selectedGender,
          subscribeNewsletter: _subscribeNewsletter,
          acceptTerms: _acceptTerms,
        ));
  }

  // ── SnackBar ──────────────────────────────────────────────────────────────
  void _showTopSnack(String message, {required bool isError}) {
    showTopSnackBar(
      Overlay.of(context),
      isError
          ? CustomSnackBar.error(message: message)
          : CustomSnackBar.success(message: message),
      animationDuration: const Duration(milliseconds: 1000),
      reverseAnimationDuration: const Duration(milliseconds: 200),
      displayDuration: const Duration(milliseconds: 1000),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final textStyle =
        TextStyle(color: isDark ? Colors.white : Colors.black);

    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (ctx, state) {
        if (state is RegisterSuccess) {
          _showTopSnack(
            languageProvider.translate(
              en: 'Membership registration successful!',
              th: 'สมัครสมาชิกสำเร็จ!',
            ),
            isError: false,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AuthPage()),
          );
        } else if (state is RegisterFailure) {
          final msg = state.message;
          final display = msg == 'password_mismatch'
              ? languageProvider.translate(
                  en: 'Passwords do not match.',
                  th: 'รหัสผ่านไม่ตรงกัน')
              : msg == 'email_already_registered'
                  ? languageProvider.translate(
                      en: 'This email is already registered.',
                      th: 'อีเมลนี้ถูกใช้งานแล้ว')
                  : msg.startsWith('firebase:')
                      ? msg.replaceFirst('firebase:', '')
                      : msg.replaceFirst('error:', 'Error: ');
          _showTopSnack(display, isError: true);
        }
      },
      builder: (ctx, state) {
        final isLoading = state is RegisterLoading;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          home: Scaffold(
            body: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),

                      // ── Back ────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            iconSize: 30,
                          ),
                        ],
                      ),

                      // ── Header ──────────────────────────────────────
                      Container(
                        width: double.infinity,
                        height: 80,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Create a new account',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {}),
                              child: const Icon(Icons.lock),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Text(
                                'You will receive a confirmation email to the email address you entered below. Please check your inbox.',
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 40),
                            const Text(
                              'Please specify*',
                              style: TextStyle(
                                  color:
                                      Color.fromARGB(255, 72, 169, 169)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Form ────────────────────────────────────────
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),

                              // Username
                              TextFormField(
                                controller: _nameCtrl,
                                autofocus: true,
                                maxLength: 30,
                                decoration: const InputDecoration(
                                    labelText: 'Username'),
                                style: textStyle,
                                validator: (v) {
                                  final r1 = RegExp(
                                      r'^(Mr|Ms)\. [A-Z][a-z]+(?: [A-Z][a-z]+)*(\.?)$');
                                  final r2 = RegExp(
                                      r'^(?!.*\s{2,})(?:\S+\s?){1,3}$');
                                  if (v == null || v.isEmpty) {
                                    return 'Please input username.';
                                  } else if (v.length < 10 ||
                                      v.length > 30) {
                                    return 'The username should be between 10-30 characters';
                                  } else if (!r1.hasMatch(v)) {
                                    return 'Invalid username format: \nMr. Jake Smith / Ms. Emma Olivia';
                                  } else if (!r2.hasMatch(v)) {
                                    return 'The username format $v is invalid.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),

                              // Email
                              TextFormField(
                                controller: _emailCtrl,
                                maxLength: 50,
                                decoration: const InputDecoration(
                                    labelText: 'Email'),
                                style: textStyle,
                                validator: (v) {
                                  final r1 = RegExp(
                                      r'^(?=.*[a-zA-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*!])[A-Za-z\d@#$%^&*!\.]{8,20}$');
                                  final r2 = RegExp(r'^\S+$');
                                  if (v == null || v.isEmpty) {
                                    return 'Please input email.';
                                  } else if (v.length < 15 ||
                                      v.length > 50) {
                                    return 'The email should be between 15-50 characters.';
                                  } else if (!r1.hasMatch(v)) {
                                    return 'Invalid email format: \nUser1@example.com';
                                  } else if (!r2.hasMatch(v)) {
                                    return 'The email format $v is invalid.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),

                              // Password
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: !_visiblePass,
                                maxLength: 20,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(
                                        () => _visiblePass = !_visiblePass),
                                    child: Icon(_visiblePass
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                  ),
                                ),
                                style: textStyle,
                                validator: (v) {
                                  final r1 = RegExp(
                                      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                                  final r2 = RegExp(r'^\S+$');
                                  if (v == null || v.isEmpty) {
                                    return 'Please input password.';
                                  } else if (v.length < 5 || v.length > 20) {
                                    return 'The password should be between 5-20 characters';
                                  } else if (!r1.hasMatch(v)) {
                                    return 'Invalid password format: \nP@ssw0rd';
                                  } else if (!r2.hasMatch(v)) {
                                    return 'The password format $v is invalid.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),

                              // Confirm Password
                              TextFormField(
                                controller: _confirmPasswordCtrl,
                                obscureText: !_visibleConfirm,
                                maxLength: 20,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() =>
                                        _visibleConfirm = !_visibleConfirm),
                                    child: Icon(_visibleConfirm
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                  ),
                                ),
                                style: textStyle,
                                validator: (v) {
                                  final r1 = RegExp(
                                      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                                  final r2 = RegExp(r'^\S+$');
                                  if (v == null || v.isEmpty) {
                                    return 'Please input confirm password.';
                                  } else if (v.length < 5 || v.length > 20) {
                                    return 'The confirm password should be between 5-20 characters';
                                  } else if (!r1.hasMatch(v)) {
                                    return 'Invalid confirm password format: \nP@ssw0rd';
                                  } else if (!r2.hasMatch(v)) {
                                    return 'The password format $v is invalid.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),

                              // Phone
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                decoration: const InputDecoration(
                                    labelText: 'Phone Number'),
                                style: textStyle,
                                validator: (v) {
                                  final r1 = RegExp(r'^[0-9]{10}$');
                                  final r2 = RegExp(
                                      r'^(?!.*(\d)\1{2})\d{10}$');
                                  if (v == null || v.isEmpty) {
                                    return 'Please input phone number';
                                  } else if (v.length != 10) {
                                    return 'Please enter a 10-digit phone number.';
                                  } else if (!r1.hasMatch(v)) {
                                    return 'Invalid phone number format: \n0123456789';
                                  } else if (!r2.hasMatch(v)) {
                                    return 'The number format $v is invalid.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),

                              // Postal Code
                              TextFormField(
                                controller: _postalCtrl,
                                keyboardType: TextInputType.number,
                                maxLength: 5,
                                decoration: const InputDecoration(
                                    labelText: 'Postal Code'),
                                style: textStyle,
                                validator: (v) {
                                  final r1 = RegExp(r'^[0-9]{5}$');
                                  if (v == null || v.isEmpty) {
                                    return 'Please input postal code';
                                  } else if (v.length != 5) {
                                    return 'Please enter a 5-digit postal code.';
                                  } else if (!r1.hasMatch(v)) {
                                    return 'Invalid postal code format: 01234';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),

                              // Birthdate
                              ListTile(
                                title: Text(
                                  _selectedDate == null
                                      ? 'Select Birthday'
                                      : 'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                ),
                                trailing:
                                    const Icon(Icons.calendar_today),
                                onTap: _selectDate,
                              ),
                              const SizedBox(height: 15),

                              // Gender
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Gender'),
                              ),
                              Row(
                                children: ['Men', 'Women', 'Not selected']
                                    .map((g) => Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<String>(
                                              value: g,
                                              groupValue: _selectedGender,
                                              onChanged: (v) => setState(
                                                  () => _selectedGender = v),
                                            ),
                                            Text(g),
                                          ],
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 15),

                              // Subscribe Newsletter
                              CheckboxListTile(
                                title: const Text(
                                    'Subscribe to the newsletter'),
                                value: _subscribeNewsletter,
                                onChanged: (v) => setState(
                                    () => _subscribeNewsletter = v!),
                              ),
                              const SizedBox(height: 15),

                              // Accept Terms
                              CheckboxListTile(
                                title: const Text(
                                    'Accept the member agreement'),
                                value: _acceptTerms,
                                onChanged: (v) =>
                                    setState(() => _acceptTerms = v!),
                              ),
                              const SizedBox(height: 20),

                              // Sign Up Button
                              ElevatedButton(
                                onPressed:
                                    isLoading ? null : () => _submit(ctx),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Text('Sign Up'),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // overlay ขณะ loading
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator.adaptive(
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color.fromARGB(75, 50, 50, 50)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}