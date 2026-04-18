import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../providers/delivery_partner_provider.dart';
import '../widgets/common_widgets.dart';

class DeliveryPartnerScreen extends ConsumerStatefulWidget {
  const DeliveryPartnerScreen({super.key});

  @override
  ConsumerState<DeliveryPartnerScreen> createState() => _DeliveryPartnerScreenState();
}

class _DeliveryPartnerScreenState extends ConsumerState<DeliveryPartnerScreen> {
  String _selectedVehicle = 'bike';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(deliveryPartnerProvider.notifier).fetchProfile());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryPartnerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Delivery Partner', style: TextStyle(fontWeight: FontWeight.w700))),
      body: state.isLoading
          ? const LoadingIndicator(message: 'Loading...')
          : state.isRegistered
              ? _buildDashboard(state)
              : _buildRegistration(),
    );
  }

  Widget _buildRegistration() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.delivery_dining, color: Colors.white, size: 56),
                const SizedBox(height: 12),
                const Text('Become a Delivery Partner', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Earn ₹200-500/day delivering orders', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14)),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 24),
          const Text('Select Your Vehicle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: ['bicycle', 'bike', 'scooter', 'car', 'auto'].map((v) {
              final isSelected = _selectedVehicle == v;
              final icons = {'bicycle': Icons.pedal_bike, 'bike': Icons.two_wheeler, 'scooter': Icons.electric_scooter, 'car': Icons.directions_car, 'auto': Icons.local_taxi};
              return GestureDetector(
                onTap: () => setState(() => _selectedVehicle = v),
                child: Container(
                  width: 90, height: 80,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withAlpha(15) : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[v] ?? Icons.directions_car, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 28),
                      const SizedBox(height: 4),
                      Text(v[0].toUpperCase() + v.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Benefits
          const Text('Benefits', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          _buildBenefit(Icons.payments, 'Earn up to ₹500/day', 'Get 85% of delivery fee'),
          _buildBenefit(Icons.schedule, 'Flexible hours', 'Work when you want'),
          _buildBenefit(Icons.trending_up, 'Weekly payouts', 'Get paid every week'),
          _buildBenefit(Icons.shield, 'Insurance coverage', 'Protected on every delivery'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await ref.read(deliveryPartnerProvider.notifier).register(_selectedVehicle);
                if (result && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('🎉 Registered! Complete KYC to start.'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  );
                }
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Register Now', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(DeliveryPartnerState state) {
    final partner = state.partner!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Online toggle card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: partner.isOnline
                  ? [AppColors.success, const Color(0xFF059669)]
                  : [const Color(0xFF475569), const Color(0xFF334155)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partner.isOnline ? 'You\'re Online 🟢' : 'You\'re Offline',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(partner.isOnline ? 'Receiving delivery requests' : 'Go online to receive requests',
                      style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Switch(
                  value: partner.isOnline,
                  onChanged: (_) => ref.read(deliveryPartnerProvider.notifier).toggleOnline(),
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white.withAlpha(80),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              _buildStatCard('🚚', '${partner.totalDeliveries}', 'Deliveries'),
              const SizedBox(width: 12),
              _buildStatCard('⭐', partner.rating.toStringAsFixed(1), 'Rating'),
              const SizedBox(width: 12),
              _buildStatCard('💰', '₹${partner.earningsBalance.toInt()}', 'Balance'),
            ],
          ),
          const SizedBox(height: 20),

          // KYC Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: partner.isKYCVerified ? AppColors.success.withAlpha(15) : AppColors.warning.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: partner.isKYCVerified ? AppColors.success.withAlpha(50) : AppColors.warning.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(partner.isKYCVerified ? Icons.verified_user : Icons.pending,
                  color: partner.isKYCVerified ? AppColors.success : AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KYC Status: ${partner.kycStatus.toUpperCase()}',
                        style: TextStyle(fontWeight: FontWeight.w700, color: partner.isKYCVerified ? AppColors.success : AppColors.warning)),
                      if (!partner.isKYCVerified)
                        const Text('Complete KYC to start accepting deliveries', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                if (!partner.isKYCVerified)
                  ElevatedButton(onPressed: () {}, child: const Text('Upload', style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active delivery or available deliveries
          if (partner.hasActiveDelivery) ...[
            const Text('Active Delivery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('You have an active delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(deliveryPartnerProvider.notifier).completeDelivery(partner.activeDeliveryId!),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      child: const Text('Mark as Delivered'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Text('Available Deliveries', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                TextButton(
                  onPressed: () => ref.read(deliveryPartnerProvider.notifier).fetchAvailableDeliveries(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            if (state.availableDeliveries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No deliveries available nearby', style: TextStyle(color: AppColors.textLight))),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }
}
