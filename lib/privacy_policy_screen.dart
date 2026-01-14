import 'package:artgrade/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 Use Global Theme
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Privacy Policy",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: AppSvgIcon(
            asset: AppIcons.arrow_left,
            size: 20,
            color: cs.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLastUpdated(theme, "January 10, 2026"),
                const SizedBox(height: 24),

                _buildSectionTitle(theme, "1. INTRODUCTION"),
                _buildBodyText(
                  theme,
                  "Welcome to ArtGrade. We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and safeguard your information when you use our mobile application.",
                ),

                _buildSectionTitle(theme, "2. INFORMATION WE COLLECT"),
                _buildBodyText(
                  theme,
                  "We collect information necessary to provide our educational services effectively. This includes:",
                ),
                _buildBulletPoint(
                  theme,
                  "Personal Identification: Name, email address, phone number, gender, and date of birth.",
                ),
                _buildBulletPoint(
                  theme,
                  "Account Data: User roles (Admin, Teacher, Student) and login credentials managed securely via Firebase Authentication.",
                ),
                _buildBulletPoint(
                  theme,
                  "User-Generated Content: Academic materials such as subjects, PDFs, videos, and profile details that you upload or create.",
                ),
                _buildBodyText(
                  theme,
                  "We do NOT collect sensitive financial information or credit card details.",
                ),

                _buildSectionTitle(theme, "3. HOW WE USE YOUR INFORMATION"),
                _buildBodyText(
                  theme,
                  "Your data is used solely for the functionality of the ArtGrade platform:",
                ),
                _buildBulletPoint(
                  theme,
                  "To manage user accounts and authentication.",
                ),
                _buildBulletPoint(
                  theme,
                  "To facilitate the organization of classes, subjects, and materials.",
                ),
                _buildBulletPoint(
                  theme,
                  "To communicate important updates regarding your account or the service.",
                ),
                _buildBulletPoint(
                  theme,
                  "To ensure the security and integrity of our platform.",
                ),

                _buildSectionTitle(theme, "4. DATA STORAGE & SECURITY"),
                _buildBodyText(
                  theme,
                  "We implement industry-standard security measures to protect your data. Your personal information is stored securely on Google Cloud servers via Firebase Cloud Firestore. While we strive to use commercially acceptable means to protect your data, no method of transmission over the internet is 100% secure.",
                ),

                _buildSectionTitle(theme, "5. THIRD-PARTY SERVICES"),
                _buildBodyText(
                  theme,
                  "ArtGrade uses third-party services that may collect information used to identify you. The primary service provider we use is Google Firebase for:",
                ),
                _buildBulletPoint(
                  theme,
                  "Authentication (Identity verification).",
                ),
                _buildBulletPoint(theme, "Cloud Firestore (Database storage)."),
                _buildBulletPoint(theme, "Cloud Storage (File hosting)."),

                _buildSectionTitle(theme, "6. USER RIGHTS"),
                _buildBodyText(theme, "You have the right to:"),
                _buildBulletPoint(
                  theme,
                  "Access the personal information we hold about you.",
                ),
                _buildBulletPoint(
                  theme,
                  "Request corrections to any inaccurate data.",
                ),
                _buildBulletPoint(
                  theme,
                  "Request deletion of your account and associated data (subject to administrative retention policies).",
                ),

                _buildSectionTitle(theme, "7. CHILDREN’S PRIVACY"),
                _buildBodyText(
                  theme,
                  "ArtGrade is an educational tool intended for use by students, teachers, and administrators. We do not knowingly collect personal data from children under the age of 13 without parental or institutional consent. If we discover that a child under 13 has provided us with personal information without consent, we will delete it immediately.",
                ),

                _buildSectionTitle(theme, "8. CHANGES TO THIS POLICY"),
                _buildBodyText(
                  theme,
                  "We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page. You are advised to review this page periodically for any changes.",
                ),

                _buildSectionTitle(theme, "9. CONTACT INFORMATION"),
                _buildBodyText(
                  theme,
                  "If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at:",
                ),
                const SizedBox(height: 16),

                // ✅ UPDATED: M3 Compliant Contact Card
                _buildContactCard(context),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "© 2026 ArtGrade. All rights reserved.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // 🛠️ UI HELPER METHODS
  // --------------------------------------------------

  Widget _buildContactCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ✅ Using Standard M3 Card
    return Card(
      elevation: 2, // Standard elevation (Shadow for Light, Tint for Dark)
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final uri = Uri(
            scheme: 'mailto',
            path: 'dev.artgrade@gmail.com',
            query: 'subject=Privacy Policy Inquiry',
          );
          if (!await launchUrl(uri)) {
            // Handle error silently
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: AppSvgIcon(
                    asset: AppIcons.email,
                    size: 24,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Email Support",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "dev.artgrade@gmail.com",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              AppSvgIcon(
                asset: AppIcons.arrow_right,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastUpdated(ThemeData theme, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Last Updated: $date",
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBodyText(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          height: 1.6, // Better readability for long text
        ),
      ),
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
