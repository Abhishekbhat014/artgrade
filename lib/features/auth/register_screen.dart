import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final dobCtrl = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  DateTime? dob;
  String? gender;

  bool loading = false;

  @override
  void dispose() {
    firstNameCtrl.dispose();
    middleNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    dobCtrl.dispose();
    super.dispose();
  }

  // ------------------
  // 📅 Logic
  // ------------------

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

  Future<void> register() async {
    if (loading) return;

    final firstName = firstNameCtrl.text.trim();
    final middleName = middleNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passCtrl.text;

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
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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
      try {
        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.currentUser!.delete();
        }
      } catch (_) {}

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

  // ------------------
  // 🎨 UI Helpers (M3 Styled)
  // ------------------
  InputDecoration _inputDecor(
    String label,
    String asset,
    ColorScheme colorScheme,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      // M3 Filled Style
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

    return Scaffold(
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
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
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

                // FIELDS
                TextField(
                  controller: firstNameCtrl,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor("First Name", AppIcons.user, cs),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: middleNameCtrl,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor(
                    "Middle Name (optional)",
                    AppIcons.user,
                    cs,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: lastNameCtrl,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor("Last Name", AppIcons.user, cs),
                ),
                const SizedBox(height: 16),

                // ✅ M3 COMPLIANT DROPDOWN
                DropdownButtonFormField<String>(
                  value: gender,
                  // Color for the dropdown MENU background (Popup)
                  dropdownColor: cs.surfaceContainerHigh,
                  // Shape of the dropdown MENU (Popup)
                  borderRadius: BorderRadius.circular(16),
                  // Style of the selected item text inside the field
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
                const SizedBox(height: 20),

                // PASSWORD
                TextField(
                  controller: passCtrl,
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.next,
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
                const SizedBox(height: 16),

                // CONFIRM PASSWORD
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: _hideConfirmPassword,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(color: cs.onSurface),
                  decoration:
                      _inputDecor(
                        "Re-enter Password",
                        AppIcons.password,
                        cs,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: AppSvgIcon(
                            asset: _hideConfirmPassword
                                ? AppIcons.view_off
                                : AppIcons.view,
                            size: 20,
                            color: cs.onSurfaceVariant,
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
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
