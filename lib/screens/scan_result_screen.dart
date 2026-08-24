import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import '../widgets/risk_card.dart';
import '../widgets/evidence_card.dart';
import '../widgets/tool_status_card.dart';
import 'forensics_screen.dart';
import 'ai_assistant_screen.dart';

class ScanResultScreen extends StatelessWidget {
  final ScanResult scanResult;

  const ScanResultScreen({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18102B),
        elevation: 0,
        title: Text(
          "Security Report • ${scanResult.scanType}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scanResult.scanId,
                      style: const TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${scanResult.timestamp.day}/${scanResult.timestamp.month}/${scanResult.timestamp.year} ${scanResult.timestamp.hour}:${scanResult.timestamp.minute}",
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18102B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2E1E4E)),
                  ),
                  child: Text(
                    scanResult.scanType,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Risk Gauge Card
            RiskCard(riskResult: scanResult.riskResult),

            const SizedBox(height: 16),

            // Privacy Guard Warning (If Any)
            if (scanResult.privacyAlerts.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: scanResult.privacyAlerts
                      .map((alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              alert,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Evidence Card
            EvidenceCard(
              confirmedEvidence: scanResult.confirmedEvidence,
              heuristicFindings: scanResult.riskResult.primaryRiskFactors,
              aiSummary: scanResult.aiSummary,
              aiRecommendation: scanResult.aiRecommendation,
            ),

            const SizedBox(height: 16),

            // Tool Status Grid Card
            ToolStatusCard(threatResult: scanResult.threatResult),

            const SizedBox(height: 24),

            // Bottom Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.analytics_rounded, size: 18, color: Colors.white),
                    label: const Text("VIEW FORENSICS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18102B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF8B5CF6)),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ForensicsScreen(scanResult: scanResult)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.psychology_rounded, size: 18, color: Colors.white),
                    label: const Text("ASK AI ASSISTANT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AiAssistantScreen(scanResult: scanResult)),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
