import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstNameCtrl = TextEditingController();
  final middleNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  DateTime? dob;
  String? gender;

  bool loading = false;
  Future<void> pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => dob = picked);
    }
  }

  // ------------------
  // Registration logic
  // ------------------
  Future<void> register() async {
    if (loading) return;

    final firstName = firstNameCtrl.text.trim();
    final middleName = middleNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passCtrl.text;

    // ------------------
    // Validation
    // ------------------
    if (!Validators.isNotEmpty(firstName) ||
        !Validators.isNotEmpty(lastName) ||
        !Validators.isNotEmpty(email)) {
      AppSnackBar.show(
        context,
        "Please fill all required fields",
        isError: true,
      );
      return;
    }

    if (!Validators.isValidEmail(email)) {
      AppSnackBar.show(
        context,
        "Please enter a valid email address",
        isError: true,
      );
      return;
    }

    if (password.length < 6) {
      AppSnackBar.show(
        context,
        "Password must be at least 6 characters",
        isError: true,
      );
      return;
    }
    if (password != confirmPassCtrl.text) {
      AppSnackBar.show(context, "Passwords do not match", isError: true);
      return;
    }

    if (dob == null) {
      AppSnackBar.show(context, "Please select date of birth", isError: true);
      return;
    }

    if (gender == null) {
      AppSnackBar.show(context, "Please select gender", isError: true);
      return;
    }

    setState(() => loading = true);

    UserCredential? cred;

    try {
      // ------------------
      // 1️⃣ Create Auth user
      // ------------------
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ------------------
      // 2️⃣ Create Firestore profile
      // ------------------
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            "firstName": firstName,
            "middleName": middleName,
            "lastName": lastName,
            "email": email,
            "role": "student",
            "dob": Timestamp.fromDate(dob!),
            "gender": gender,

            "active": true,
            "createdAt": Timestamp.now(),
          });

      if (!mounted) return;

      AppSnackBar.show(context, "Account created successfully!");

      // Small delay so user sees feedback
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final message = switch (e.code) {
        'email-already-in-use' =>
          "This email is already registered. Try logging in.",
        'invalid-email' => "Invalid email address",
        'weak-password' => "Password is too weak",
        _ => "Registration failed. Please try again.",
      };

      AppSnackBar.show(context, message, isError: true);
    } catch (e) {
      // ------------------
      // 🔥 ROLLBACK AUTH USER
      // ------------------
      try {
        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.currentUser!.delete();
        }
      } catch (_) {
        // Ignore rollback errors
      }

      if (!mounted) return;

      AppSnackBar.show(
        context,
        "Something went wrong. Please try again.",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    middleNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  // ------------------
  // Input decoration helper
  // ------------------
  InputDecoration inputDecor(String label, dynamic icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: HugeIcon(icon: icon, size: 18, color: Colors.grey),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/ArtGradeLogo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),

                Text(
                  "Create Account",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),

                Text(
                  "Join us and start your journey.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: firstNameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: inputDecor(
                    "First Name",
                    HugeIcons.strokeRoundedUser,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: middleNameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: inputDecor(
                    "Middle Name (optional)",
                    HugeIcons.strokeRoundedUser,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: lastNameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: inputDecor(
                    "Last Name",
                    HugeIcons.strokeRoundedUser,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: inputDecor(
                    "Gender",
                    HugeIcons.strokeRoundedUserCircle,
                  ),
                  items: const [
                    DropdownMenuItem(value: "male", child: Text("Male")),
                    DropdownMenuItem(value: "female", child: Text("Female")),
                    DropdownMenuItem(value: "other", child: Text("Other")),
                  ],
                  onChanged: (value) {
                    setState(() => gender = value);
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: inputDecor(
                    "Email",
                    HugeIcons.strokeRoundedMail01,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: passCtrl,
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.next,
                  decoration:
                      inputDecor(
                        "Password",
                        HugeIcons.strokeRoundedLockPassword,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: HugeIcon(
                            icon: _hidePassword
                                ? HugeIcons.strokeRoundedViewOff
                                : HugeIcons.strokeRoundedView,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _hidePassword = !_hidePassword);
                          },
                        ),
                      ),
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: _hideConfirmPassword,
                  textInputAction: TextInputAction.done,
                  decoration:
                      inputDecor(
                        "Re-enter Password",
                        HugeIcons.strokeRoundedLockPassword,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: HugeIcon(
                            icon: _hideConfirmPassword
                                ? HugeIcons.strokeRoundedViewOff
                                : HugeIcons.strokeRoundedView,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(
                              () =>
                                  _hideConfirmPassword = !_hideConfirmPassword,
                            );
                          },
                        ),
                      ),
                ),
                const SizedBox(height: 32),

                FilledButton(
                  onPressed: loading ? null : register,
                  child: loading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text("Create Account"),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Login"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
