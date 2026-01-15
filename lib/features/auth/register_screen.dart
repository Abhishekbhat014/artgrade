import 'dart:io';

import 'package:artgrade/core/services/cloudinary_service.dart';
import 'package:artgrade/core/services/google_auth_service.dart';
import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController(); // ✅ 1. Added Phone Controller
  final passCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  File? profileImage;

  bool _hidePassword = true;

  DateTime? dob;
  String? gender;

  bool loading = false;

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose(); // ✅ Dispose Phone Controller
    passCtrl.dispose();
    dobCtrl.dispose();
    super.dispose();
  }

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        profileImage = File(picked.path);
      });
    }
  }

  Future<void> pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        dob = picked;
        dobCtrl.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> signUpWithGoogle() async {
    if (loading) return;

    try {
      setState(() => loading = true);
      await AuthService.signInWithGoogle();
      // ✅ AuthGate will route accordingly
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, "Google sign-in failed.", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> register() async {
    if (loading) return;

    final firstName = firstNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    // ✅ Sanitize phone (remove spaces/dashes)
    final phone = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final password = passCtrl.text;

    if (!Validators.isNotEmpty(firstName) ||
        !Validators.isNotEmpty(lastName) ||
        !Validators.isNotEmpty(email)) {
      AppSnackBar.show(context, "Please fill all fields", isError: true);
      return;
    }

    if (!Validators.isValidEmail(email)) {
      AppSnackBar.show(context, "Invalid email address", isError: true);
      return;
    }

    // ✅ 2. Validate Phone Number
    if (phone.isEmpty || phone.length < 10) {
      AppSnackBar.show(
        context,
        "Please enter a valid phone number",
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

    if (gender == null) {
      AppSnackBar.show(context, "Please select gender", isError: true);
      return;
    }

    if (dob == null) {
      AppSnackBar.show(context, "Please select date of birth", isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      // 1️⃣ Create Firebase Auth user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2️⃣ Upload profile image to Cloudinary (optional)
      String? photoUrl;
      if (profileImage != null) {
        photoUrl = await CloudinaryService.uploadProfileImage(profileImage!);
      }

      // 3️⃣ Save user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'uid': cred.user!.uid,
            'email': email,
            'phone': phone, // ✅ Save Phone Number

            'firstName': firstName,
            'lastName': lastName,

            'gender': gender,
            'dob': Timestamp.fromDate(dob!),

            'provider': 'password',
            'photoUrl': photoUrl,
            'profileComplete': true,

            'role': 'student',
            'active': true,

            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      AppSnackBar.show(context, "Account created successfully!");

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final message = switch (e.code) {
        'email-already-in-use' => "This email is already registered.",
        'weak-password' => "Password is too weak.",
        _ => "Registration failed. Please try again.",
      };

      AppSnackBar.show(context, message, isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration _inputDecor(
    String label,
    String asset,
    ColorScheme colorScheme,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: AppSvgIcon(
          asset: asset,
          size: 22,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: AppSvgIcon(
              asset: AppIcons.arrow_left,
              color: cs.onSurface,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LOGO
                  Image.asset(
                    'assets/images/ArtGradeLogo.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),

                  // HEADERS
                  Text(
                    "Create Account",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Join us and start your journey.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // PROFILE IMAGE PICKER
                  Center(
                    child: GestureDetector(
                      onTap: pickProfileImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: cs.surfaceContainerHigh,
                            backgroundImage: profileImage != null
                                ? FileImage(profileImage!)
                                : null,
                            child: profileImage == null
                                ? AppSvgIcon(
                                    asset: AppIcons.user,
                                    size: 40,
                                    color: cs.onSurfaceVariant,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                            child: AppSvgIcon(
                              asset: AppIcons.camera_add,
                              size: 18,
                              color: cs.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // FIRST NAME
                  TextField(
                    controller: firstNameCtrl,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _inputDecor("First Name", AppIcons.user, cs),
                  ),
                  const SizedBox(height: 16),

                  // LAST NAME
                  TextField(
                    controller: lastNameCtrl,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _inputDecor("Last Name", AppIcons.user, cs),
                  ),
                  const SizedBox(height: 16),

                  // GENDER
                  DropdownButtonFormField<String>(
                    value: gender,
                    dropdownColor: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                    ),
                    decoration: _inputDecor("Gender", AppIcons.gender, cs),
                    items: const [
                      DropdownMenuItem(value: "male", child: Text("Male")),
                      DropdownMenuItem(value: "female", child: Text("Female")),
                      DropdownMenuItem(value: "other", child: Text("Other")),
                    ],
                    onChanged: (value) => setState(() => gender = value),
                    icon: AppSvgIcon(
                      asset: AppIcons.arrow_down,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DOB
                  GestureDetector(
                    onTap: pickDob,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: dobCtrl,
                        style: TextStyle(color: cs.onSurface),
                        decoration: _inputDecor(
                          "Date of Birth",
                          AppIcons.calender,
                          cs,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // EMAIL
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _inputDecor("Email", AppIcons.email, cs),
                  ),
                  const SizedBox(height: 16),

                  // ✅ 3. PHONE NUMBER UI
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _inputDecor("Phone Number", AppIcons.phone, cs),
                  ),
                  const SizedBox(height: 20),

                  // PASSWORD
                  TextField(
                    controller: passCtrl,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => register(),
                    style: TextStyle(color: cs.onSurface),
                    decoration: _inputDecor("Password", AppIcons.password, cs)
                        .copyWith(
                          suffixIcon: IconButton(
                            icon: AppSvgIcon(
                              asset: _hidePassword
                                  ? AppIcons.view_off
                                  : AppIcons.view,
                              size: 20,
                              color: cs.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() => _hidePassword = !_hidePassword);
                            },
                          ),
                        ),
                  ),
                  const SizedBox(height: 32),

                  // REGISTER BUTTON
                  FilledButton(
                    onPressed: loading ? null : register,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: loading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: cs.onPrimary,
                            ),
                          )
                        : const Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // OR DIVIDER
                  Row(
                    children: [
                      Expanded(child: Divider(color: cs.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "OR",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: cs.outlineVariant)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // GOOGLE SIGN-IN BUTTON
                  OutlinedButton.icon(
                    onPressed: loading ? null : signUpWithGoogle,
                    icon: const AppSvgIcon(asset: AppIcons.google, size: 20),
                    label: const Text(
                      "Continue with Google",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      foregroundColor: cs.onSurface,
                      side: BorderSide(color: cs.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  // LOGIN LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.primary,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text("Login"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
