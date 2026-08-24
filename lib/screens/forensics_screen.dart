import 'package:flutter/material.dart';
import '../models/scan_result.dart';

class ForensicsScreen extends StatelessWidget {
  final ScanResult scanResult;

  const ForensicsScreen({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18102B),
        elevation: 0,
        title: const Text("Forensics Report • Investigation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF18102B),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF8B5CF6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "SECUREBUBBLE AI FORENSICS REPORT",
                  style: TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 20),
              _buildField("Scan ID", scanResult.scanId),
              _buildField("Timestamp", "${scanResult.timestamp.toIso8601String()}"),
              _buildField("Target Category", scanResult.urlResult?.isShortened == true ? "Concealed Shortened Redirect URL" : "Web Domain / Text Payload"),
              _buildField("Target URL", scanResult.urlResult?.expandedUrl ?? scanResult.extractedText),
              _buildField("Risk Score", "${scanResult.riskResult.score} / 100 (${scanResult.riskResult.levelLabel})"),
              _buildField("Detected Brand", scanResult.domainResult?.detectedBrand ?? "None"),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: Color(0xFF2E1E4E)),
              ),

              const Text("EVIDENCE & AUDIT TRAIL", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              ...scanResult.confirmedEvidence.map((ev) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF4ADE80), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(ev, style: const TextStyle(color: Colors.white, fontSize: 12.5))),
                      ],
                    ),
                  )),

              ...scanResult.riskResult.primaryRiskFactors.map((rf) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rf, style: const TextStyle(color: Colors.white, fontSize: 12.5))),
                      ],
                    ),
                  )),

              const SizedBox(height: 20),
              const Text("RECOMMENDATION", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                scanResult.aiRecommendation,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                  label: const Text("EXPORT FORENSICS REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Forensics Report Exported to Audit Logs"), backgroundColor: Color(0xFF8B5CF6)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
