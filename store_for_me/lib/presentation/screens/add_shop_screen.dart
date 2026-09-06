import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/models/shop_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../providers/shop_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddShopScreen extends ConsumerStatefulWidget {
  final ShopModel? existingShop;

  const AddShopScreen({super.key, this.existingShop});

  @override
  ConsumerState<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends ConsumerState<AddShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _upiController = TextEditingController();
  final _descController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();

  String _selectedCategory = 'Grocery';
  String _businessMode = 'shop'; // 'shop', 'cart', 'service', 'gym'
  bool _isMobileCart = false;
  String _serviceType = 'both'; // 'at_home', 'at_center', 'both'
  double _deliveryRadius = 5.0;
  bool _hasHomeDelivery = true;
  bool _hasSelfPickup = true;
  TimeOfDay _openingTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 21, minute: 0);
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  XFile? _logoFile;
  XFile? _bannerFile;

  bool get _isEditing => widget.existingShop != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final shop = widget.existingShop!;
      _nameController.text = shop.shopName;
      _addressController.text = shop.address;
      _phoneController.text = shop.phone;
      _whatsappController.text = shop.whatsappNumber;
      _upiController.text = shop.upiId;
      _descController.text = shop.description;
      _selectedCategory = shop.category;
      _businessMode = shop.businessType;
      _isMobileCart = shop.isMobile;
      _serviceType = shop.serviceType;
      _deliveryRadius = shop.deliveryRadius;
      _hasHomeDelivery = shop.hasHomeDelivery;
      _hasSelfPickup = shop.hasSelfPickup;

      if (shop.location != null) {
        _latController.text = shop.location!.latitude.toString();
        _lngController.text = shop.location!.longitude.toString();
      }

      if (shop.openingTime.isNotEmpty) {
        final parts = shop.openingTime.split(':');
        if (parts.length == 2) {
          _openingTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts[1]) ?? 0);
        }
      }
      if (shop.closingTime.isNotEmpty) {
        final parts = shop.closingTime.split(':');
        if (parts.length == 2) {
          _closingTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 21, minute: int.tryParse(parts[1]) ?? 0);
        }
      }
    } else {
      _fetchCurrentLocation();
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS Location unavailable. Please enable location permissions.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _latController.text = position.latitude.toStringAsFixed(6);
          _lngController.text = position.longitude.toStringAsFixed(6);
        });

        try {
          final address = await _locationService.getAddressFromCoordinates(
            position.latitude, position.longitude,
          );
          if (address != null && mounted) {
            setState(() => _addressController.text = address);
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Location updated successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _upiController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(bool isOpening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  Future<void> _pickImage({required bool isLogo}) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isLogo ? 512 : 1200,
        maxHeight: isLogo ? 512 : 600,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          if (isLogo) {
            _logoFile = image;
          } else {
            _bannerFile = image;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final map = <String, dynamic>{
        'shopName': _nameController.text.trim(),
        'category': _selectedCategory,
        'description': _descController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': _latController.text.trim(),
        'longitude': _lngController.text.trim(),
        'openingTime': _formatTime(_openingTime),
        'closingTime': _formatTime(_closingTime),
        'phone': _phoneController.text.trim(),
        'whatsappNumber': _whatsappController.text.trim(),
        'upiId': _upiController.text.trim(),
        'businessType': _businessMode,
        'isMobile': _isMobileCart,
        'serviceType': _serviceType,
        'deliveryRadius': _deliveryRadius,
        'hasHomeDelivery': _hasHomeDelivery,
        'hasSelfPickup': _hasSelfPickup,
      };

      if (_logoFile != null) {
        map['logo'] = await MultipartFile.fromFile(_logoFile!.path, filename: _logoFile!.name);
      }
      if (_bannerFile != null) {
        map['banner'] = await MultipartFile.fromFile(_bannerFile!.path, filename: _bannerFile!.name);
      }

      final formData = FormData.fromMap(map);

      if (_isEditing) {
        await ApiService().updateShop(widget.existingShop!.id, formData);
      } else {
        await ApiService().createShop(formData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? '✅ Business updated successfully!'
                : '🎉 Business registered! Opening Business Manager Dashboard...'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // 1. Refresh user profile (upgrades role to 'owner' & updates business count in Riverpod!)
        await ref.read(authProvider.notifier).refreshProfile();

        // 2. Fetch owner shop & business list
        await ref.read(shopProvider.notifier).fetchOwnerShop();
        await ref.read(businessProvider.notifier).fetchBusinesses();

        if (mounted) {
          if (_isEditing) {
            Navigator.pop(context);
          } else {
            // Direct seamless transition into Business Manager Dashboard
            Navigator.pushReplacementNamed(context, '/owner-dashboard');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        if (e is DioException && e.response?.data != null && e.response?.data['requiresSubscription'] == true) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Subscription Limit Reached'),
              content: Text(e.response!.data['message']),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/subscription');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Upgrade Plan', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required String hint,
    required IconData icon,
    required XFile? localFile,
    required String? existingUrl,
    required bool isLogo,
    required double height,
  }) {
    final hasLocal = localFile != null;
    final hasExisting = existingUrl != null && existingUrl.isNotEmpty && !hasLocal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(isLogo: isLogo),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (hasLocal || hasExisting) ? AppColors.primary.withAlpha(80) : AppColors.divider,
                width: (hasLocal || hasExisting) ? 1.5 : 1,
              ),
            ),
            child: hasLocal
                ? _buildImagePreview(Image.file(File(localFile.path), fit: BoxFit.cover))
                : hasExisting
                    ? _buildImagePreview(
                        CachedNetworkImage(
                          imageUrl: AppConstants.getImageUrl(existingUrl),
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => _buildPlaceholderContent(icon, hint),
                        ),
                      )
                    : _buildPlaceholderContent(icon, hint),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(Widget image) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: image,
        ),
        Positioned(
          bottom: 8, right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(150),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Change', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderContent(IconData icon, String hint) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 36, color: AppColors.primary.withAlpha(120)),
        const SizedBox(height: 8),
        Text(
          hint,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Update Business (Business Radar)' : 'Business Radar • Registration Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === SECTION 1: BUSINESS TYPE & CATEGORY SELECTOR ===
              _buildSectionHeader('Step 1: Business Mode & Primary Category', Icons.category_rounded),
              Row(
                children: [
                  Expanded(
                    child: _buildModeCard(
                      id: 'shop',
                      title: 'Retail Shop',
                      subtitle: 'Grocery, Kirana, Stores',
                      icon: Icons.storefront,
                      onTap: () {
                        setState(() {
                          _businessMode = 'shop';
                          _selectedCategory = 'Grocery';
                          _isMobileCart = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModeCard(
                      id: 'cart',
                      title: 'Cart / Stall',
                      subtitle: 'Chai, Sabzi, Vendor',
                      icon: Icons.emoji_food_beverage_outlined,
                      onTap: () {
                        setState(() {
                          _businessMode = 'cart';
                          _selectedCategory = 'Street Carts & Tea Stalls';
                          _isMobileCart = true;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildModeCard(
                      id: 'service',
                      title: 'Service & Repair',
                      subtitle: 'AC Repair, Plumber',
                      icon: Icons.home_repair_service_outlined,
                      onTap: () {
                        setState(() {
                          _businessMode = 'service';
                          _selectedCategory = 'AC & Appliance Repair';
                          _isMobileCart = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModeCard(
                      id: 'gym',
                      title: 'Gym & Fitness',
                      subtitle: 'Gym, Yoga, Salon',
                      icon: Icons.fitness_center_outlined,
                      onTap: () {
                        setState(() {
                          _businessMode = 'gym';
                          _selectedCategory = 'Gyms & Fitness';
                          _isMobileCart = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text('Select Specific Business Category', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: AppConstants.shopCategories
                    .where((c) => c != 'All')
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: const Icon(Icons.sell_outlined, color: AppColors.primary),
                ),
              ),

              // === SECTION 2: BUSINESS IDENTITY ===
              _buildSectionHeader('Step 2: Business Identity & Overview', Icons.business_rounded),
              CustomTextField(
                controller: _nameController,
                label: _businessMode == 'cart'
                    ? 'Stall / Cart Name'
                    : (_businessMode == 'service' ? 'Service Business Name' : 'Business Name'),
                hint: _businessMode == 'cart' ? 'e.g. Gupta Chai & Snacks Stall' : 'e.g. Sharma AC Repair & Service',
                prefixIcon: Icons.store,
                validator: (v) => Validators.validateRequired(v, 'Name'),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _descController,
                label: 'Business Overview & Specialities',
                hint: 'Describe products, pricing, home visits or repair specialities...',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),

              // === SECTION 3: LOCATION & GPS PINNING ===
              _buildSectionHeader('Step 3: Location & GPS Pin', Icons.location_on_rounded),
              CustomTextField(
                controller: _addressController,
                label: _businessMode == 'cart' ? 'Street Spot / Operating Area' : 'Shop Address',
                hint: 'Main Market, Road No. 2, Area Name...',
                prefixIcon: Icons.location_on,
                validator: (v) => Validators.validateRequired(v, 'Address'),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _latController,
                      label: 'Latitude',
                      prefixIcon: Icons.my_location,
                      keyboardType: TextInputType.number,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _lngController,
                      label: 'Longitude',
                      prefixIcon: Icons.my_location,
                      keyboardType: TextInputType.number,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                  icon: _isFetchingLocation
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.gps_fixed),
                  label: Text(_isFetchingLocation ? 'Fetching location...' : 'Pin Current GPS Location'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mobile Cart Switch
              if (_businessMode == 'cart')
                SwitchListTile(
                  value: _isMobileCart,
                  title: const Text('Mobile Vendor / Moving Cart', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Check if your cart moves to different spots daily'),
                  onChanged: (val) => setState(() => _isMobileCart = val),
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),

              // === SECTION 4: CONTACT & DIGITAL PAYMENTS ===
              _buildSectionHeader('Step 4: Contact & Digital Payments', Icons.payments_rounded),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _whatsappController,
                label: 'WhatsApp Business Number (Optional)',
                hint: 'Customer direct order chats...',
                prefixIcon: Icons.chat_bubble_outline,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _upiController,
                label: 'UPI ID for Payments (Optional)',
                hint: 'e.g. 9876543210@paytm',
                prefixIcon: Icons.qr_code_scanner,
              ),
              const SizedBox(height: 16),

              // Delivery Options & Radius
              Text('Delivery & Fulfillment Options',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilterChip(
                      selected: _hasHomeDelivery,
                      label: const Text('Home Delivery'),
                      onSelected: (val) => setState(() => _hasHomeDelivery = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChip(
                      selected: _hasSelfPickup,
                      label: const Text('Self Pickup'),
                      onSelected: (val) => setState(() => _hasSelfPickup = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Radius: ${_deliveryRadius.toStringAsFixed(1)} km',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Slider(
                    value: _deliveryRadius,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    label: '${_deliveryRadius.toStringAsFixed(1)} km',
                    onChanged: (val) => setState(() => _deliveryRadius = val),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),

              // === SECTION 5: OPERATING HOURS & BRANDING ===
              _buildSectionHeader('Step 5: Hours & Photos', Icons.access_time_filled_rounded),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Opening Time', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 14)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectTime(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
                                const SizedBox(width: 8),
                                Text(_formatTime(_openingTime)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Closing Time', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 14)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectTime(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
                                const SizedBox(width: 8),
                                Text(_formatTime(_closingTime)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildImagePicker(
                label: 'Business Banner / Cover Photo',
                hint: 'Tap to add banner photo of shop or cart',
                icon: Icons.panorama_rounded,
                localFile: _bannerFile,
                existingUrl: _isEditing ? widget.existingShop!.banner : null,
                isLogo: false,
                height: 140,
              ),
              const SizedBox(height: 16),

              _buildImagePicker(
                label: 'Business Logo / Profile Photo',
                hint: 'Tap to upload logo or photo',
                icon: Icons.add_a_photo_rounded,
                localFile: _logoFile,
                existingUrl: _isEditing ? widget.existingShop!.logo : null,
                isLogo: true,
                height: 100,
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: _isEditing ? 'Update Business Details' : 'Publish Business Listing',
                icon: _isEditing ? Icons.save : Icons.rocket_launch,
                isLoading: _isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _businessMode == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withAlpha(50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
