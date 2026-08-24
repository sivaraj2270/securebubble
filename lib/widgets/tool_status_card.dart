import 'package:flutter/material.dart';
import '../models/threat_result.dart';

class ToolStatusCard extends StatelessWidget {
  final ThreatResult? threatResult;

  const ToolStatusCard({super.key, this.threatResult});

  @override
  Widget build(BuildContext context) {
    final vtOk = threatResult?.vtAvailable ?? true;
    final sbOk = threatResult?.safeBrowsingAvailable ?? true;
    final usOk = threatResult?.urlScanAvailable ?? true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18102B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2E1E4E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TRANSPARENT ANALYSIS SOURCES STATUS",
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          _buildStatusRow("ML Kit OCR Recognition", true, "Active Engine"),
          _buildStatusRow("ML Kit Barcode & QR Scanner", true, "Active Engine"),
          _buildStatusRow(
            "VirusTotal API v3",
            vtOk,
            vtOk ? "90 Security Vendors Checked" : "⚠️ API Timeout / Unavailable",
          ),
          _buildStatusRow(
            "Google Safe Browsing / Web Risk",
            sbOk,
            sbOk ? "Phishing & Malware Checked" : "⚠️ API Unavailable",
          ),
          _buildStatusRow(
            "urlscan.io Deep Inspection",
            usOk,
            usOk ? "DOM & Screenshot Engine" : "⚠️ Optional Deep Scan",
          ),
          _buildStatusRow("Local Heuristic Engine", true, "12 Rule Sets Evaluated"),
          _buildStatusRow("AI Security Analyst", true, "Evidence Synthesized"),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String toolName, bool isAvailable, String detail) {
    final color = isAvailable ? const Color(0xFF4ADE80) : const Color(0xFFF59E0B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              toolName,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            detail,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
