import 'package:artgrade/about_us_screen.dart';
import 'package:artgrade/core/constants/theme_controller.dart';
import 'package:artgrade/features/auth/login_screen.dart';
import 'package:artgrade/privacy_policy_screen.dart';
import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/utils/validators.dart';
import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            "My Profile",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: cs.primary.withOpacity(0.1),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                splashBorderRadius: BorderRadius.circular(15),
                tabs: const [
                  Tab(text: "Personal"),
                  Tab(text: "Settings"),
                ],
              ),
            ),
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: cs.primary),
              );
            }

            if (!snapshot.data!.exists) return const _ErrorState();

            final data = snapshot.data!.data() as Map<String, dynamic>;

            return TabBarView(
              children: [
                _PersonalTab(data: data, uid: user.uid),
                _SettingsTab(email: data['email'] ?? ''),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* =======================================================
   TAB 1: PERSONAL DETAILS
======================================================= */

class _PersonalTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final String uid;

  const _PersonalTab({required this.data, required this.uid});

  @override
  Widget build(BuildContext context) {
    final firstName = data['firstName'] ?? '';
    final middleName = data['middleName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final email = data['email'] ?? '';
    final phone = data['phone'] ?? '—';
    final gender = data['gender'] ?? '—';
    final dob = (data['dob'] as Timestamp?)?.toDate();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    final fullName = [
      firstName,
      middleName,
      lastName,
    ].where((s) => s.toString().trim().isNotEmpty).join(' ');

    String formatDate(DateTime d) =>
        "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/${d.year}";

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        children: [
          // 1. Centered Header
          _ProfileHeaderCard(
            name: fullName.isNotEmpty ? fullName : "Administrator",
            role: "Administrator",
            onEdit: () => _openEditSheet(context, uid, data),
          ),

          const SizedBox(height: 32),

          // 2. Contact Info
          const _SectionHeader(title: "Contact Information"),
          const SizedBox(height: 12),
          _InfoGroup(
            children: [
              _InfoRow(icon: AppIcons.email, label: "Email", value: email),
              _InfoRow(
                icon: AppIcons.phone,
                label: "Phone",
                value: phone,
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 3. Basic Details
          const _SectionHeader(title: "Personal Details"),
          const SizedBox(height: 12),
          _InfoGroup(
            children: [
              _InfoRow(icon: AppIcons.avatar, label: "Gender", value: gender),
              if (dob != null)
                _InfoRow(
                  icon: AppIcons.calender,
                  label: "Birthday",
                  value: formatDate(dob),
                ),
              if (createdAt != null)
                _InfoRow(
                  icon: AppIcons.shield,
                  label: "Admin Since",
                  value: formatDate(createdAt),
                  isLast: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openEditSheet(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(userId: uid, data: data),
    );
  }
}

/* =======================================================
   TAB 2: SETTINGS
======================================================= */

class _SettingsTab extends StatelessWidget {
  final String email;
  const _SettingsTab({required this.email});

  void _openThemePicker(BuildContext context) {
    final themeController = context.read<ThemeController>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Choose Appearance",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<ThemeMode>(
              title: const Text("System"),
              value: ThemeMode.system,
              groupValue: themeController.themeMode,
              onChanged: (v) {
                themeController.setTheme(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text("Light"),
              value: ThemeMode.light,
              groupValue: themeController.themeMode,
              onChanged: (v) {
                themeController.setTheme(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text("Dark"),
              value: ThemeMode.dark,
              groupValue: themeController.themeMode,
              onChanged: (v) {
                themeController.setTheme(v!);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeController = context.watch<ThemeController>();

    String themeLabel(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return "Light";
        case ThemeMode.dark:
          return "Dark";
        case ThemeMode.system:
          return "System";
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: "Security"),
          const SizedBox(height: 12),
          _InfoGroup(
            children: [
              _ActionRow(
                icon: AppIcons.password,
                label: "Change Password",
                onTap: () async {
                  if (email.isEmpty) {
                    AppSnackBar.show(
                      context,
                      "Please enter your registered email",
                      isError: true,
                    );
                    return;
                  }

                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: email.trim(),
                    );
                    if (!context.mounted) return;
                    AppSnackBar.show(
                      context,
                      "Password reset link sent to $email",
                    );
                  } on FirebaseAuthException catch (e) {
                    AppSnackBar.show(
                      context,
                      e.message ?? "Failed to send reset link",
                      isError: true,
                    );
                  }
                },
              ),
              _ActionRow(
                icon: AppIcons.shield,
                label: "Privacy Policy",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          const _SectionHeader(title: "App Settings"),
          const SizedBox(height: 12),
          _InfoGroup(
            children: [
              _ActionRow(
                icon: AppIcons.sun,
                label: "Appearance",
                trailingText: themeLabel(themeController.themeMode),
                onTap: () => _openThemePicker(context),
              ),
              _ActionRow(
                icon: AppIcons.info,
                label: "About ArtGrade",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                  );
                },
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const AppSvgIcon(asset: AppIcons.logout, size: 18),
              label: const Text("Sign Out"),
              style: FilledButton.styleFrom(
                backgroundColor: cs.errorContainer,
                foregroundColor: cs.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              "v1.0.0",
              style: TextStyle(
                color: cs.onSurfaceVariant.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =======================================================
   REFACTORED WIDGETS (M3 Compliant)
======================================================= */

class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String role;
  final VoidCallback onEdit;

  const _ProfileHeaderCard({
    required this.name,
    required this.role,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Avatar with Edit Button overlaid
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: cs.primaryContainer,
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 4),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "A",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                child: AppSvgIcon(
                  asset: AppIcons.edit,
                  size: 16,
                  color: cs.onPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            role,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _InfoGroup extends StatelessWidget {
  final List<Widget> children;
  const _InfoGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppSvgIcon(
                  asset: icon,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 64,
            endIndent: 20,
            color: cs.outlineVariant.withOpacity(0.3),
          ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingText;
  final bool isLast;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(24))
            : const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppSvgIcon(asset: icon, size: 20, color: cs.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (trailingText != null) ...[
                    Text(
                      trailingText!,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AppSvgIcon(
                    asset: AppIcons.arrow_right,
                    size: 20,
                    color: cs.onSurfaceVariant.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                indent: 64,
                endIndent: 20,
                color: cs.outlineVariant.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Could not load profile"));
  }
}

/* =======================================================
   EDIT PROFILE SHEET
======================================================= */

class _EditProfileSheet extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> data;

  const _EditProfileSheet({required this.userId, required this.data});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController firstNameCtrl;
  late final TextEditingController middleNameCtrl;
  late final TextEditingController lastNameCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController dobCtrl;

  late String gender;
  DateTime? dob;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    firstNameCtrl = TextEditingController(text: widget.data['firstName'] ?? '');
    middleNameCtrl = TextEditingController(
      text: widget.data['middleName'] ?? '',
    );
    lastNameCtrl = TextEditingController(text: widget.data['lastName'] ?? '');
    phoneCtrl = TextEditingController(text: widget.data['phone'] ?? '');
    gender = widget.data['gender'] ?? 'Male';

    final ts = widget.data['dob'];
    if (ts is Timestamp) {
      dob = ts.toDate();
    }
    dobCtrl = TextEditingController(text: dob != null ? _formatDob(dob!) : '');
  }

  String _formatDob(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        dob = picked;
        dobCtrl.text = _formatDob(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (loading) return;

    final firstName = firstNameCtrl.text.trim();
    final middleName = middleNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();
    final phone = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

    if (!Validators.isValidName(firstName)) {
      AppSnackBar.show(
        context,
        "First name must contain only letters",
        isError: true,
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            "firstName": firstName,
            "middleName": middleName,
            "lastName": lastName,
            "phone": phone,
            "gender": gender,
            if (dob != null) "dob": Timestamp.fromDate(dob!),
            "updatedAt": Timestamp.now(),
          });

      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBar.show(context, "Profile updated successfully");
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, "Failed to update profile", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    InputDecoration decor(String label, String asset) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: AppSvgIcon(asset: asset, size: 22, color: cs.onSurfaceVariant),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Edit Profile",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: firstNameCtrl,
              decoration: decor("First Name", AppIcons.user),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: middleNameCtrl,
              decoration: decor("Middle Name", AppIcons.user),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lastNameCtrl,
              decoration: decor("Last Name", AppIcons.user),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: decor("Phone", AppIcons.phone),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: decor("Gender", AppIcons.user),
              dropdownColor: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              value: gender,
              items: const [
                DropdownMenuItem(value: "Male", child: Text("Male")),
                DropdownMenuItem(value: "Female", child: Text("Female")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
              ],
              onChanged: (v) => setState(() => gender = v!),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickDob,
              child: AbsorbPointer(
                child: TextField(
                  controller: dobCtrl,
                  decoration: decor("Birthday", AppIcons.calender),
                ),
              ),
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: loading ? null : _saveProfile,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
