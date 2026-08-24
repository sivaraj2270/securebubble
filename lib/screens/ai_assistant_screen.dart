import 'package:flutter/material.dart';
import '../models/scan_result.dart';

class AiAssistantScreen extends StatefulWidget {
  final ScanResult scanResult;

  const AiAssistantScreen({super.key, required this.scanResult});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messages.add({
      'sender': 'ai',
      'text': "Hi! I'm your SecureBubble AI Assistant. Ask me anything about this scan's evidence, risk score (${widget.scanResult.riskResult.score}/100), or recommended security actions.",
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _controller.clear();
    });

    final lower = text.toLowerCase();
    String reply = "Based on confirmed evidence, ";

    if (lower.contains('why') || lower.contains('suspicious') || lower.contains('risk')) {
      reply += "this scan received a risk score of ${widget.scanResult.riskResult.score}/100 due to ${widget.scanResult.riskResult.primaryRiskFactors.join(', ')}.";
    } else if (lower.contains('dangerous') || lower.contains('safe')) {
      reply += "the overall classification is ${widget.scanResult.riskResult.levelLabel}. VirusTotal & heuristic rules detected ${widget.scanResult.confirmedEvidence.length} confirmed threat indicators.";
    } else if (lower.contains('do') || lower.contains('action') || lower.contains('recommend')) {
      reply += widget.scanResult.aiRecommendation;
    } else {
      reply += "the target ${widget.scanResult.urlResult?.domain ?? 'payload'} exhibits indicators: ${widget.scanResult.riskResult.primaryRiskFactors.take(2).join(' & ')}.";
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': reply});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18102B),
        elevation: 0,
        title: const Text("AI Security Assistant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Column(
        children: [
          // Pre-set Question Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildChip("Why is this suspicious?"),
                _buildChip("Is this URL dangerous?"),
                _buildChip("What should I do?"),
                _buildChip("Explain in simple language"),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAi = msg['sender'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isAi ? const Color(0xFF18102B) : const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(20),
                      border: isAi ? Border.all(color: const Color(0xFF2E1E4E)) : null,
                    ),
                    child: Text(
                      msg['text']!,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF18102B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Ask AI Assistant...",
                      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF8B5CF6)),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: const Color(0xFF18102B),
        side: const BorderSide(color: Color(0xFF2E1E4E)),
        label: Text(text, style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 12, fontWeight: FontWeight.bold)),
        onPressed: () => _sendMessage(text),
      ),
    );
  }
}
