import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final _inputController = TextEditingController();
  final _api = ApiService();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  double _totalEstimate = 0;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('AI Shopping Assistant', style: TextStyle(fontWeight: FontWeight.w700))),
      body: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 36)),
                SizedBox(height: 8),
                const Text('Smart Shopping Planner', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Enter items to find the cheapest shops', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms),

          // Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'e.g., milk 1L, bread, eggs',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _search,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20)),
                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Find'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Total estimate
          if (_totalEstimate > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Best estimate: ₹${_totalEstimate.toInt()} across nearby shops', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.success))),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

          // Results
          Expanded(
            child: _results.isEmpty
                ? Center(child: Text(_isLoading ? '' : 'Enter items above to get started', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final itemName = item['item'] ?? '';
                      final options = item['options'] as List? ?? [];
                      final cheapest = item['cheapest'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 20, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text(itemName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  const Spacer(),
                                  if (cheapest != null)
                                    Text('Best: ₹${cheapest['price'] ?? 0}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success, fontSize: 14)),
                                ],
                              ),
                              if (cheapest != null) ...[
                                const SizedBox(height: 4),
                                Text('at ${cheapest['shop'] ?? 'nearby shop'}', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                              ],
                              if (options.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ...options.take(3).map((opt) {
                                  final shop = opt['shop'];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(shop?['shopName'] ?? shop?.toString() ?? '', style: const TextStyle(fontSize: 13))),
                                        Text('₹${opt['price'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              if (options.isEmpty) ...[
                                SizedBox(height: 8),
                                Text('Not found nearby', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
                              ],
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (100 * index).ms);
                    },
                  ),
          ),

          // Quick suggestions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: ['milk, bread, eggs', 'rice 5kg, dal, oil', 'toothpaste, soap, shampoo'].map((s) {
                return GestureDetector(
                  onTap: () {
                    _inputController.text = s;
                    _search();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withAlpha(40)),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _search() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() { _isLoading = true; _results = []; _totalEstimate = 0; });
    try {
      final items = text.split(',').map((e) => {'name': e.trim()}).toList();
      final res = await _api.getShoppingAssistant(items);
      final data = res.data['data'];
      setState(() {
        _results = List<Map<String, dynamic>>.from(data['plan'] ?? []);
        _totalEstimate = (data['totalEstimate'] ?? 0).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}







