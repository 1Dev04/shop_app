// lib/screen/signin_user.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/blocs/cat_auth/auth_bloc.dart';
import 'package:flutter_application_1/documents/privacy_policy.dart';
import 'package:flutter_application_1/documents/terms_of_use.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/provider/theme.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:flutter_application_1/screen/signup_user.dart';
import 'package:flutter_application_1/screen/auth_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: const _LoginView(),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _LoginView
// ════════════════════════════════════════════════════════════════════════════

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _visibleP = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => regisUser(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final textStyle = TextStyle(color: isDark ? Colors.white : Colors.black);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthSuccess) {
          showTopSnackBar(
            Overlay.of(ctx),
            CustomSnackBar.success(
              message: languageProvider.translate(
                en: 'Login successful!',
                th: 'เข้าสู่ระบบสำเร็จ!',
              ),
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!ctx.mounted) return;
            Navigator.pushReplacement(
              ctx,
              MaterialPageRoute(builder: (_) => authPage()),
            );
          });
        } else if (state is AuthFailure) {
          showTopSnackBar(
            Overlay.of(ctx),
            CustomSnackBar.error(message: state.message),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1500),
          );
        }
      },
      builder: (ctx, state) {
        final isLoading = state is AuthLoading;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          home: Scaffold(
            backgroundColor: isDark
                ? const Color.fromRGBO(0, 0, 0, 0.933)
                : const Color.fromRGBO(255, 255, 255, 0.933),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Back button ───────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.cancel_outlined),
                            iconSize: 30,
                          ),
                        ],
                      ),

                      // ── Header ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(15),
                        color: isDark
                            ? const Color.fromRGBO(255, 255, 255, 0.929)
                            : const Color.fromRGBO(0, 0, 0, 0.929),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: _navigateToRegister,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                minimumSize: const Size(180, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Create a new user account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Login by email and password'),
                            Icon(Icons.announcement_sharp),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Please Specify*',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 72, 169, 169)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // ── Email ─────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextFormField(
                          controller: _emailCtrl,
                          autofocus: true,
                          maxLength: 50,
                          decoration: const InputDecoration(labelText: 'Email'),
                          style: textStyle,
                          validator: (v) {
                            final regex1 = RegExp(
                                r'^(?=.*[a-zA-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*!])[A-Za-z\d@#$%^&*!\.]{8,20}$');
                            final regex2 = RegExp(r'^\S+$');
                            if (v == null || v.isEmpty) {
                              return 'Please input email.';
                            } else if (v.length < 15 || v.length > 50) {
                              return 'The email should be between 15-50 characters';
                            } else if (!regex1.hasMatch(v)) {
                              return 'Invalid email format: \nUser1@example.com, person1@example.co.th';
                            } else if (!regex2.hasMatch(v)) {
                              return 'The email format $v is invalid.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 15),

                      // ── Password ──────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextFormField(
                          controller: _passwordCtrl,
                          obscureText: !_visibleP,
                          maxLength: 20,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: GestureDetector(
                              onTap: () =>
                                  setState(() => _visibleP = !_visibleP),
                              child: Icon(_visibleP
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                            ),
                          ),
                          style: textStyle,
                          validator: (v) {
                            final regex1 = RegExp(
                                r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                            final regex2 = RegExp(r'^\S+$');
                            if (v == null || v.isEmpty) {
                              return 'Please input password.';
                            } else if (v.length < 5 || v.length > 20) {
                              return 'The password should be between 5-20 characters';
                            } else if (!regex1.hasMatch(v)) {
                              return 'Invalid password format: \nP@ssw0rd';
                            } else if (!regex2.hasMatch(v)) {
                              return 'The password format $v is invalid.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Terms & Privacy ───────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const TermsOfUsePage()),
                                );
                              },
                              child: const Text(
                                'Terms of Use',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                            const SizedBox(height: 5),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const PrivacyPolicyPage()),
                                );
                              },
                              child: const Text(
                                'Privacy Policy',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),

                      // ── Confirm Button ────────────────────────────────
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  ctx.read<AuthBloc>().add(
                                        AuthLoginRequested(
                                          email: _emailCtrl.text,
                                          password: _passwordCtrl.text,
                                        ),
                                      );
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Confirm'),
                      ),
                      const SizedBox(height: 10),

                      // ── Or continue with ──────────────────────────────
                      const Center(child: Text('Or continue with')),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    ctx.read<AuthBloc>().add(
                                          const AuthGoogleLoginRequested(),
                                        );
                                  },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  isLoading ? Colors.grey.shade300 : null,
                              child: const Icon(Icons.g_mobiledata),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            
                            onPressed: isLoading
                                ? null
                                : () async {
                                    try {
                                      await FirebaseAuth.instance
                                          .signInWithEmailAndPassword(
                                        email: 'guest678@gmail.com',
                                        password: 'guest678@',
                                      );
                                      if (!ctx.mounted) return;
                                      Navigator.pushReplacement(
                                        ctx,
                                        MaterialPageRoute(
                                            builder: (_) => authPage()),
                                      );
                                    } catch (e) {
                                      if (!ctx.mounted) return;
                                      showTopSnackBar(
                                        Overlay.of(ctx),
                                        CustomSnackBar.error(
                                            message: 'Guest login failed: $e'),
                                      );
                                    }
                                  },
                            icon: Icon(Icons.person_outline,
                                color: isDark ? Colors.white : Colors.black),
                            label: Text(
                              languageProvider.translate(
                                en: 'Continue as Guest',
                                th: 'เข้าใช้งานในฐานะผู้เยี่ยมชม',
                              ),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Forgot Password ───────────────────────────────
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 10),
                      //   child: const Row(
                      //     mainAxisAlignment: MainAxisAlignment.end,
                      //     children: [
                      //       Text(
                      //         'Forgot password',
                      //         style: TextStyle(
                      //             decoration: TextDecoration.underline,
                      //             fontWeight: FontWeight.bold),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      const SizedBox(height: 20),

                      // ── Create Account Section ────────────────────────
                      Container(
                        padding: const EdgeInsets.all(15),
                        color: isDark
                            ? const Color.fromRGBO(255, 255, 255, 0.929)
                            : const Color.fromRGBO(0, 0, 0, 0.929),
                        child: Center(
                          child: Text(
                            'Create a new user account',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: const Text(
                            'Create an account for convenient use and faster payment.'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _navigateToRegister,
                        child: const Text('Create'),
                      ),
                      const SizedBox(height: 20),

                      // ── Footer ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Divider(
                          color: isDark
                              ? const Color.fromRGBO(255, 255, 255, 0.929)
                              : const Color.fromRGBO(0, 0, 0, 0.929),
                          height: 2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('All rights reserved.'),
                            Icon(Icons.copyright_rounded),
                            Text('ABC_Shop (Thailand)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
