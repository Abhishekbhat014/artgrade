import 'dart:io';

import 'package:artgrade/core/services/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  File? profileImage;
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();

  DateTime? dob;
  String? gender;
  bool loading = false;

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    dobCtrl.dispose();
    super.dispose();
  }

  // ... [Logic methods remain exactly the same] ...
  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => profileImage = File(picked.path));
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

  Future<void> saveProfile() async {
    if (loading) return;

    final firstName = firstNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      AppSnackBar.show(
        context,
        "Please enter first and last name",
        isError: true,
      );
      return;
    }

    if (phone.isEmpty || phone.length < 10) {
      AppSnackBar.show(context, "Enter a valid phone number", isError: true);
      return;
    }

    if (gender == null) {
      AppSnackBar.show(context, "Select gender", isError: true);
      return;
    }

    if (dob == null) {
      AppSnackBar.show(context, "Select date of birth", isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String? photoUrl;

      if (profileImage != null) {
        photoUrl = await CloudinaryService.uploadProfileImage(profileImage!);
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'gender': gender,
        'dob': Timestamp.fromDate(dob!),
        'profileComplete': true,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, "Failed to save profile.", isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ==========================================
  // 🎨 UI HELPERS
  // ==========================================
  InputDecoration _inputDecor(String label, String asset, ColorScheme cs) {
    return InputDecoration(
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ✅ UX: GestureDetector to dismiss keyboard
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        // ✅ UI: SafeArea prevents content from hiding behind the notch
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    Text(
                      "Complete Your Profile",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We need a few more details to continue",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ===============================
                    // PROFILE IMAGE PICKER
                    // ===============================
                    Center(
                      child: GestureDetector(
                        onTap: pickProfileImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.surfaceContainerHighest,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 56, // Slightly larger
                                backgroundColor: cs.surfaceContainerHighest
                                    .withOpacity(0.3),
                                backgroundImage: profileImage != null
                                    ? FileImage(profileImage!)
                                    : null,
                                child: profileImage == null
                                    ? AppSvgIcon(
                                        asset: AppIcons.user, // Consistent icon
                                        size: 40,
                                        color: cs.onSurfaceVariant.withOpacity(
                                          0.5,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            // Camera Badge with Border
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 3, // Creates separation visual
                                ),
                              ),
                              child: AppSvgIcon(
                                asset: AppIcons.camera_add,
                                size: 16,
                                color: cs.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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

                    // PHONE
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(color: cs.onSurface),
                      decoration: _inputDecor(
                        "Phone Number",
                        AppIcons.phone,
                        cs,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // GENDER
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: _inputDecor("Gender", AppIcons.gender, cs),
                      dropdownColor: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      // Ensure text style matches TextField
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                      ),
                      icon: AppSvgIcon(
                        asset: AppIcons.arrow_down,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                      items: const [
                        DropdownMenuItem(value: "male", child: Text("Male")),
                        DropdownMenuItem(
                          value: "female",
                          child: Text("Female"),
                        ),
                        DropdownMenuItem(value: "other", child: Text("Other")),
                      ],
                      onChanged: (v) => setState(() => gender = v),
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
                    const SizedBox(height: 32),

                    // SAVE BUTTON
                    FilledButton(
                      onPressed: loading ? null : saveProfile,
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
                              "Continue",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
