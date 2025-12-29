import 'package:artgrade/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart'; // Add to pubspec.yaml if you want email tapping

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
          ),
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "About Us",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            // 1. Brand Header
            const _BrandHeader(),

            const SizedBox(height: 32),

            // 2. Info Cards
            _FeatureCard(
              icon: HugeIcons.strokeRoundedBookOpen01,
              color: Colors.blueAccent,
              title: "What is ArtGrade?",
              content:
                  "ArtGrade is a structured learning platform designed to guide students through art education step-by-step. Each course is carefully organized to support consistent progress.",
            ),
            _FeatureCard(
              icon: HugeIcons.strokeRoundedTarget01,
              color: Colors.orange,
              title: "Our Mission",
              content:
                  "Our mission is to make art education accessible, trackable, and engaging — especially for students preparing for graded examinations and structured programs.",
            ),

            const SizedBox(height: 16),

            // 3. Developer Details (NEW)
            const _DeveloperCard(
              name: "Abhishek Bhat",
              role: "Lead Developer & Creator",
              email: "dev.artgrade@gmail.com",
            ),

            const SizedBox(height: 24),

            // 4. Footer
            _AppFooter(colorScheme: cs),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/* =======================================================
   COMPONENTS
======================================================= */

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                'assets/images/ArtGradeLogo.png',
                width: 60,
                height: 60,
                errorBuilder: (c, o, s) => const HugeIcon(
                  icon: HugeIcons.strokeRoundedPaintBoard,
                  size: 40,
                  color: Color(0xFF2D3142),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "ArtGrade",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2D3142),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Mastering Art, One Grade at a Time",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final dynamic icon;
  final Color color;
  final String title;
  final String content;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: HugeIcon(icon: icon, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// NEW: DEVELOPER CARD
// -------------------------------------------------------
class _DeveloperCard extends StatelessWidget {
  final String name;
  final String role;
  final String email;

  const _DeveloperCard({
    required this.name,
    required this.role,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            "Developed By",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3142),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedComputerProgramming01,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Contact Button
              IconButton(
                onPressed: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: email,
                    query: Uri.encodeQueryComponent(
                      'subject=ArtGrade Support&body=Hello Abhishek,',
                    ),
                  );

                  try {
                    await launchUrl(
                      emailUri,
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {
                    // optional: snackbar (logic-only addition)
                    if (context.mounted) {
                      AppSnackBar.show(context, "No email app found");
                    }
                  }
                },

                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMail02,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppFooter extends StatelessWidget {
  final ColorScheme colorScheme;
  const _AppFooter({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(color: Colors.grey.shade200, thickness: 1),
        const SizedBox(height: 24),
        Text(
          "© ${DateTime.now().year} ArtGrade",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Version 1.0.0",
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.primary.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
