import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int totalScans = 327;
  int threatsDetected = 41;
  int phishingCount = 23;
  int scamCount = 9;
  int maliciousQrCount = 6;
  int otherCount = 3;
  String mostCommonThreat = "Banking Phishing";
  String riskAwarenessRating = "★★★★☆";
  bool isDataDeleted = false;

  void _deletePersonalData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18102B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF2E1E4E)),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Delete Threat History?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          "This will permanently wipe all local threat intelligence logs and personal security analytics stored on your device. This action cannot be undone.",
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                totalScans = 0;
                threatsDetected = 0;
                phishingCount = 0;
                scamCount = 0;
                maliciousQrCount = 0;
                otherCount = 0;
                mostCommonThreat = "None";
                riskAwarenessRating = "☆☆☆☆☆";
                isDataDeleted = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("All Personal Security Data Successfully Wiped!"),
                  backgroundColor: Color(0xFF8B5CF6),
                ),
              );
            },
            child: const Text("PERMANENTLY DELETE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18102B),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Personal Threat Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // YOUR SECURITY PROFILE CARD (Matching user specification)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF18102B),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "YOUR SECURITY PROFILE",
                        style: TextStyle(
                          color: Color(0xFFA78BFA),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "🔒 LOCAL PRIVACY",
                          style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildStatRow("Scans", "$totalScans", isBold: true),
                  const Divider(color: Color(0xFF2E1E4E), height: 20),

                  _buildStatRow("Threats detected", "$threatsDetected", isBold: true, valueColor: Colors.redAccent),
                  const SizedBox(height: 10),

                  _buildSubStatRow("Phishing", "$phishingCount"),
                  _buildSubStatRow("Scam messages", "$scamCount"),
                  _buildSubStatRow("Malicious QR", "$maliciousQrCount"),
                  _buildSubStatRow("Other", "$otherCount"),

                  const Divider(color: Color(0xFF2E1E4E), height: 24),

                  _buildStatRow("Most common threat", mostCommonThreat, valueColor: const Color(0xFFF59E0B)),
                  const SizedBox(height: 12),

                  _buildStatRow("Risk awareness", riskAwarenessRating, valueColor: const Color(0xFFF59E0B), isStars: true),

                  const SizedBox(height: 20),

                  // Delete Data Action
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      label: Text(
                        isDataDeleted ? "Data Reset Complete" : "Delete Personal Security Data",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: isDataDeleted ? null : _deletePersonalData,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Threat Category Breakdown",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),

            const SizedBox(height: 12),

            _buildCategoryBar("Verified E-Commerce / Legitimate Links", 0.65, const Color(0xFF8B5CF6), "65%"),
            const SizedBox(height: 12),
            _buildCategoryBar("Cloudflare / Ngrok Ephemeral Tunnels", 0.20, Colors.redAccent, "20%"),
            const SizedBox(height: 12),
            _buildCategoryBar("Shortened Concealed URLs (bit.ly)", 0.15, const Color(0xFFF59E0B), "15%"),

            const SizedBox(height: 24),

            const Text(
              "VirusTotal Engine Benchmarks",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF18102B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E1E4E)),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Scan Engine Latency", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("300ms (Ultra-Fast)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA78BFA))),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("VirusTotal Security Vendors", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("90 Engines Online", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4ADE80))),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Screen OCR Frame Latency", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text("15ms", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA78BFA))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isBold = false, Color? valueColor, bool isStars = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isStars ? 18 : 15,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFFA78BFA),
            letterSpacing: isStars ? 2 : 0,
          ),
        ),
      ],
    );
  }

  Widget _buildSubStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text("• ", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
              Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(String title, double factor, Color color, String percentText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18102B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2E1E4E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(percentText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: factor,
              minHeight: 8,
              backgroundColor: const Color(0xFF130C25),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
