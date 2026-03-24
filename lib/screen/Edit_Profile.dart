// lib/screen/edit_profile_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:flutter_application_1/repositories/profile_repository.dart';
import 'package:flutter_application_1/screen/Auth_Page.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProfileRepository();

  // ── UI state ──────────────────────────────────────────────────────────────
  bool _visibleCurrent = false;
  bool _visibleNew = false;
  bool _visibleConfirm = false;
  bool _isLoading = false;
  bool _isSubmitting = false;

  // ── Controllers ───────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _newEmailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _conNewPasswordCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _birthdateCtrl = TextEditingController();

  // ── Form state ────────────────────────────────────────────────────────────
  String? _selectedGender;
  bool _subscribeNewsletter = false;
  bool _acceptTerms = false;
  DateTime? _selectedBirthdate;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _newEmailCtrl.dispose();
    _passwordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _conNewPasswordCtrl.dispose();
    _postalCtrl.dispose();
    _phoneCtrl.dispose();
    _birthdateCtrl.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _repo.loadProfile();
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = profile.name;
        _emailCtrl.text = profile.email;
        _phoneCtrl.text = profile.phone;
        _postalCtrl.text = profile.postal;
        _selectedGender = profile.gender;
        _subscribeNewsletter = profile.subscribeNewsletter;
        _acceptTerms = profile.acceptTerms;
        if (profile.birthdate != null) {
          _selectedBirthdate = profile.birthdate;
          _birthdateCtrl.text = profile.birthdate!.toIso8601String();
        }
      });
    } catch (e) {
      _showSnack('Failed to load profile: $e', _SnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showSnack('Please accept terms and conditions', _SnackType.info);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final resultKey = await _repo.updateProfile(UpdateProfileParams(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        postal: _postalCtrl.text,
        birthdate: _birthdateCtrl.text,
        gender: _selectedGender,
        subscribeNewsletter: _subscribeNewsletter,
        acceptTerms: _acceptTerms,
        newEmail: _newEmailCtrl.text.isNotEmpty ? _newEmailCtrl.text : null,
        currentPassword:
            _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
        newPassword:
            _newPasswordCtrl.text.isNotEmpty ? _newPasswordCtrl.text : null,
      ));

      if (!mounted) return;

      if (resultKey == 'verify_email_sent') {
        _showSnack(
            'Please check your new email to verify the change.',
            _SnackType.info);
      } else {
        _showSnack('Profile updated successfully 🎉', _SnackType.success);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthPage()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnack('Auth error: ${e.message}', _SnackType.error);
    } catch (e) {
      _showSnack('Error: $e', _SnackType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Select Birthdate ──────────────────────────────────────────────────────
  Future<void> _selectBirthdate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
        _birthdateCtrl.text = picked.toIso8601String();
      });
    }
  }

  // ── SnackBar helper ───────────────────────────────────────────────────────
  void _showSnack(String message, _SnackType type) {
    if (!mounted) return;
    final snackBar = switch (type) {
      _SnackType.success => CustomSnackBar.success(message: message),
      _SnackType.info => CustomSnackBar.info(message: message),
      _SnackType.error => CustomSnackBar.error(message: message),
    };
    showTopSnackBar(
      Overlay.of(context),
      snackBar,
      animationDuration: const Duration(milliseconds: 200),
      reverseAnimationDuration: const Duration(milliseconds: 200),
      displayDuration: const Duration(milliseconds: 1500),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final textStyle = TextStyle(color: isDark ? Colors.white : Colors.black);
    final dimStyle =
        TextStyle(color: isDark ? Colors.white70 : Colors.black54);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            iconSize: 30,
                          ),
                        ],
                      ),
                      const Center(
                        child: Text('Edit Profile',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      const SizedBox(height: 30),

                      // ── Username ────────────────────────────────────────
                      TextFormField(
                        controller: _nameCtrl,
                        maxLength: 30,
                        decoration:
                            const InputDecoration(labelText: 'Username'),
                        style: textStyle,
                        validator: (v) {
                          final regex = RegExp(
                              r'^(Mr|Ms)\. [A-Z][a-z]+(?: [A-Z][a-z]+)*(\.?)$');
                          if (v == null || v.isEmpty) {
                            return 'Please input username.';
                          } else if (v.length < 10 || v.length > 30) {
                            return 'The username should be between 10-30 characters';
                          } else if (!regex.hasMatch(v)) {
                            return 'Invalid username format: \nMr. Jake Smith / Ms. Emma Olivia';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // ── Current Email (read-only) ───────────────────────
                      TextFormField(
                        controller: _emailCtrl,
                        enabled: false,
                        maxLength: 50,
                        decoration: const InputDecoration(
                            labelText: 'Current Email'),
                        style: dimStyle,
                      ),
                      const SizedBox(height: 15),

                      // ── New Email ───────────────────────────────────────
                      TextFormField(
                        controller: _newEmailCtrl,
                        maxLength: 50,
                        decoration: const InputDecoration(
                            labelText: 'New Email (Optional)'),
                        style: textStyle,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // ── Phone ───────────────────────────────────────────
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                        style: textStyle,
                        validator: (v) {
                          final regex = RegExp(r'^0[0-9]{9}$');
                          if (v == null || v.isEmpty) {
                            return 'Please input phone number';
                          } else if (!regex.hasMatch(v)) {
                            return 'Invalid phone format: 0890489858';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // ── Birthdate ───────────────────────────────────────
                      TextFormField(
                        controller: _birthdateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Birthdate',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        style: textStyle,
                        onTap: _selectBirthdate,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please select birthdate';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // ── Postal Code ─────────────────────────────────────
                      TextFormField(
                        controller: _postalCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        decoration:
                            const InputDecoration(labelText: 'Postal Code'),
                        style: textStyle,
                        validator: (v) {
                          final regex = RegExp(r'^[0-9]{5}$');
                          if (v == null || v.isEmpty) {
                            return 'Please input postal code';
                          } else if (!regex.hasMatch(v)) {
                            return 'Invalid postal code format: 10270';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // ── Gender ──────────────────────────────────────────
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

                      // ── Current Password ────────────────────────────────
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: !_visibleCurrent,
                        maxLength: 20,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _visibleCurrent = !_visibleCurrent),
                            child: Icon(_visibleCurrent
                                ? Icons.visibility
                                : Icons.visibility_off),
                          ),
                        ),
                        style: textStyle,
                        validator: (v) {
                          if ((_newEmailCtrl.text.isNotEmpty ||
                                  _newPasswordCtrl.text.isNotEmpty) &&
                              (v == null || v.isEmpty)) {
                            return 'Please enter current password to make changes.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // ── New Password ────────────────────────────────────
                      TextFormField(
                        controller: _newPasswordCtrl,
                        obscureText: !_visibleNew,
                        maxLength: 20,
                        decoration: InputDecoration(
                          labelText: 'New Password (Optional)',
                          suffixIcon: GestureDetector(
                            onTap: () =>
                                setState(() => _visibleNew = !_visibleNew),
                            child: Icon(_visibleNew
                                ? Icons.visibility
                                : Icons.visibility_off),
                          ),
                        ),
                        style: textStyle,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final regex = RegExp(
                              r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                          if (!regex.hasMatch(v)) {
                            return 'Password must contain uppercase, lowercase, number, and special character';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // ── Confirm New Password ────────────────────────────
                      TextFormField(
                        controller: _conNewPasswordCtrl,
                        obscureText: !_visibleConfirm,
                        maxLength: 20,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _visibleConfirm = !_visibleConfirm),
                            child: Icon(_visibleConfirm
                                ? Icons.visibility
                                : Icons.visibility_off),
                          ),
                        ),
                        style: textStyle,
                        validator: (v) {
                          if (_newPasswordCtrl.text.isNotEmpty) {
                            if (v == null || v.isEmpty) {
                              return 'Please confirm your new password.';
                            }
                            if (v != _newPasswordCtrl.text) {
                              return 'Passwords do not match!';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // ── Subscribe Newsletter ────────────────────────────
                      CheckboxListTile(
                        title: const Text('Subscribe to the newsletter'),
                        value: _subscribeNewsletter,
                        onChanged: (v) =>
                            setState(() => _subscribeNewsletter = v!),
                      ),
                      const SizedBox(height: 15),

                      // ── Accept Terms ────────────────────────────────────
                      CheckboxListTile(
                        title: const Text('Accept terms and conditions'),
                        value: _acceptTerms,
                        onChanged: (v) =>
                            setState(() => _acceptTerms = v!),
                      ),
                      const SizedBox(height: 15),

                      // ── Confirm Button ──────────────────────────────────
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Text('Confirm',
                                style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

enum _SnackType { success, info, error }