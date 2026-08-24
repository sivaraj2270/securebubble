import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final AuthService authService = AuthService();
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await authService.registerUser(
        email: email,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account Created Successfully! Please login."),
          backgroundColor: Color(0xFF8B5CF6),
        ),
      );

      Navigator.pop(context);
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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Text(
                  "Join real-time AI security shield intelligence.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 28),

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
                        "Get Started Free",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Set up your secure credentials in 1 minute.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Full Name Input
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Full Name",
                          hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFA78BFA)),
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

                      const SizedBox(height: 14),

                      // Email Input
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "Email Address",
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

                      const SizedBox(height: 14),

                      // Password Input
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

                      const SizedBox(height: 14),

                      // Confirm Password Input
                      TextField(
                        controller: confirmPasswordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: obscureConfirmPassword,
                        decoration: InputDecoration(
                          hintText: "Confirm Password",
                          hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                          prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFFA78BFA)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFFA78BFA),
                            ),
                            onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
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

                      const SizedBox(height: 24),

                      // Sign Up Button
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
                          ),
                          onPressed: isLoading ? null : register,
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              "Login",
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