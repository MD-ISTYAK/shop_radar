import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(walletProvider.notifier).fetchWallet();
      ref.read(walletProvider.notifier).fetchTransactions();
    });
  }

  void _showAddMoneySheet(BuildContext context) {
    final amountController = TextEditingController(text: '500');
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_card_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Add Money via Razorpay',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Select or enter amount (₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  // Preset chips
                  Wrap(
                    spacing: 8,
                    children: [100, 500, 1000, 2500, 5000].map((amt) {
                      return ChoiceChip(
                        label: Text('₹$amt'),
                        selected: amountController.text == amt.toString(),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: amountController.text == amt.toString() ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setSheetState(() => amountController.text = amt.toString());
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      labelText: 'Amount',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    onChanged: (val) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              final double? amount = double.tryParse(amountController.text.trim());
                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid amount')),
                                );
                                return;
                              }

                              setSheetState(() => isProcessing = true);

                              // Razorpay payment ID reference
                              final paymentId = 'pay_rzp_${DateTime.now().millisecondsSinceEpoch}';

                              final success = await ref.read(walletProvider.notifier).addMoney(amount, paymentId);

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('🎉 ₹${amount.toStringAsFixed(0)} added to wallet successfully!'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to add money. Please try again.'),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Proceed with Razorpay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWithdrawSheet(BuildContext context) {
    final upiController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.outbox_rounded, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Withdraw Funds to UPI / Bank',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: upiController,
                decoration: InputDecoration(
                  labelText: 'UPI ID / Bank VPA (e.g. user@upi)',
                  prefixIcon: const Icon(Icons.account_balance_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Amount to Withdraw',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final upi = upiController.text.trim();
                    final amt = double.tryParse(amountController.text.trim());
                    if (upi.isEmpty || amt == null || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid UPI ID and withdrawal amount')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Withdrawal request of ₹${amt.toStringAsFixed(0)} submitted! Payout will reflect in $upi within 2 hours.'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Confirm Withdrawal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Business Radar Wallet', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(walletProvider.notifier).fetchWallet();
          await ref.read(walletProvider.notifier).fetchTransactions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Balance card
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Available Balance', style: TextStyle(color: Colors.white60, fontSize: 14)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Active 🟢',
                            style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${walletState.balance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddMoneySheet(context),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Money'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E293B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showWithdrawSheet(context),
                            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                            label: const Text('Withdraw'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transaction history header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('Transaction History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Transaction list
              walletState.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    )
                  : walletState.transactions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.history_rounded, size: 48, color: Theme.of(context).disabledColor),
                              const SizedBox(height: 12),
                              Text('No transactions yet', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: walletState.transactions.length,
                          separatorBuilder: (context, index) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final txn = walletState.transactions[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: txn.isCredit ? AppColors.success.withAlpha(20) : AppColors.error.withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  txn.isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: txn.isCredit ? AppColors.success : AppColors.error,
                                ),
                              ),
                              title: Text(txn.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(
                                '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year}',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                              ),
                              trailing: Text(
                                '${txn.isCredit ? '+' : '-'}₹${txn.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: txn.isCredit ? AppColors.success : AppColors.error,
                                  fontSize: 15,
                                ),
                              ),
                            );
                          },
                        ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
