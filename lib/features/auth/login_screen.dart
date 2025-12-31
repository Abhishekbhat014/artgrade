import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;
  bool hasInternet = true;
  bool _hidePassword = true;

  Timer? _internetTimer;

  // ------------------
  // Internet check
  // ------------------
  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    // Initial check (faster feedback on first open)
    _checkInternet().then((status) {
      if (!mounted) return;
      setState(() => hasInternet = status);
    });

    // Periodic check (non-blocking)
    _internetTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final status = await _checkInternet();
      if (!mounted || status == hasInternet) return;
      setState(() => hasInternet = status);
    });
  }

  // ------------------
  // Login logic
  // ------------------
  Future<void> login() async {
    if (loading) return;

    if (!hasInternet) {
      AppSnackBar.show(
        context,
        "Internet connection required to login",
        isError: true,
      );
      return;
    }

    final email = emailCtrl.text.trim();
    final password = passCtrl.text;

    if (!Validators.isNotEmpty(email) || !Validators.isNotEmpty(password)) {
      AppSnackBar.show(
        context,
        "Please enter email and password",
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

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ NOTHING ELSE HERE
      // AuthGate will react automatically
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final message = switch (e.code) {
        'user-not-found' => "No user found for that email",
        'wrong-password' => "Incorrect password",
        'invalid-email' => "Invalid email address",
        _ => "Login failed",
      };

      AppSnackBar.show(context, message, isError: true);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        "Something went wrong. Try again.",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _internetTimer?.cancel();
    emailCtrl.dispose();
    passCtrl.dispose();
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
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),

                Text(
                  "ArtGrade",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),

                Text(
                  "Welcome back, please sign in.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 48),

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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => login(),
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

                const SizedBox(height: 32),

                FilledButton(
                  onPressed: (!hasInternet || loading) ? null : login,
                  child: loading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text("Login"),
                ),

                if (!hasInternet) ...[
                  const SizedBox(height: 12),
                  Text(
                    "No internet connection",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text("Create account"),
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
