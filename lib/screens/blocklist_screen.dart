import 'package:flutter/material.dart';
import '../services/blocklist_service.dart';

class BlocklistScreen extends StatefulWidget {
  const BlocklistScreen({Key? key}) : super(key: key);

  @override
  State<BlocklistScreen> createState() => _BlocklistScreenState();
}

class _BlocklistScreenState extends State<BlocklistScreen> {
  List<BlockedItem> _blockedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlocklist();
  }

  Future<void> _loadBlocklist() async {
    setState(() => _isLoading = true);
    final items = await BlocklistService.getBlocklist();
    setState(() {
      _blockedItems = items;
      _isLoading = false;
    });
  }

  Future<void> _unblock(String domain) async {
    await BlocklistService.unblockUrl(domain);
    _loadBlocklist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unblocked $domain")),
      );
    }
  }

  Future<void> _clearAll() async {
    await BlocklistService.clearBlocklist();
    _loadBlocklist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cleared all items from Blocklist")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0716),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140C24),
        title: const Text(
          "SecureBubble Blocklist",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_blockedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Color(0xFFEF4444)),
              onPressed: _clearAll,
              tooltip: "Clear Blocklist",
            ),
        ],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : _blockedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shield_outlined, size: 64, color: Color(0xFF9CA3AF)),
                      SizedBox(height: 12),
                      Text(
                        "Your Blocklist is Clean",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "High-risk phishing links blocked by you will appear here.",
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blockedItems.length,
                  itemBuilder: (context, index) {
                    final item = _blockedItems[index];
                    return Card(
                      color: const Color(0xFF140C24),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                      ),
                      child: ListTile(
                        leading: const Text("🔴", style: TextStyle(fontSize: 20)),
                        title: Text(
                          item.domain,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          "Risk: ${item.riskScore}/100 • ${item.threatReason}",
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.lock_open, color: Color(0xFF60A5FA)),
                          onPressed: () => _unblock(item.domain),
                          tooltip: "Unblock",
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
