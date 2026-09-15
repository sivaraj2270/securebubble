import 'package:flutter/material.dart';

class HighRiskWarningDialog extends StatelessWidget {
  final String url;
  final int riskScore;
  final String threatCategory;
  final VoidCallback onBlock;
  final VoidCallback onAllow;

  const HighRiskWarningDialog({
    Key? key,
    required this.url,
    required this.riskScore,
    required this.threatCategory,
    required this.onBlock,
    required this.onAllow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF140C24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text("🚨", style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text(
                  "HIGH RISK LINK",
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "This destination may be dangerous.",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1535),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E1E4E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Risk Score: $riskScore/100",
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Threat: $threatCategory",
                    style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  const Text("URL:", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                  Text(
                    url,
                    style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Do you want to block this link?",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAllow();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("ALLOW"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onBlock();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("BLOCK", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
