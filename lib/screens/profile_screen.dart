import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/page_routes.dart';
import 'auth_gate.dart';
import 'analytics_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final authService = AuthService();

  bool pushNotifications = true;
  bool autoStartOnBoot = true;
  bool cloudSyncEnabled = true;

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? "siva3497kinglanden@gmail.com";
    final username = email.split('@')[0];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18102B),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "User Profile & Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF18102B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2E1E4E)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                    child: Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFA78BFA),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF8B5CF6)),
                    ),
                    child: const Text(
                      "⭐ PRO 360 SUBSCRIPTION ACTIVE",
                      style: TextStyle(
                        color: Color(0xFFA78BFA),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Personal Threat Profile Shortcut Tile
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18102B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
              ),
              child: ListTile(
                leading: const Icon(Icons.bar_chart_rounded, color: Color(0xFFA78BFA), size: 26),
                title: const Text("Personal Threat Profile & Data", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                subtitle: const Text("327 Scans • 41 Threats • Privacy Managed", style: TextStyle(fontSize: 12, color: Color(0xFF4ADE80))),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFA78BFA)),
                onTap: () {
                  Navigator.push(context, SmoothPageRoute(page: const AnalyticsScreen()));
                },
              ),
            ),

            const SizedBox(height: 24),

            // Settings Group
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18102B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2E1E4E)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: const Color(0xFF8B5CF6),
                    title: const Text("Push Security Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    subtitle: const Text("Receive instant threat notifications", style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    value: pushNotifications,
                    onChanged: (val) => setState(() => pushNotifications = val),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFF2E1E4E)),
                  SwitchListTile(
                    activeColor: const Color(0xFF8B5CF6),
                    title: const Text("Auto-Start Floating Bubble", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    subtitle: const Text("Launch overlay assistant on device boot", style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    value: autoStartOnBoot,
                    onChanged: (val) => setState(() => autoStartOnBoot = val),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFF2E1E4E)),
                  SwitchListTile(
                    activeColor: const Color(0xFF8B5CF6),
                    title: const Text("Cloud Intelligence Sync", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    subtitle: const Text("Sync scan history with Web Console", style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                    value: cloudSyncEnabled,
                    onChanged: (val) => setState(() => cloudSyncEnabled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // API & Info Section
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18102B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2E1E4E)),
              ),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.key_rounded, color: Color(0xFFA78BFA)),
                    title: Text("VirusTotal API v3 Engine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    subtitle: Text("Cloud Engine • Active & Connected", style: TextStyle(fontSize: 12, color: Color(0xFF4ADE80))),
                    trailing: Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 18),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFF2E1E4E)),
                  const ListTile(
                    leading: Icon(Icons.security_rounded, color: Color(0xFFA78BFA)),
                    title: Text("App Version", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    subtitle: Text("v2.7.0 (Personal Threat Profile Build)", style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                label: const Text("LOGOUT ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () async {
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthGate()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
