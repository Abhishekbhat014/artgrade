import 'package:artgrade/about_us_screen.dart';
import 'package:artgrade/features/auth/login_screen.dart';
import 'package:artgrade/utils/snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const SizedBox();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "My Profile",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Edit Profile",
            onPressed: () async {
              try {
                final snap = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get();

                if (!snap.exists || !context.mounted) {
                  AppSnackBar.show(context, "Profile not found", isError: true);
                  return;
                }

                _openEditSheet(context, uid, snap.data()!);
              } catch (_) {
                if (context.mounted) {
                  AppSnackBar.show(
                    context,
                    "Error loading profile",
                    isError: true,
                  );
                }
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedPencilEdit02,
                size: 20,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "Unable to load profile",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final firstName = data['firstName'] ?? 'Student';
          final middleName = data['middleName'] ?? ''; // ✅ Get Middle Name
          final lastName = data['lastName'] ?? '';
          final email = data['email'] ?? '';
          final phone = data['phone'] ?? 'Not set';
          final gender = data['gender'] ?? 'Not set';
          final dob = (data['dob'] as Timestamp?)?.toDate();
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

          // ✅ Logic to display name correctly (avoids double spaces)
          final fullName = [
            firstName,
            middleName,
            lastName,
          ].where((s) => s.toString().trim().isNotEmpty).join(' ');

          String formatDate(DateTime d) =>
              "${d.day.toString().padLeft(2, '0')}/"
              "${d.month.toString().padLeft(2, '0')}/${d.year}";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _Avatar(colorScheme: cs),
                const SizedBox(height: 16),

                // Display Full Name
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                _RoleBadge(colorScheme: cs),
                const SizedBox(height: 32),

                // INFO CARD
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileRow(
                        icon: HugeIcons.strokeRoundedMail01,
                        label: "Email",
                        value: email,
                      ),
                      _ProfileRow(
                        icon: HugeIcons.strokeRoundedCall02,
                        label: "Phone",
                        value: phone,
                      ),
                      _ProfileRow(
                        icon: HugeIcons.strokeRoundedUser,
                        label: "Gender",
                        value: gender,
                      ),
                      if (dob != null)
                        _ProfileRow(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          label: "Date of Birth",
                          value: formatDate(dob),
                        ),
                      if (createdAt != null)
                        _ProfileRow(
                          icon: HugeIcons.strokeRoundedMortarboard01,
                          label: "Joined",
                          value: formatDate(createdAt),
                          isLast: true,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ABOUT US BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutUsScreen(),
                        ),
                      );
                    },
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: 20,
                    ),
                    label: const Text("About Us"),
                  ),
                ),

                const SizedBox(height: 32),

                // SIGN OUT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text("Sign Out"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error.withOpacity(0.6)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
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

  Future<void> _confirmLogout(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }
}

// =======================================================
// EDIT PROFILE SHEET
// =======================================================

class _EditProfileSheet extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> data;

  const _EditProfileSheet({required this.userId, required this.data});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController firstNameCtrl;
  late final TextEditingController middleNameCtrl; // ✅ Added
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
    // ✅ Init Middle Name
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
      "${d.day.toString().padLeft(2, '0')}/"
      "${d.month.toString().padLeft(2, '0')}/"
      "${d.year}";

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(now.year - 15),
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: "Select Date of Birth",
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
    final middleName = middleNameCtrl.text.trim(); // ✅ Capture Middle
    final lastName = lastNameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    if (firstName.length < 2) {
      AppSnackBar.show(context, "Invalid first name", isError: true);
      return;
    }

    if (dob != null && dob!.isAfter(DateTime.now())) {
      AppSnackBar.show(context, "Invalid date of birth", isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            "firstName": firstName,
            "middleName": middleName, // ✅ Save Middle Name
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    InputDecoration decor(String label, dynamic icon) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surfaceVariant,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: HugeIcon(icon: icon, size: 20, color: cs.onSurfaceVariant),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Edit Profile",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // First Name
          TextField(
            controller: firstNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: decor("First Name", HugeIcons.strokeRoundedUser),
          ),
          const SizedBox(height: 16),

          // ✅ Middle Name Field
          TextField(
            controller: middleNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: decor(
              "Middle Name (Optional)",
              HugeIcons.strokeRoundedUser,
            ),
          ),
          const SizedBox(height: 16),

          // Last Name
          TextField(
            controller: lastNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: decor("Last Name", HugeIcons.strokeRoundedUser),
          ),
          const SizedBox(height: 16),

          // Phone
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: decor("Phone", HugeIcons.strokeRoundedSmartPhone01),
          ),
          const SizedBox(height: 16),

          // Date of Birth
          GestureDetector(
            onTap: _pickDob,
            child: AbsorbPointer(
              child: TextField(
                controller: dobCtrl,
                decoration:
                    decor(
                      "Date of Birth",
                      HugeIcons.strokeRoundedCalendar01,
                    ).copyWith(
                      hintText: "Select Date of Birth",
                      suffixIcon: Center(
                        widthFactor: 1.0,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar03,
                              size: 20,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gender
          DropdownButtonFormField<String>(
            value: gender,
            decoration: decor("Gender", HugeIcons.strokeRoundedUserMultiple),
            items: const [
              DropdownMenuItem(value: "Male", child: Text("Male")),
              DropdownMenuItem(value: "Female", child: Text("Female")),
              DropdownMenuItem(value: "Other", child: Text("Other")),
            ],
            onChanged: (v) => setState(() => gender = v!),
          ),

          const SizedBox(height: 32),

          // Save Button
          FilledButton(
            onPressed: loading ? null : _saveProfile,
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Save Changes"),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// UI HELPERS (THEME SAFE)
// =======================================================

class _Avatar extends StatelessWidget {
  final ColorScheme colorScheme;
  const _Avatar({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 110,
          width: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withOpacity(0.15),
          ),
        ),
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedUserCircle,
              size: 50,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final ColorScheme colorScheme;
  const _RoleBadge({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedMortarboard02,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            "Student",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;
  final bool isLast;

  const _ProfileRow({
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
        if (!isLast) Divider(height: 1, thickness: 1, color: cs.outlineVariant),
      ],
    );
  }
}
