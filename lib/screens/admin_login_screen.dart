import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_routes.dart';
import 'admin_dashboard_screen.dart';
import '../widgets/nukezero_logo_widget.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController(text: "admin@gmail.com");
  final passwordController = TextEditingController(text: "tree1010234");
  final adminService = AdminService();

  bool isLoading = false;
  bool obscurePassword = true;
  String? connectionErrorMessage;

  Future<void> handleAdminLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter admin email and password"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      connectionErrorMessage = null;
    });

    final result = await adminService.adminLogin(email, password);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result["success"] == true) {
      final isOffline = result["is_offline"] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "Admin Local/Offline Mode Active. Admin Portal Opened."
                : "Admin Authentication Successful! Access Granted.",
          ),
          backgroundColor: isOffline ? Colors.orangeAccent : const Color(0xFF10B981),
        ),
      );

      Navigator.pushReplacement(
        context,
        SmoothPageRoute(page: const AdminDashboardScreen()),
      );
    } else {
      setState(() {
        connectionErrorMessage = result["message"];
      });
    }
  }

  Future<void> _showServerSettingsDialog() async {
    final urlController = TextEditingController(text: adminService.baseUrl);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: Color(0xFF2563EB), size: 22),
            SizedBox(width: 8),
            Text("Backend Host URL", style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Set the IP address of your Windows PC running FastAPI backend:",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5),
              decoration: InputDecoration(
                hintText: "http://10.76.108.11:8000",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2563EB)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text("Quick Presets:", style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text("PC Wi-Fi (10.76.108.11)", style: TextStyle(fontSize: 11, color: Color(0xFF0F172A))),
                  selected: urlController.text.contains("10.76.108.11"),
                  selectedColor: const Color(0xFFDBEAFE),
                  backgroundColor: const Color(0xFFF1F5F9),
                  onSelected: (_) => setState(() => urlController.text = "http://10.76.108.11:8000"),
                ),
                ChoiceChip(
                  label: const Text("Emulator (10.0.2.2)", style: TextStyle(fontSize: 11, color: Color(0xFF0F172A))),
                  selected: urlController.text.contains("10.0.2.2"),
                  selectedColor: const Color(0xFFDBEAFE),
                  backgroundColor: const Color(0xFFF1F5F9),
                  onSelected: (_) => setState(() => urlController.text = "http://10.0.2.2:8000"),
                ),
                ChoiceChip(
                  label: const Text("Localhost (127.0.0.1)", style: TextStyle(fontSize: 11, color: Color(0xFF0F172A))),
                  selected: urlController.text.contains("127.0.0.1"),
                  selectedColor: const Color(0xFFDBEAFE),
                  backgroundColor: const Color(0xFFF1F5F9),
                  onSelected: (_) => setState(() => urlController.text = "http://127.0.0.1:8000"),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                adminService.setBaseUrl(newUrl);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Backend URL set to: ${adminService.baseUrl}")),
                );
              }
            },
            child: const Text("SAVE URL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Admin Portal Access",
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF2563EB), size: 22),
            onPressed: _showServerSettingsDialog,
            tooltip: "Configure Server Host URL",
          ),
        ],
      ),
      body: ZentraTheme.buildAmbientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // N Logo Circular Badge
                  const Center(
                    child: NukeZeroLogoWidget(size: 68),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "NukeZero Admin Portal",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Technitium DNS Shield Operations",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    "Admin Email",
                    style: TextStyle(color: Color(0xFF334155), fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Enter admin email",
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2563EB)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Admin Password",
                    style: TextStyle(color: Color(0xFF334155), fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Enter admin password",
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF2563EB)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  ZentraTheme.buildPrimaryButton(
                    text: "SIGN IN TO ADMIN PORTAL",
                    isLoading: isLoading,
                    icon: Icons.login_rounded,
                    onPressed: handleAdminLogin,
                  ),

                  if (connectionErrorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text("Connection Error", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            connectionErrorMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _showServerSettingsDialog,
                            child: const Text(
                              "⚙️ Tap here to change Backend Host URL / IP",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
