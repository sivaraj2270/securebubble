import 'package:flutter/material.dart';
import '../services/privacy_guard.dart';

class PrivacyGuardScreen extends StatefulWidget {
  const PrivacyGuardScreen({super.key});

  @override
  State<PrivacyGuardScreen> createState() => _PrivacyGuardScreenState();
}

class _PrivacyGuardScreenState extends State<PrivacyGuardScreen> {
  final TextEditingController _textController = TextEditingController();
  List<String> _alerts = [];

  void _scanPrivacy() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _alerts = PrivacyGuard.scanForSensitiveData(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18102B),
        elevation: 0,
        title: const Text("Privacy Guard • Local PII Scanner", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Local On-Device Privacy Protection",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Scans for Email, Phone Numbers, OTP Passcodes, API Keys, Passwords, and Credit Cards locally. Sensitive data is never sent to external APIs.",
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Paste text or message to scan for PII...",
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFF18102B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF2E1E4E))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _scanPrivacy,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("SCAN FOR SENSITIVE DATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            if (_alerts.isNotEmpty) ...[
              const Text("PRIVACY ALERTS DETECTED", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Text(
                        _alerts[index],
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ] else if (_textController.text.isNotEmpty) ...[
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 20),
                  SizedBox(width: 8),
                  Text("No sensitive PII or secrets detected in scanned text.", style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
