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
  final _descController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();

  String _selectedCategory = 'Grocery';
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
      _descController.text = shop.description;
      _selectedCategory = shop.category;

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
      // Auto-fetch GPS location for new shops
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
              content: Text('Could not get location. Please enable GPS and grant location permission.'),
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

        // Reverse geocode to get address
        try {
          final address = await _locationService.getAddressFromCoordinates(
            position.latitude, position.longitude,
          );
          if (address != null && mounted) {
            setState(() => _addressController.text = address);
          }
        } catch (_) {
          // Reverse geocoding failed, but coordinates are still updated
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully!'),
              backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
            content: Text(_isEditing ? 'Shop updated successfully!' : 'Shop created successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        ref.read(shopProvider.notifier).fetchOwnerShop();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                          placeholder: (_, __) => Container(color: AppColors.shimmerBase),
                          errorWidget: (_, __, ___) => _buildPlaceholderContent(icon, hint),
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
          bottom: 8,
          right: 8,
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
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Update Shop' : 'Register Shop'),
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
              // Banner image upload
              _buildImagePicker(
                label: 'Shop Banner',
                hint: 'Tap to add a banner image',
                icon: Icons.panorama_rounded,
                localFile: _bannerFile,
                existingUrl: _isEditing ? widget.existingShop!.banner : null,
                isLogo: false,
                height: 150,
              ),
              const SizedBox(height: 16),

              // Logo image upload
              _buildImagePicker(
                label: 'Shop Logo',
                hint: 'Tap to add a logo',
                icon: Icons.add_a_photo_rounded,
                localFile: _logoFile,
                existingUrl: _isEditing ? widget.existingShop!.logo : null,
                isLogo: true,
                height: 110,
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _nameController,
                label: 'Shop Name',
                prefixIcon: Icons.store,
                validator: (v) => Validators.validateRequired(v, 'Shop name'),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              Text('Category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: AppConstants.shopCategories
                    .where((c) => c != 'All')
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _descController,
                label: 'Description',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _addressController,
                label: 'Address',
                prefixIcon: Icons.location_on,
                validator: (v) => Validators.validateRequired(v, 'Address'),
              ),
              const SizedBox(height: 16),

              // Location section
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                  icon: _isFetchingLocation
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.gps_fixed),
                  label: Text(_isFetchingLocation ? 'Fetching location...' : 'Use My Current Location'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 16),

              // Opening hours
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 20, color: AppColors.textSecondary),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 20, color: AppColors.textSecondary),
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
              const SizedBox(height: 32),

              CustomButton(
                text: _isEditing ? 'Update Shop' : 'Register Shop',
                isLoading: _isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
