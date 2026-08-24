import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140C24),
        elevation: 0,
        title: const Text("Privacy Policy & Security Guarantee", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "NUKEZERO SHIELD PRIVACY PRINCIPLES",
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
            ),
            const SizedBox(height: 16),
            _buildSection(
              "1. Explicit User-Triggered Scanning",
              "NUKEZERO Shield operates on an on-demand basis. Screen analysis and text extraction are executed strictly when you explicitly tap or long-press the floating security bubble. The app does NOT continuously record or monitor your screen in the background.",
            ),
            _buildSection(
              "2. Zero Sensitive Credentials Collection",
              "The application automatically filters out passwords, OTPs, credit card tokens, and banking credentials. No sensitive private content is uploaded or stored.",
            ),
            _buildSection(
              "3. Data Minimization & Local Processing",
              "Local heuristic rules, typosquatting checks, and URL parsing are executed directly on your device. Only extracted URL strings or hashes are queried against threat intelligence services.",
            ),
            _buildSection(
              "4. Encrypted Local History Storage",
              "Your scan history is stored in an encrypted local database on your device. You maintain 100% control to view, filter, or clear your history logs at any time.",
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF140C24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E1E4E)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF4ADE80), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "NUKEZERO Shield is committed to transparent, policy-compliant Android cybersecurity.",
                      style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
