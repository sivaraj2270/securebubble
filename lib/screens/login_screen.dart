import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/page_routes.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter email and password"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await authService.loginUser(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        SmoothPageRoute(
          page: const DashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void fillQuickTest() {
    emailController.text = "siva3497kinglanden@gmail.com";
    passwordController.text = "123456";
    login();
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
      backgroundColor: const Color(0xFF0B0716),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // DeepSeek Style Concentric Radar Rings Hero Logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B5CF6).withOpacity(0.06),
                      ),
                    ),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B5CF6).withOpacity(0.12),
                        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2), width: 1.5),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B5CF6).withOpacity(0.2),
                        border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  "Discover Intelligence with",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "SecureBubble Cyber AI",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Real-time VirusTotal API v3 Threat Radar & Phishing Detector",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 32),

                // Dark Slate Violet Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18102B),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF2E1E4E)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Welcome Back",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Let's get started with real-time AI security.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Email Field
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "Email or Username",
                          hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFA78BFA)),
                          filled: true,
                          fillColor: const Color(0xFF130C25),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Color(0xFF2E1E4E)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: passwordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFA78BFA)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFFA78BFA),
                            ),
                            onPressed: () => setState(() => obscurePassword = !obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF130C25),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Color(0xFF2E1E4E)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Neon Violet Login Button (DeepSeek Pill Button Style)
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                            shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5),
                          ),
                          onPressed: isLoading ? null : login,
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  "Login to Protect",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Quick Test Access Button
                      SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.bolt_rounded, color: Color(0xFFA78BFA), size: 20),
                          label: const Text(
                            "Quick Test Access",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E1E4E)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: isLoading ? null : fillQuickTest,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                SmoothPageRoute(
                                  page: const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Color(0xFFA78BFA),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}