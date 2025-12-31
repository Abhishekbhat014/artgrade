import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:artgrade/utils/snackbar.dart';
import '../../auth/login_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Profile",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
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

            if (!snapshot.data!.exists) {
              return const _ErrorState();
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

            return Stack(
              children: [
                _ProfileContent(data: data),
                Positioned(
                  top: 8,
                  right: 16,
                  child: IconButton(
                    tooltip: "Edit Profile",
                    onPressed: () => _openEditSheet(context, user.uid, data),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withOpacity(0.15),
                            blurRadius: 10,
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
                ),
              ],
            );
          },
        ),
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
   PROFILE CONTENT
======================================================= */

class _ProfileContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProfileContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final email = data['email'] ?? '';
    final phone = data['phone'] ?? '—';
    final gender = data['gender'] ?? '—';
    final dob = (data['dob'] as Timestamp?)?.toDate();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    String formatDate(DateTime d) =>
        "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/${d.year}";

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        children: [
          const _Avatar(),
          const SizedBox(height: 16),
          Text(
            "$firstName $lastName",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          _RoleBadge(colorScheme: cs),
          const SizedBox(height: 32),
          _Card(
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
                  icon: HugeIcons.strokeRoundedShield01,
                  label: "Member Since",
                  value: formatDate(createdAt),
                  isLast: true,
                ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedLogout02,
                size: 20,
                color: Colors.redAccent,
              ),
              label: const Text("Sign Out"),
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
        ],
      ),
    );
  }
}

/* =======================================================
   EDIT PROFILE SHEET (WITH DOB)
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
  late final TextEditingController dobCtrl;

  late String gender;
  DateTime? dob;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    firstNameCtrl = TextEditingController(text: widget.data['firstName'] ?? '');
    lastNameCtrl = TextEditingController(text: widget.data['lastName'] ?? '');
    phoneCtrl = TextEditingController(text: widget.data['phone'] ?? '');
    gender = widget.data['gender'] ?? 'Male';

    dob = (widget.data['dob'] as Timestamp?)?.toDate();

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
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: "Select Date of Birth",
    );

    if (picked != null) {
      setState(() {
        dob = picked;
        dobCtrl.text = _formatDob(picked); // ✅ THIS FIXES DISPLAY
      });
    }
  }

  Future<void> _saveProfile() async {
    if (loading) return;

    final firstName = firstNameCtrl.text.trim();
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

    InputDecoration decor(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surfaceVariant,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          TextField(controller: firstNameCtrl, decoration: decor("First Name")),
          const SizedBox(height: 16),
          TextField(controller: lastNameCtrl, decoration: decor("Last Name")),
          const SizedBox(height: 16),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: decor("Phone"),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: gender,
            decoration: decor("Gender"),
            items: const [
              DropdownMenuItem(value: "Male", child: Text("Male")),
              DropdownMenuItem(value: "Female", child: Text("Female")),
              DropdownMenuItem(value: "Other", child: Text("Other")),
            ],
            onChanged: (v) => setState(() => gender = v!),
          ),

          const SizedBox(height: 16),

          // Inside _EditProfileSheetState -> build method
          GestureDetector(
            onTap: _pickDob,
            child: AbsorbPointer(
              child: TextField(
                controller: dobCtrl,
                decoration: decor("Date of Birth").copyWith(
                  hintText: "Select Date of Birth",
                  // ✅ FIXED: Correctly sized and aligned icon
                  suffixIcon: Center(
                    widthFactor: 1.0,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          size: 20, // Clean size
                          color: cs.onSurfaceVariant, // Theme safe color
                        ),
                      ),
                    ),
                  ),
                  // ✅ Constraints prevent it from stretching
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

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

/* =======================================================
   SMALL HELPERS
======================================================= */

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primary.withOpacity(0.15),
      ),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUserCircle,
          size: 48,
          color: cs.primary,
        ),
      ),
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
        color: colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "Administrator",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: cs.shadow.withOpacity(0.08), blurRadius: 12),
        ],
      ),
      child: Column(children: children),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              HugeIcon(icon: icon, size: 20, color: cs.onSurfaceVariant),
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
                      ),
                    ),
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
        if (!isLast) Divider(height: 1, color: cs.outlineVariant),
      ],
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
