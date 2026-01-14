import 'package:artgrade/utils/snackbar.dart';
import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
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
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: AppSvgIcon(
            asset: AppIcons.arrow_left,
            size: 20,
            color: cs.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "About Us",
          style: theme.textTheme.titleMedium?.copyWith(
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
              asset: AppIcons.book,
              color: cs.primary,
              title: "What is ArtGrade?",
              content:
                  "ArtGrade is a structured learning platform designed to guide students through art education step-by-step. Each course is carefully organized to support consistent progress.",
            ),
            const _FeatureCard(
              asset: AppIcons.vision,
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
   BRAND HEADER (M3 Compliant)
======================================================= */

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ✅ Replaced manual BoxShadow with Material Elevation
        Material(
          elevation: 10, // High elevation for "Floating Logo" look
          shape: const CircleBorder(),
          color: cs.surface,
          child: Container(
            height: 100,
            width: 100,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Center(
              child: Image.asset(
                "assets/images/ArtGradeLogo.png",
                height: 60,
                width: 60,
              ),
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
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Mastering Art, One Grade at a Time",
          textAlign: TextAlign.center,
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
   FEATURE CARD (M3 Compliant)
======================================================= */

class _FeatureCard extends StatelessWidget {
  final String asset;
  final Color color;
  final String title;
  final String content;

  const _FeatureCard({
    required this.asset,
    required this.color,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ Standard Card (Theme handles shadow/tint)
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                  child: AppSvgIcon(asset: asset, size: 24, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
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
      ),
    );
  }
}

/* =======================================================
   DEVELOPER CARD (M3 Compliant)
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Developed By",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        // ✅ Standard Card
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                    child: AppSvgIcon(
                      asset: AppIcons.developer,
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
                      const SizedBox(height: 2),
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
                      if (context.mounted) {
                        AppSnackBar.show(context, "No email app found");
                      }
                    }
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: cs.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: AppSvgIcon(
                    asset: AppIcons.email,
                    size: 20,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
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
        Divider(color: colorScheme.outlineVariant.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          "© ${DateTime.now().year} ArtGrade",
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          "v1.0.0",
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
