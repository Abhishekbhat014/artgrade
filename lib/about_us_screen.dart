import 'package:artgrade/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
          ),
          color: cs.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "About Us",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            const _BrandHeader(),
            const SizedBox(height: 32),

            _FeatureCard(
              icon: HugeIcons.strokeRoundedBookOpen01,
              color: cs.primary,
              title: "What is ArtGrade?",
              content:
                  "ArtGrade is a structured learning platform designed to guide students through art education step-by-step. Each course is carefully organized to support consistent progress.",
            ),
            _FeatureCard(
              icon: HugeIcons.strokeRoundedTarget01,
              color: Colors.orange,
              title: "Our Mission",
              content:
                  "Our mission is to make art education accessible, trackable, and engaging — especially for students preparing for graded examinations.",
            ),

            const SizedBox(height: 16),

            const _DeveloperCard(
              name: "Abhishek Bhat",
              role: "Lead Developer & Creator",
              email: "dev.artgrade@gmail.com",
            ),

            const SizedBox(height: 24),
            _AppFooter(colorScheme: cs),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/* =======================================================
   BRAND HEADER
======================================================= */

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            color: cs.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedPaintBoard,
              size: 40,
              color: cs.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "ArtGrade",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Mastering Art, One Grade at a Time",
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/* =======================================================
   FEATURE CARD
======================================================= */

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
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.12),
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: HugeIcon(icon: icon, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
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
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/* =======================================================
   DEVELOPER CARD
======================================================= */

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
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Developed By",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: cs.shadow.withOpacity(0.12), blurRadius: 16),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: cs.primary,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final uri = Uri(
                    scheme: 'mailto',
                    path: email,
                    query: 'subject=ArtGrade Support&body=Hello Abhishek,',
                  );

                  if (!await launchUrl(uri)) {
                    AppSnackBar.show(context, "No email app found");
                  }
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedMail02,
                  size: 20,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* =======================================================
   FOOTER
======================================================= */

class _AppFooter extends StatelessWidget {
  final ColorScheme colorScheme;
  const _AppFooter({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(color: colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Text(
          "© ${DateTime.now().year} ArtGrade",
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          "Version 1.0.0",
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
