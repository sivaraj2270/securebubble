import 'package:flutter/material.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String selectedFilter = "All";
  final searchController = TextEditingController();

  final List<Map<String, String>> activities = [
    {
      "url": "https://swiggy.com/buzzstreaks/oogw",
      "category": "Verified Legitimate Domain",
      "status": "SAFE",
      "vt": "0/90 Flagged",
      "time": "Today, 7:48 PM",
    },
    {
      "url": "https://dpl-unlimited-cubic-carol.trycloudflare.com",
      "category": "Cloudflare Phishing Tunnel",
      "status": "DANGEROUS",
      "vt": "Cloudflare Ephemeral Host",
      "time": "Today, 5:12 PM",
    },
    {
      "url": "http://bit.ly/bank-verify-account-login",
      "category": "Shortened Concealed URL",
      "status": "DANGEROUS",
      "vt": "Unshortened Target Domain",
      "time": "Yesterday, 3:20 PM",
    },
    {
      "url": "https://unstop.com/hackathons/cyber-challenge",
      "category": "Verified Safe Domain",
      "status": "SAFE",
      "vt": "0/90 Flagged",
      "time": "Yesterday, 11:05 AM",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = activities.where((act) {
      if (selectedFilter == "Safe Checks" && act["status"] != "SAFE") return false;
      if (selectedFilter == "Threats" && act["status"] != "DANGEROUS") return false;
      if (searchController.text.isNotEmpty && !act["url"]!.toLowerCase().contains(searchController.text.toLowerCase())) return false;
      return true;
    }).toList();

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
          "Scan Activity History",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search scan activity URL...",
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA78BFA)),
                filled: true,
                fillColor: const Color(0xFF18102B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF2E1E4E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filter Tabs
            Row(
              children: ["All", "Safe Checks", "Threats"].map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => setState(() => selectedFilter = filter),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF18102B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF2E1E4E),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Items List
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final act = filtered[index];
                  final isSafe = act["status"] == "SAFE";
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18102B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2E1E4E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSafe ? const Color(0xFF8B5CF6).withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                act["status"]!,
                                style: TextStyle(
                                  color: isSafe ? const Color(0xFFA78BFA) : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              act["time"]!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          act["url"]!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA78BFA),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${act['category']} • ${act['vt']}",
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
