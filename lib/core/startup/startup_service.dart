import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AppStartDestination { login, student, admin }

class StartupService {
  static Future<AppStartDestination> determineStart() async {
    // 1️⃣ Wait for Firebase Auth to settle
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return AppStartDestination.login;
    }

    // 2️⃣ Load user profile
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!snap.exists) {
      return AppStartDestination.login;
    }

    final data = snap.data();
    if (data == null) {
      return AppStartDestination.login;
    }

    final role = data['role'];
    if (role != 'admin' && role != 'student') {
      return AppStartDestination.login;
    }

    final active = data['active'] ?? true;

    // Optional safety: inactive user forced logout
    if (!active) {
      await FirebaseAuth.instance.signOut();
      return AppStartDestination.login;
    }

    // 3️⃣ Decide destination
    if (role == 'admin') {
      return AppStartDestination.admin;
    }

    return AppStartDestination.student;
  }
}
