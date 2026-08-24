import 'package:flutter/material.dart';
import '../models/hyperlink_result.dart';

class HyperlinkResultScreen extends StatelessWidget {
  final HyperlinkResult result;

  const HyperlinkResultScreen({super.key, required this.result});

  Color _getRiskColor() {
    switch (result.riskLevel) {
      case 'MALICIOUS':
      case 'HIGH':
        return const Color(0xFFEF4444);
      case 'SUSPICIOUS':
        return const Color(0xFFF59E0B);
      case 'LOW':
        return const Color(0xFF4ADE80);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor();
    final isExposed = result.actualUrl != "Not available";

    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18102B),
        elevation: 0,
        title: const Text("Hyperlink Analysis Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF18102B),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "--------------------------------\nSECUREBUBBLE AI\n--------------------------------",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 20),

              _buildBlock("Visible Link", result.visibleText, Colors.white),
              const SizedBox(height: 14),

              _buildBlock("Actual Destination", result.actualUrl, isExposed ? Colors.white : const Color(0xFFF59E0B)),
              const SizedBox(height: 14),

              _buildBlock(
                "Domain Match",
                !isExposed ? "⚠️ NOT EXPOSED" : (result.domainMatch ? "✔ YES" : "❌ NO"),
                !isExposed ? const Color(0xFFF59E0B) : (result.domainMatch ? const Color(0xFF4ADE80) : const Color(0xFFEF4444)),
              ),
              const SizedBox(height: 14),

              _buildBlock("Risk", result.riskLevel == 'HIGH' ? "🔴 HIGH" : (result.riskLevel == 'LOW' ? "🟢 LOW" : "🟡 SUSPICIOUS"), color),
              const SizedBox(height: 14),

              _buildBlock("Detection", result.detectionType, const Color(0xFFA78BFA)),
              const SizedBox(height: 14),

              _buildBlock("Reason", result.reason, const Color(0xFFD1D5DB)),

              if (result.redirects.isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildBlock("Redirect Chain", result.redirects.join(" → "), const Color(0xFF9CA3AF)),
              ],

              const SizedBox(height: 24),

              if (!isExposed) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Status: ⚠️ ACTUAL URL NOT EXPOSED\n\"This application does not expose the hyperlink destination through its UI.\"",
                          style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                  label: const Text("CLOSE REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(String title, String content, Color contentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(color: contentColor, fontSize: 13.5, fontWeight: FontWeight.bold, height: 1.3),
        ),
      ],
    );
  }
}
