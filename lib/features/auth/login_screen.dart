import 'package:artgrade/core/services/google_auth_service.dart';
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
  bool _hidePassword = true;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

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

      // ✅ DO NOTHING ELSE
      // AuthGate will rebuild automatically
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, _mapAuthError(e), isError: true);
    } on PlatformException {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        "Something went wrong, please try again",
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        "Something went wrong, please try again",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => loading = false);
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

  // ==========================================
  // 🎨 UI HELPERS
  // ==========================================

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
      // Ensures the icon area is consistent
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ✅ UX IMPROVEMENT: Wrap in GestureDetector to close keyboard on tap
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LOGO
                  Image.asset(
                    'assets/images/ArtGradeLogo.png',
                    height: 90, // Slightly reduced to save vertical space
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),

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
                  const SizedBox(
                    height: 32,
                  ), // Reduced from 48 for better mobile fit
                  // EMAIL INPUT
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: cs.onSurface),
                    decoration: _inputDecor("Email", AppIcons.email, cs),
                  ),
                  const SizedBox(
                    height: 16,
                  ), // Reduced from 20 for tighter grouping
                  // PASSWORD INPUT
                  TextField(
                    controller: passCtrl,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    // ✅ UX: Allow submitting form directly from keyboard
                    onSubmitted: (_) => login(),
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
                            "Login",
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

                  // ✅ UI FIX: Use OutlinedButton for secondary actions
                  // This is cleaner and handles the border/background logic natively
                  OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : () async {
                            try {
                              setState(() => loading = true);
                              await AuthService.forceGoogleReauth();
                              // ✅ NO NAVIGATION
                            } catch (_) {
                              if (!context.mounted) return;
                              AppSnackBar.show(
                                context,
                                "Google sign-in failed.",
                                isError: true,
                              );
                            } finally {
                              if (mounted) setState(() => loading = false);
                            }
                          },

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
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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
      ),
    );
  }
}
