import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Delivery Partner', style: TextStyle(fontWeight: FontWeight.w700))),
      body: state.isLoading
          ? const LoadingIndicator(message: 'Loading...')
          : state.isRegistered
              ? _buildDashboard(state)
              : _buildRegistration(state),
    );
  }

  Widget _buildRegistration(DeliveryPartnerState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -50,
                  bottom: -20,
                  child: Opacity(
                    opacity: 0.2,
                    child: Icon(Icons.delivery_dining, size: 250, color: Colors.white),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join Our\nDelivery Fleet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Earn up to ₹15,000/month',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: Image.asset(
                    'assets/images/delivery_partner_hero.png',
                    height: 180,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.delivery_dining, size: 100, color: Colors.white),
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.2),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Your Vehicle', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['bicycle', 'bike', 'scooter', 'car', 'auto'].map((v) {
                      final isSelected = _selectedVehicle == v;
                      final icons = {
                        'bicycle': Icons.pedal_bike_rounded,
                        'bike': Icons.two_wheeler_rounded,
                        'scooter': Icons.electric_scooter_rounded,
                        'car': Icons.directions_car_rounded,
                        'auto': Icons.local_taxi_rounded
                      };
                      return GestureDetector(
                        onTap: () => setState(() => _selectedVehicle = v),
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: 1.5),
                            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))] : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icons[v] ?? Icons.directions_car, color: isSelected ? Colors.white : AppColors.textSecondary, size: 32),
                              const SizedBox(height: 6),
                              Text(
                                v[0].toUpperCase() + v.substring(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 32),
                
                Text('Partner Benefits', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 16),
                _buildBenefit(Icons.account_balance_wallet_rounded, 'Competitive Earnings', 'Get 85% of delivery fee + tips'),
                _buildBenefit(Icons.history_toggle_off_rounded, 'Flexible Schedule', 'Be your own boss, work when you want'),
                _buildBenefit(Icons.electric_bolt_rounded, 'Instant Payouts', 'Withdraw your earnings every week'),
                _buildBenefit(Icons.security_rounded, 'Partner Insurance', 'Full coverage during delivery hours'),
                
                const SizedBox(height: 32),

                if (state.error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        '⚠️ ${state.error}',
                        style: TextStyle(color: AppColors.error.withAlpha(200), fontSize: 13, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ).animate().fadeIn(),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : () async {
                      final result = await ref.read(deliveryPartnerProvider.notifier).register(_selectedVehicle);
                      if (result && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('🎉 Welcome Aboard! Complete KYC to start.'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      shadowColor: AppColors.primary.withAlpha(100),
                    ),
                    child: state.isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Register Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ).animate().slideY(begin: 0.2, duration: 400.ms),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(DeliveryPartnerState state) {
    final partner = state.partner!;
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(deliveryPartnerProvider.notifier).fetchProfile();
        await ref.read(deliveryPartnerProvider.notifier).fetchAvailableDeliveries();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Online toggle card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: partner.isOnline
                      ? [AppColors.success, const Color(0xFF059669)]
                      : [const Color(0xFF475569), const Color(0xFF334155)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (partner.isOnline ? AppColors.success : (Colors.black) ?? Colors.transparent).withAlpha(40),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      partner.isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner.isOnline ? 'You\'re Online' : 'You\'re Offline',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          partner.isOnline ? 'Waiting for nearby requests' : 'Go online to receive orders',
                          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: partner.isOnline,
                    onChanged: (val) async {
                      if (!partner.isKYCVerified && val) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Complete KYC to go online')),
                        );
                        return;
                      }
                      final error = await ref.read(deliveryPartnerProvider.notifier).toggleOnline();
                      if (error != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white.withAlpha(100),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            // Statistics Grid (7 Cards)
            const Text('Performance Stats', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('🚀', '${partner.activeDeliveries.length}', 'Accepted (Active)', color: AppColors.primary),
                _buildStatCard('✅', '${partner.totalDeliveries}', 'Total Delivered', color: AppColors.success),
                _buildStatCard('📋', '${partner.totalAcceptedRequests}', 'Total Accepted', color: Colors.blue),
                _buildStatCard('💰', '₹${partner.totalEarnings.toInt()}', 'Total Earning', color: Colors.orange),
                _buildStatCard('📅', '₹${partner.todayEarnings.toInt()}', 'Today Earning', color: Colors.amber),
                _buildStatCard('❌', '${partner.missedRequests}', 'Missed Request', color: Colors.purple),
                _buildStatCard('⚠️', '${partner.failedOrders}', 'Failed Order', color: AppColors.error),
              ],
            ),
            const SizedBox(height: 24),

            // KYC Status
            if (!partner.isKYCVerified)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: partner.kycStatus == 'submitted' ? Colors.blue.withAlpha(15) : AppColors.warning.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: partner.kycStatus == 'submitted' ? Colors.blue.withAlpha(50) : AppColors.warning.withAlpha(50),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      partner.kycStatus == 'submitted' ? Icons.hourglass_top_rounded : Icons.error_outline_rounded,
                      color: partner.kycStatus == 'submitted' ? Colors.blue : AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner.kycStatus == 'submitted' ? 'KYC Under Review' : 'KYC Pending',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: partner.kycStatus == 'submitted' ? Colors.blue : AppColors.warning,
                            ),
                          ),
                          Text(
                            partner.kycStatus == 'submitted' 
                              ? 'We are verifying your documents.' 
                              : 'Upload documents to start earnings.',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (partner.kycStatus != 'verified')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton(
                                onPressed: () => ref.read(deliveryPartnerProvider.notifier).verifySelf(),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('⚡ Quick Verify (Testing Only)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (partner.kycStatus == 'pending')
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/delivery-partner/kyc'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Complete', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                  ],
                ),
              ),

            // Delivery Sections
            if (partner.hasActiveDelivery) ...[
              Row(
                children: [
                  const Text('Active Deliveries', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text('${state.activeDeliveries.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.activeDeliveries.length,
                itemBuilder: (context, index) {
                  final delivery = state.activeDeliveries[index];
                  final deliveryId = delivery['_id'];
                  return _buildDeliveryCard(deliveryId, isActive: true, delivery: delivery);
                },
              ),
            ],

            SizedBox(height: 8),
            Row(
              children: [
                const Text('Available Nearby', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => ref.read(deliveryPartnerProvider.notifier).fetchAvailableDeliveries(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            if (state.availableDeliveries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.map_outlined, color: (Theme.of(context).textTheme.bodySmall?.color ?? (Colors.grey) ?? Colors.transparent).withAlpha(100), size: 48),
                    SizedBox(height: 12),
                    Text('No deliveries available nearby', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                    Text('Try moving to a busier area', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.availableDeliveries.length,
                itemBuilder: (context, index) {
                  final delivery = state.availableDeliveries[index];
                  return _buildDeliveryCard(delivery['_id'], delivery: delivery);
                },
              ),
            
            const SizedBox(height: 100), // Spacing for bottom navbar
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (color ?? Colors.transparent).withAlpha(30), width: 1.5),
        boxShadow: [
          BoxShadow(color: (color ?? Colors.transparent).withAlpha(10), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(String deliveryId, {bool isActive = false, dynamic delivery}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isActive ? AppColors.primary.withAlpha(50) : AppColors.divider),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.primary : (AppColors.accent) ?? Colors.transparent).withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(isActive ? Icons.directions_bike : Icons.shopping_bag_outlined, 
                    color: isActive ? AppColors.primary : AppColors.accent, size: 24),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery != null ? (delivery['shopId']?['shopName'] ?? 'New Request') : 'Active Order',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        delivery != null ? (delivery['deliveryAddress'] ?? 'Address Hidden') : 'ID: ${deliveryId.substring(0, 8)}...',
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${((delivery?['deliveryFee'] ?? 40) * 0.85).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                      Text('You earn', style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor.withAlpha(50)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (!isActive) ...[
                  Icon(Icons.location_on, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                  SizedBox(width: 4),
                  Text('2.4 km away', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
                const Spacer(),
                if (isActive)
                  ElevatedButton(
                    onPressed: () {
                      debugPrint('--- NAVIGATION START ---');
                      debugPrint('Target: /delivery-order-details');
                      debugPrint('Delivery ID: ${delivery?['_id']}');
                      if (delivery == null) {
                        debugPrint('ERROR: delivery object is NULL');
                      } else {
                        Navigator.pushNamed(context, '/delivery-order-details', arguments: delivery);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (delivery?['status'] == 'out_for_delivery' || delivery?['status'] == 'picked_up') ? AppColors.success : AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      (delivery?['status'] == 'out_for_delivery' || delivery?['status'] == 'picked_up') ? 'Deliver to Customer' : 'Pickup Order', 
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      final error = await ref.read(deliveryPartnerProvider.notifier).acceptDelivery(deliveryId);
                      if (error != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error), backgroundColor: AppColors.error),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionSheet(String deliveryId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompletionBottomSheet(deliveryId: deliveryId),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
                SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionBottomSheet extends ConsumerStatefulWidget {
  final String deliveryId;
  const _CompletionBottomSheet({required this.deliveryId});

  @override
  ConsumerState<_CompletionBottomSheet> createState() => _CompletionBottomSheetState();
}

class _CompletionBottomSheetState extends ConsumerState<_CompletionBottomSheet> {
  final TextEditingController _otpController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _proofImage;
  bool _isCompleting = false;

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 60);
    if (image != null) setState(() => _proofImage = File(image.path));
  }

  Future<void> _complete() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter 6-digit OTP')));
      return;
    }
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Take a photo of the delivery proof')));
      return;
    }

    setState(() => _isCompleting = true);
    
    try {
      final formData = FormData.fromMap({
        'otp': _otpController.text,
        'images': [
          await MultipartFile.fromFile(_proofImage!.path, filename: 'proof.jpg'),
        ],
      });

      final success = await ref.read(deliveryPartnerProvider.notifier).completeDelivery(widget.deliveryId, formData);
      
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delivery Completed Successfully!'), backgroundColor: AppColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification failed. Please check OTP.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Completion Error: $e');
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24, left: 24, right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 24),
          const Text('Verification Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Enter the 6-digit OTP from the customer and take a proof photo.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
          const SizedBox(height: 24),
          
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0 0 0 0 0 0',
              hintStyle: const TextStyle(letterSpacing: 8),
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 12),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.none),
                image: _proofImage != null ? DecorationImage(image: FileImage(_proofImage!), fit: BoxFit.cover) : null,
              ),
              child: _proofImage == null 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 32),
                      SizedBox(height: 8),
                      Text('Take Proof Photo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  )
                : null,
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCompleting ? null : _complete,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isCompleting 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirm Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}












