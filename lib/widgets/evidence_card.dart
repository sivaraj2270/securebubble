import 'package:flutter/material.dart';

class EvidenceCard extends StatelessWidget {
  final List<String> confirmedEvidence;
  final List<String> heuristicFindings;
  final String aiSummary;
  final String aiRecommendation;

  const EvidenceCard({
    super.key,
    required this.confirmedEvidence,
    required this.heuristicFindings,
    required this.aiSummary,
    required this.aiRecommendation,
  });

  @override
  Widget build(BuildContext context) {
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
          const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Color(0xFFA78BFA), size: 20),
              SizedBox(width: 8),
              Text(
                "CONFIRMED THREAT EVIDENCE",
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (confirmedEvidence.isEmpty && heuristicFindings.isEmpty)
            const Text(
              "✔ No malicious indicators or threat evidence detected.",
              style: TextStyle(color: Color(0xFF4ADE80), fontSize: 13, fontWeight: FontWeight.w600),
            )
          else ...[
            ...confirmedEvidence.map((ev) => _buildItem(ev, Colors.redAccent)),
            ...heuristicFindings.map((hf) => _buildItem(hf, Colors.orangeAccent)),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0xFF2E1E4E)),
          ),

          const Row(
            children: [
              Icon(Icons.psychology_rounded, color: Color(0xFF06B6D4), size: 20),
              SizedBox(width: 8),
              Text(
                "AI SECURITY ANALYST SUMMARY",
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            aiSummary,
            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13, height: 1.5),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF130C25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E1E4E)),
            ),
            child: Text(
              aiRecommendation,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
