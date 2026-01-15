import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // =======================================================
  // 🔐 GOOGLE SIGN-IN
  // =======================================================
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1️⃣ Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled
        return null;
      }

      // 2️⃣ Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3️⃣ Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4️⃣ Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // 5️⃣ Ensure Firestore user document exists
      await _ensureUserDocument(userCredential);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // =======================================================
  // 🧾 CREATE USER DOC (FIRST GOOGLE LOGIN ONLY)
  // =======================================================
  static Future<void> _ensureUserDocument(UserCredential credential) async {
    final user = credential.user;
    if (user == null) return;

    final docRef = _db.collection('users').doc(user.uid);
    final docSnap = await docRef.get();

    // ✅ If already exists, do nothing
    if (docSnap.exists) return;

    // 🔤 Safely split Google display name
    final displayName = user.displayName ?? '';
    final parts = displayName.trim().split(RegExp(r'\s+'));

    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    // 🆕 Create normalized user document
    await docRef.set({
      'uid': user.uid,
      'email': user.email ?? '',

      'firstName': firstName,
      'lastName': lastName,

      'photoUrl': user.photoURL,
      'provider': 'google',

      // 🔽 Profile data (to be filled later)
      'phone': null,
      'gender': null,
      'dob': null,
      'profileComplete': false,

      // 🔐 Access control
      'role': 'student',
      'active': true,

      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // =======================================================
  // 🔁 FORCE GOOGLE RE-AUTH (ANDROID SAFE)
  // =======================================================
  static Future<UserCredential?> forceGoogleReauth() async {
    // Clear cached account (safe)
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    // Disconnect MAY fail on Android — ignore safely
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      // Intentionally ignored
    }

    // Fresh sign-in
    return await signInWithGoogle();
  }

  // =======================================================
  // 🚪 LOGOUT
  // =======================================================
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
