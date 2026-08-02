import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const platform = MethodChannel("securebubble/service");
  bool isBubbleActive = false;
  bool isLoading = false;

  Future<void> _toggleBubble(bool enable) async {
    setState(() => isLoading = true);
    try {
      if (enable) {
        await platform.invokeMethod("startBubble");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Floating Security Assistant Started"),
              backgroundColor: Color(0xFF00E676),
            ),
          );
        }
      } else {
        await platform.invokeMethod("stopBubble");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Protection Disabled"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      setState(() {
        isBubbleActive = enable;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Service Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121824),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4)),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF00E676), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "SecureBubble AI",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: () async {
              await authService.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141C2B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF212E46)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF00E676).withOpacity(0.2),
                    child: Text(
                      (user?.email?.isNotEmpty == true) ? user!.email![0].toUpperCase() : "U",
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "AUTHENTICATED USER",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Color(0xFF7A8B9E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? "User Account",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFF00E676), size: 8),
                        SizedBox(width: 6),
                        Text(
                          "ONLINE",
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Main Hero Radar Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isBubbleActive
                      ? [const Color(0xFF0D2818), const Color(0xFF141C2B)]
                      : [const Color(0xFF281014), const Color(0xFF141C2B)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isBubbleActive ? const Color(0xFF00E676) : Colors.redAccent.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isBubbleActive ? const Color(0xFF00E676) : Colors.redAccent).withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Animated Pulsing Circle Icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isBubbleActive ? const Color(0xFF00E676) : Colors.redAccent).withOpacity(0.1),
                        ),
                      ),
                      Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isBubbleActive ? const Color(0xFF00E676) : Colors.redAccent).withOpacity(0.2),
                        ),
                        child: Icon(
                          isBubbleActive ? Icons.security_rounded : Icons.shield_outlined,
                          size: 45,
                          color: isBubbleActive ? const Color(0xFF00E676) : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    isBubbleActive ? "PROTECTION ACTIVE" : "PROTECTION INACTIVE",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isBubbleActive ? const Color(0xFF00E676) : Colors.redAccent,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    isBubbleActive
                        ? "Floating shield assistant is running. Tap the bubble anytime on WhatsApp, Telegram, or Chrome to scan."
                        : "Tap the toggle below to activate the floating overlay and real-time screen scan protection.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9AAEC4),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Toggle Switch Button
                  InkWell(
                    onTap: isLoading ? null : () => _toggleBubble(!isBubbleActive),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isBubbleActive ? const Color(0xFF00E676) : Colors.redAccent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isBubbleActive ? const Color(0xFF00E676) : Colors.redAccent).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoading) ...[
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                            ),
                            const SizedBox(width: 12),
                          ] else ...[
                            Icon(
                              isBubbleActive ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                              color: isBubbleActive ? Colors.black : Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            isBubbleActive ? "DISABLE ASSISTANT BUBBLE" : "ACTIVATE ASSISTANT BUBBLE",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isBubbleActive ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Threat Metrics Section Header
            const Text(
              "Security Analytics Overview",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 12),

            // Analytics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: "Total Scans",
                    value: "14",
                    icon: Icons.radar_rounded,
                    color: const Color(0xFF00B0FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: "Safe Checks",
                    value: "12",
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF00E676),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: "Threats Caught",
                    value: "2",
                    icon: Icons.warning_amber_rounded,
                    color: Colors.amberAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: "AI Status",
                    value: "Active",
                    icon: Icons.auto_awesome_rounded,
                    color: Colors.purpleAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // System Permissions Checklist
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141C2B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF212E46)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Color(0xFF7A8B9E), size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Android Security Permissions",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildPermissionRow("Draw Over Other Apps (Overlay)", true),
                  _buildPermissionRow("Screen Capture API (MediaProjection)", true),
                  _buildPermissionRow("Foreground Package Tracker (Accessibility)", true),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF212E46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A8B9E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String title, bool isGranted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            color: isGranted ? const Color(0xFF00E676) : Colors.amber,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isGranted ? Colors.white70 : const Color(0xFF7A8B9E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}