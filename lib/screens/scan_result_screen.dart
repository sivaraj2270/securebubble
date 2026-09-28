import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import '../models/risk_result.dart';
import '../widgets/risk_card.dart';
import '../widgets/evidence_card.dart';
import '../widgets/tool_status_card.dart';
import 'forensics_screen.dart';
import 'ai_assistant_screen.dart';
import '../services/admin_service.dart';
import '../services/blocklist_service.dart';

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

            const SizedBox(height: 24),

            // Threat Action Panel (Phases 5.1 & 5.2 - Block Domain Integration)
            if (scanResult.riskResult.score >= 60 || scanResult.riskResult.level == RiskLevel.high || scanResult.riskResult.level == RiskLevel.malicious) ...[
              Builder(
                builder: (context) {
                  final targetDomain = scanResult.urlResult?.domain ?? scanResult.domainResult?.domain ?? scanResult.extractedText;
                  final threatSummary = scanResult.aiRecommendation.isNotEmpty ? scanResult.aiRecommendation : scanResult.riskResult.levelLabel;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E102F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "MALICIOUS THREAT DETECTED",
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Domain: ${targetDomain.isEmpty ? 'Target Domain' : targetDomain}",
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Risk Score: ${scanResult.riskResult.score}/100 • Threat: $threatSummary",
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.block_rounded, size: 16, color: Colors.white),
                                label: const Text("BLOCK DOMAIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  if (targetDomain.isEmpty) return;

                                  await BlocklistService.blockUrl(
                                    targetDomain,
                                    scanResult.riskResult.score,
                                    "Blocked via Scan Result Screen",
                                  );
                                  await AdminService().blockDomain(
                                    targetDomain,
                                    reason: "Blocked via Scan Result Screen",
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("🚫 '$targetDomain' blocked system-wide! Cannot open in mobile phone browsers."),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.description_rounded, size: 16, color: Colors.white),
                                label: const Text("VIEW REPORT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF8B5CF6)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ForensicsScreen(scanResult: scanResult)),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF4B5563)),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text("GO BACK", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],



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

