
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Data class สำหรับโปรไฟล์ที่โหลดมา ────────────────────────────────────
class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String postal;
  final String gender;
  final bool subscribeNewsletter;
  final bool acceptTerms;
  final DateTime? birthdate;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.postal,
    required this.gender,
    required this.subscribeNewsletter,
    required this.acceptTerms,
    this.birthdate,
  });
}

// ── Params สำหรับ update ──────────────────────────────────────────────────
class UpdateProfileParams {
  final String name;
  final String email;
  final String phone;
  final String postal;
  final String birthdate;
  final String? gender;
  final bool subscribeNewsletter;
  final bool acceptTerms;
  final String? newEmail;
  final String? currentPassword;
  final String? newPassword;

  const UpdateProfileParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.postal,
    required this.birthdate,
    required this.gender,
    required this.subscribeNewsletter,
    required this.acceptTerms,
    this.newEmail,
    this.currentPassword,
    this.newPassword,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// ProfileRepository
// ════════════════════════════════════════════════════════════════════════════

class ProfileRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProfileRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Load ─────────────────────────────────────────────────────────────────
  Future<UserProfile> loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final doc =
        await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) throw Exception('User data not found');

    DateTime? birthdate;
    final raw = doc['birthdate'];
    if (raw is Timestamp) {
      birthdate = raw.toDate();
    } else if (raw is String && raw.isNotEmpty) {
      birthdate = DateTime.tryParse(raw);
    }

    return UserProfile(
      name: doc['name'] ?? '',
      email: user.email ?? '',
      phone: doc['phone'] ?? '',
      postal: doc['postal'] ?? '',
      gender: doc['gender'] ?? '',
      subscribeNewsletter: doc['subscribeNewsletter'] ?? false,
      acceptTerms: doc['acceptTerms'] ?? false,
      birthdate: birthdate,
    );
  }

  // ── Update ────────────────────────────────────────────────────────────────
  /// Returns a message key:
  ///   'updated'            — success, ไม่มีการเปลี่ยนอีเมล
  ///   'verify_email_sent'  — success, ส่ง verify email ไปแล้ว
  Future<String> updateProfile(UpdateProfileParams p) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final oldDoc =
        await _firestore.collection('users').doc(user.uid).get();
    if (!oldDoc.exists) throw Exception('User data not found in Firestore');

    String resultKey = 'updated';

    // 1. เปลี่ยนอีเมล
    if (p.newEmail != null &&
        p.newEmail!.isNotEmpty &&
        p.newEmail != user.email) {
      await _reauthenticate(user.email!, p.currentPassword!);
      await user.verifyBeforeUpdateEmail(p.newEmail!);
      resultKey = 'verify_email_sent';
    }

    // 2. เปลี่ยนรหัสผ่าน
    if (p.newPassword != null && p.newPassword!.isNotEmpty) {
      await _reauthenticate(user.email!, p.currentPassword!);
      await user.updatePassword(p.newPassword!);
    }

    // 3. อัปเดต Firestore
    await _firestore.collection('users').doc(user.uid).set({
      'acceptTerms': p.acceptTerms,
      'birthdate': p.birthdate,
      'confirmPassword': p.newPassword ?? oldDoc['confirmPassword'] ?? '',
      'createdAt': oldDoc['createdAt'] ?? FieldValue.serverTimestamp(),
      'email': p.newEmail?.isNotEmpty == true ? p.newEmail : p.email,
      'gender': p.gender ?? '',
      'name': p.name.trim(),
      'password': p.newPassword ?? oldDoc['password'] ?? '',
      'phone': p.phone.trim(),
      'postal': p.postal.trim(),
      'subscribeNewsletter': p.subscribeNewsletter,
      'uid': user.uid,
    });

    return resultKey;
  }

  // ── Private: Reauthenticate ───────────────────────────────────────────────
  Future<void> _reauthenticate(String email, String password) async {
    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    await _auth.currentUser!.reauthenticateWithCredential(credential);
  }
}