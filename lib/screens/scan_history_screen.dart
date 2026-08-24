import 'package:flutter/material.dart';
import '../services/scan_history_database.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<ScanRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await ScanHistoryDatabase.getScanHistory();
    setState(() {
      _history = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(String id) async {
    await ScanHistoryDatabase.deleteRecord(id);
    _loadHistory();
  }

  Future<void> _clearAll() async {
    await ScanHistoryDatabase.clearAllHistory();
    _loadHistory();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DANGEROUS':
        return const Color(0xFFEF4444);
      case 'SUSPICIOUS':
        return const Color(0xFFF59E0B);
      case 'LOW RISK':
        return const Color(0xFF60A5FA);
      default:
        return const Color(0xFF4ADE80);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140C24),
        elevation: 0,
        title: const Text("Scan History Log", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF140C24),
                    title: const Text("Clear All History?", style: TextStyle(color: Colors.white)),
                    content: const Text("This action will permanently delete all scan records from your device.", style: TextStyle(color: Color(0xFF9CA3AF))),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white))),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearAll();
                        },
                        child: const Text("CLEAR ALL", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : (_history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, color: Color(0xFF9CA3AF), size: 48),
                      SizedBox(height: 12),
                      Text("No Scan History Recorded Yet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text("Scanned links and QR codes will appear here.", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final statusColor = _getStatusColor(item.status);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF140C24),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2E1E4E)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.shield_rounded, color: statusColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.urlOrItem,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year} ${item.timestamp.hour}:${item.timestamp.minute}",
                                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${item.status} (${item.riskScore})",
                                  style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 18),
                                onPressed: () => _deleteItem(item.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                )),
    );
  }
}
