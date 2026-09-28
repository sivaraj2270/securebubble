import 'package:flutter/material.dart';
import '../models/dual_url_scan_result.dart';

class SecurityPopupDialog extends StatelessWidget {
  final DualUrlScanResult scanResult;
  final VoidCallback? onBlockDomain;
  final VoidCallback? onViewReport;
  final VoidCallback? onContinue;

  const SecurityPopupDialog({
    super.key,
    required this.scanResult,
    this.onBlockDomain,
    this.onViewReport,
    this.onContinue,
  });

  Color get _statusColor {
    final classification = scanResult.securebubble.classification.toUpperCase();
    if (classification == 'CRITICAL' || classification == 'HIGH RISK') {
      return const Color(0xFFEF4444); // Danger Red
    } else if (classification == 'SUSPICIOUS') {
      return const Color(0xFFF59E0B); // Amber Warning
    }
    return const Color(0xFF10B981); // Safe Emerald
  }

  IconData get _statusIcon {
    final classification = scanResult.securebubble.classification.toUpperCase();
    if (classification == 'CRITICAL' || classification == 'HIGH RISK') {
      return Icons.gpp_bad_rounded;
    } else if (classification == 'SUSPICIOUS') {
      return Icons.warning_amber_rounded;
    }
    return Icons.verified_user_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDangerous = scanResult.securebubble.riskScore >= 61;
    final isConflict = !scanResult.comparison.agreement;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF111827), // Dark Theme Slate
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Badge
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon, color: _statusColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDangerous
                                ? "🚨 SECUREBUBBLE ALERT"
                                : "🛡️ SECUREBUBBLE VERIFIED",
                            style: TextStyle(
                              color: _statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            scanResult.securebubble.classification,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Domain & Target URL Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scanResult.domain,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scanResult.url,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Dual Security Providers Cards
              Row(
                children: [
                  // VirusTotal Card
                  Expanded(
                    child: _buildProviderCard(
                      title: "VirusTotal",
                      classification: scanResult.virustotal.classification,
                      subtext: scanResult.virustotal.malicious > 0
                          ? "${scanResult.virustotal.malicious}/${scanResult.virustotal.totalEngines} Flagged"
                          : "No detections",
                      isMalicious: scanResult.virustotal.malicious > 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Google Web Risk Card
                  Expanded(
                    child: _buildProviderCard(
                      title: "Google Web Risk",
                      classification: scanResult.googleWebRisk.classification,
                      subtext: scanResult.googleWebRisk.threatTypes.isNotEmpty
                          ? scanResult.googleWebRisk.threatTypes.join(", ")
                          : "No threat match",
                      isMalicious: scanResult.googleWebRisk.threatTypes.isNotEmpty,
                    ),
                  ),
                ],
              ),

              if (isConflict) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF451A03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.compare_arrows_rounded, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          scanResult.comparison.summary,
                          style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // SecureBubble Risk Score Display
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "SecureBubble Risk Score",
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                        ),
                        Text(
                          "${scanResult.securebubble.riskScore} / 100",
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: scanResult.securebubble.riskScore / 100.0,
                      backgroundColor: Colors.black26,
                      color: _statusColor,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isDangerous
                          ? "🛑 The link has NOT been opened."
                          : "🟢 Link verified. Proceed with awareness.",
                      style: TextStyle(
                        color: isDangerous ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  if (isDangerous && onBlockDomain != null) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onBlockDomain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.block_rounded, size: 18),
                        label: const Text("BLOCK DOMAIN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewReport ?? () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4B5563)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("VIEW REPORT", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                  if (!isDangerous) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onContinue ?? () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("CONTINUE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard({
    required String title,
    required String classification,
    required String subtext,
    required bool isMalicious,
  }) {
    final color = isMalicious ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isMalicious ? Icons.cancel_rounded : Icons.check_circle_rounded, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  classification.toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
