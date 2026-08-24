import 'package:flutter/material.dart';
import '../models/hyperlink_scan_result.dart';

class HyperlinkAnalysisScreen extends StatelessWidget {
  final HyperlinkScanResult result;

  const HyperlinkAnalysisScreen({super.key, required this.result});

  Color _getRiskColor() {
    switch (result.riskLevel) {
      case 'MALICIOUS':
        return const Color(0xFFEF4444);
      case 'HIGH':
        return const Color(0xFFF97316);
      case 'SUSPICIOUS':
        return const Color(0xFFF59E0B);
      case 'SAFE':
        return const Color(0xFF4ADE80);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();
    final isExposed = result.actualUrl != "ACTUAL_URL_NOT_EXPOSED";

    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18102B),
        elevation: 0,
        title: const Text("🔗 HYPERLINK ANALYSIS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF18102B),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: riskColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: riskColor.withOpacity(0.15),
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
                  "----------------------------------------\nSECUREBUBBLE AI\n----------------------------------------",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 18),

              const Text("🔗 HYPERLINK ANALYSIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 16),

              _buildField("Visible Text:", result.visibleText, Colors.white),
              const SizedBox(height: 12),

              _buildField(
                "Actual Destination:",
                isExposed ? result.actualUrl : "⚪ NOT AVAILABLE",
                isExposed ? Colors.white : const Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 12),

              if (isExposed) ...[
                _buildField("Final Destination:", result.finalUrl, Colors.white),
                const SizedBox(height: 12),
                _buildField("Domain Match:", result.domainMatch ? "✅ YES" : "❌ NO", result.domainMatch ? const Color(0xFF4ADE80) : const Color(0xFFEF4444)),
                const SizedBox(height: 12),
                _buildField("HTTPS:", result.https ? "✅ YES" : "❌ NO", result.https ? const Color(0xFF4ADE80) : const Color(0xFFF59E0B)),
                const SizedBox(height: 12),
                _buildField("Punycode:", result.punycode ? "⚠️ YES" : "❌ NO", result.punycode ? const Color(0xFFEF4444) : const Color(0xFF4ADE80)),
                const SizedBox(height: 12),
                _buildField("Typosquatting:", result.typosquatting ? "⚠️ POSSIBLE" : "❌ NO", result.typosquatting ? const Color(0xFFF59E0B) : const Color(0xFF4ADE80)),
                const SizedBox(height: 12),
                _buildField("Redirect:", result.redirectDetected ? "⚠️ YES" : "❌ NO", result.redirectDetected ? const Color(0xFFF59E0B) : const Color(0xFF4ADE80)),
                const SizedBox(height: 12),
              ],

              _buildField(
                "Risk:",
                result.riskLevel == 'MALICIOUS'
                    ? "🔴 CRITICAL"
                    : (result.riskLevel == 'HIGH' ? "🔴 HIGH" : (result.riskLevel == 'SUSPICIOUS' ? "🟡 SUSPICIOUS" : "🟢 SAFE")),
                riskColor,
              ),
              const SizedBox(height: 12),

              _buildField("Detection:", result.detectionType, const Color(0xFFA78BFA)),
              const SizedBox(height: 14),

              const Text("Why?", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                "\"${result.reasons.join(' ')}\"",
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 14),
              const Text("Recommendation:", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                !isExposed
                    ? "\"Exercise caution. Do not click unverified links in apps that mask destinations.\""
                    : (result.riskLevel == 'SAFE'
                        ? "\"The displayed link matches the actual destination domain. Safe to proceed with normal caution.\""
                        : "\"Do not open this link or enter credentials. Verify the official site directly in your browser.\""),
                style: TextStyle(color: !isExposed ? const Color(0xFFF59E0B) : (result.riskLevel == 'SAFE' ? const Color(0xFF4ADE80) : const Color(0xFFEF4444)), fontSize: 13, height: 1.4, fontWeight: FontWeight.bold),
              ),

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
                          "Status: ⚠️ ACTUAL DESTINATION NOT EXPOSED\n\"The current application does not expose the hyperlink destination through its UI/accessibility interface.\"",
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
                  label: const Text("DISMISS REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildField(String title, String content, Color contentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          content,
          style: TextStyle(color: contentColor, fontSize: 13.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
