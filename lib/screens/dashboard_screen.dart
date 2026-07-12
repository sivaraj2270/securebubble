import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const platform = MethodChannel("securebubble/service");

  Future<void> startBubble(BuildContext context) async {
    try {
      await platform.invokeMethod("startBubble");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bubble Started"),
        ),
      );
    } catch (e) {
      print("Start Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error : $e"),
        ),
      );
    }
  }

  Future<void> stopBubble(BuildContext context) async {
    try {
      await platform.invokeMethod("stopBubble");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bubble Stopped"),
        ),
      );
    } catch (e) {
      print("Stop Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error : $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "SecureBubble AI",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF161B22),
              child: Icon(
                Icons.security,
                size: 70,
                color: Colors.greenAccent,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Protection OFF",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              color: const Color(0xFF161B22),
              child: ListTile(
                leading: const Icon(
                  Icons.person,
                  color: Colors.greenAccent,
                ),
                title: const Text(
                  "Logged In User",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  user?.email ?? "Unknown User",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: () {
                startBubble(context);
              },
              icon: const Icon(Icons.bubble_chart),
              label: const Text("Enable Bubble"),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: () {
                stopBubble(context);
              },
              icon: const Icon(Icons.close),
              label: const Text("Disable Bubble"),
            ),
          ],
        ),
      ),
    );
  }
}