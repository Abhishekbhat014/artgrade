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
            color: const Color(0xFF2D3142),
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
              } catch (e) {
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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text("Unable to load profile"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final firstName = data['firstName'] ?? 'Student';
          final lastName = data['lastName'] ?? '';
          final email = data['email'] ?? '';
          final phone = data['phone'] ?? 'Not set';
          final gender = data['gender'] ?? 'Not set';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Avatar
                _Avatar(colorScheme: cs),

                const SizedBox(height: 16),
                Text(
                  "$firstName $lastName",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 6),
                _RoleBadge(colorScheme: cs),

                const SizedBox(height: 32),

                // Info Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
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
                      if (createdAt != null)
                        _ProfileRow(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          label: "Joined",
                          value:
                              "${createdAt.day}/${createdAt.month}/${createdAt.year}",
                          isLast: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: cs.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: cs.primary,
                    ),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: 20,
                    ),
                    label: const Text("About Us"),
                  ),
                ),

                const SizedBox(height: 32),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Colors.redAccent.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: Colors.redAccent,
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text("Sign Out"),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Sign Out",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
  late final TextEditingController lastNameCtrl;
  late final TextEditingController phoneCtrl;
  late String gender;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    firstNameCtrl = TextEditingController(text: widget.data['firstName'] ?? '');
    lastNameCtrl = TextEditingController(text: widget.data['lastName'] ?? '');
    phoneCtrl = TextEditingController(text: widget.data['phone'] ?? '');
    gender = widget.data['gender'] ?? 'Male';
  }

  Future<void> _save() async {
    if (firstNameCtrl.text.trim().isEmpty) {
      AppSnackBar.show(context, "First name is required", isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'firstName': firstNameCtrl.text.trim(),
            'lastName': lastNameCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
            'gender': gender,
            'updatedAt': Timestamp.now(),
          });

      if (!mounted) return;
      Navigator.pop(context);
      AppSnackBar.show(context, "Profile updated successfully");
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, "Failed to update profile: $e", isError: true);
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
      fillColor: const Color(0xFFF8F9FC),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: HugeIcon(icon: icon, size: 20, color: Colors.grey.shade500),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Edit Profile",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 24),

          TextField(
            controller: firstNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: decor("First Name", HugeIcons.strokeRoundedUser),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: lastNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: decor("Last Name", HugeIcons.strokeRoundedUser),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: decor("Phone", HugeIcons.strokeRoundedSmartPhone01),
          ),
          const SizedBox(height: 16),

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

          FilledButton(
            onPressed: loading ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "Save Changes",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

/* =======================================================
   UI HELPERS
======================================================= */

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
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
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
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    size: 20,
                    color: Colors.grey.shade600,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
      ],
    );
  }
}
