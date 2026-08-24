import 'package:flutter/material.dart';
import '../models/risk_result.dart';

class RiskCard extends StatelessWidget {
  final RiskResult riskResult;

  const RiskCard({super.key, required this.riskResult});

  Color _getRiskColor() {
    switch (riskResult.level) {
      case RiskLevel.malicious:
        return const Color(0xFFEF4444);
      case RiskLevel.high:
        return const Color(0xFFF97316);
      case RiskLevel.suspicious:
        return const Color(0xFFF59E0B);
      case RiskLevel.low:
        return const Color(0xFF4ADE80);
      case RiskLevel.unknown:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18102B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color),
                ),
                child: Text(
                  riskResult.levelLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${riskResult.score}",
                      style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                    const TextSpan(
                      text: " / 100",
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "MULTI-ENGINE RISK BREAKDOWN",
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          _buildScoreBar("Threat Intelligence (VirusTotal)", riskResult.threatIntelScore, 30, const Color(0xFF8B5CF6)),
          _buildScoreBar("URL Reputation (Safe Browsing)", riskResult.urlReputationScore, 20, const Color(0xFF3B82F6)),
          _buildScoreBar("Domain & urlscan.io Signals", riskResult.domainSignalsScore, 15, const Color(0xFF06B6D4)),
          _buildScoreBar("Brand Impersonation Target", riskResult.brandImpersonationScore, 15, const Color(0xFFEC4899)),
          _buildScoreBar("Phishing & Local Heuristics", riskResult.phishingIndicatorsScore, 10, const Color(0xFFF59E0B)),
          _buildScoreBar("OCR Scam Pattern Signals", riskResult.ocrScamSignalsScore, 10, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int score, int maxScore, Color color) {
    final pct = (score / maxScore).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              Text("$score/$maxScore", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: const Color(0xFF130C25),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
