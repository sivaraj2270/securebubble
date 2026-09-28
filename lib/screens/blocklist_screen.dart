import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/blocklist_service.dart';

class BlocklistScreen extends StatefulWidget {
  const BlocklistScreen({super.key});

  @override
  State<BlocklistScreen> createState() => _BlocklistScreenState();
}

class _BlocklistScreenState extends State<BlocklistScreen> {
  List<BlockedItem> _blockedItems = [];
  bool _isLoading = true;
  final adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _loadBlocklist();
  }

  Future<void> _loadBlocklist() async {
    setState(() => _isLoading = true);

    // Sync all blocked items to native Android DNS Firewall
    await BlocklistService.syncNativeBlocklist();
    
    // 1. Fetch local app blocklist
    final localItems = await BlocklistService.getBlocklist();
    
    // 2. Fetch Technitium DNS blocklist from backend
    final technitiumItems = await adminService.getBlockedDomains();

    final Map<String, BlockedItem> mergedMap = {};

    for (final item in localItems) {
      if (item.domain.isNotEmpty) {
        mergedMap[item.domain.toLowerCase()] = item;
      }
    }

    for (final raw in technitiumItems) {
      final dom = (raw is String ? raw : (raw["domain"] ?? raw["name"] ?? "")).toString().trim().toLowerCase();
      if (dom.isNotEmpty && !mergedMap.containsKey(dom)) {
        mergedMap[dom] = BlockedItem(
          url: dom,
          domain: dom,
          riskScore: 90,
          threatReason: "Technitium DNS Blocklist",
          blockedAt: DateTime.now().toIso8601String(),
        );
      }
    }

    if (mounted) {
      setState(() {
        _blockedItems = mergedMap.values.toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _addBlockDomain(String inputUrl) async {
    final cleanInput = inputUrl.trim();
    if (cleanInput.isEmpty) return;

    final domain = BlocklistService.extractDomain(cleanInput);

    await BlocklistService.blockUrl(cleanInput, 90, "Blocked manually by user");

    await _loadBlocklist();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🚫 '$domain' blocked system-wide! Cannot open in mobile phone browsers."),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _unblock(String domain) async {
    await BlocklistService.unblockUrl(domain);
    await adminService.unblockDomain(domain);
    await _loadBlocklist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unblocked $domain")),
      );
    }
  }

  Future<void> _clearAll() async {
    for (final item in _blockedItems) {
      await adminService.unblockDomain(item.domain);
    }
    await BlocklistService.clearBlocklist();
    await _loadBlocklist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cleared all items from Blocklist")),
      );
    }
  }

  Future<void> _showAddBlockDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF140C24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text("Block Link / Domain", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter domain or URL to block instantly across Technitium DNS and SecureBubble:",
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "e.g. phishing-fakebank.com",
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFF0B0716),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E1E4E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              final input = controller.text.trim();
              if (input.isNotEmpty) {
                Navigator.pop(ctx);
                await _addBlockDomain(input);
              }
            },
            child: const Text("BLOCK NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        backgroundColor: const Color(0xFF140C24),
        title: const Text(
          "SecureBubble Blocklist",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981), size: 22),
            onPressed: _showAddBlockDialog,
            tooltip: "Add Link to Blocklist",
          ),
          if (_blockedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Color(0xFFEF4444)),
              onPressed: _clearAll,
              tooltip: "Clear Blocklist",
            ),
        ],
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFEF4444),
        icon: const Icon(Icons.block_rounded, color: Colors.white),
        label: const Text("BLOCK LINK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAddBlockDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : _blockedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 64, color: Color(0xFF9CA3AF)),
                      const SizedBox(height: 12),
                      const Text(
                        "Your Blocklist is Clean",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Tap '+ BLOCK LINK' to block any malicious domain or URL.",
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        label: const Text("ADD DOMAIN TO BLOCK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: _showAddBlockDialog,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
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
