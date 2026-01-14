import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
  }

  // ==========================================
  // 🧠 LOGIC (UNCHANGED)
  // ==========================================

  Future<void> login() async {
    if (loading) return;

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
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, _mapAuthError(e), isError: true);
    } on PlatformException catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        "Something went wrong, please try again",
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        "Something went wrong, please try again",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Account does not exist';
      case 'user-disabled':
        return 'Account is disabled';
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password';
      default:
        return e.message ?? 'Login failed';
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // 🎨 UI HELPERS (M3 STYLING)
  // ==========================================

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
      // Allow content to resize when keyboard opens
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOGO
                Image.asset(
                  'assets/images/ArtGradeLogo.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),

                // HEADER
                Text(
                  "ArtGrade",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Welcome back, please sign in.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),

                // EMAIL INPUT
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: cs.onSurface),
                  decoration: _inputDecor("Email", AppIcons.email, cs),
                ),
                const SizedBox(height: 20),

                // PASSWORD INPUT
                TextField(
                  controller: passCtrl,
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.done,
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

                // LOGIN BUTTON
                FilledButton(
                  onPressed: loading ? null : login,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      56,
                    ), // Tall M3 Button
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
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                if (!hasInternet) ...[
                  const SizedBox(height: 12),
                  Text(
                    "No internet connection",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // REGISTER LINK
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
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
                      style: TextButton.styleFrom(
                        foregroundColor: cs.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
