import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/models/product_model.dart';
import '../../services/api_service.dart';
import '../providers/product_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final ProductModel? existingProduct;

  const AddProductScreen({super.key, this.existingProduct});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _stockController = TextEditingController(text: '10');
  final _durationController = TextEditingController(text: '1 Hour');
  
  String _selectedItemType = 'product'; // 'product' or 'service'
  String _selectedBookingType = 'instant'; // 'instant' or 'appointment'
  
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;

  bool get _isEditing => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final product = widget.existingProduct!;
      _nameController.text = product.name;
      _descController.text = product.description;
      _priceController.text = product.price.toStringAsFixed(0);
      _discountController.text = product.discount.toStringAsFixed(0);
      _stockController.text = product.stock.toString();
      _durationController.text = product.serviceDuration;
      _selectedItemType = product.itemType;
      _selectedBookingType = product.bookingType;
      _existingImageUrls = List.from(product.images);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final totalCurrent = _selectedImages.length + _existingImageUrls.length;
      if (totalCurrent >= 5) return;

      final images = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          final canAdd = 5 - _existingImageUrls.length;
          _selectedImages = [..._selectedImages, ...images].take(canAdd).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final totalCurrent = _selectedImages.length + _existingImageUrls.length;
      if (totalCurrent >= 5) return;

      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take picture: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    final totalCurrent = _selectedImages.length + _existingImageUrls.length;
    if (totalCurrent >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Item Photos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${5 - totalCurrent} more photo(s) allowed',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select multiple photos'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _takePicture();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final map = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': _priceController.text.trim(),
        'discount': _discountController.text.trim(),
        'stock': _selectedItemType == 'service' ? '999' : _stockController.text.trim(),
        'itemType': _selectedItemType,
        'serviceDuration': _durationController.text.trim(),
        'bookingType': _selectedBookingType,
      };

      // Attach new images
      if (_selectedImages.isNotEmpty) {
        final files = <MultipartFile>[];
        for (final file in _selectedImages) {
          files.add(await MultipartFile.fromFile(file.path, filename: file.name));
        }
        map['images'] = files;
      }

      final formData = FormData.fromMap(map);

      if (_isEditing) {
        await ApiService().updateProduct(widget.existingProduct!.id, formData);
      } else {
        await ApiService().addProduct(formData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Item updated successfully!' : 'Item / Service added successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        ref.read(productProvider.notifier).fetchOwnerProducts();
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

  @override
  Widget build(BuildContext context) {
    final totalImages = _existingImageUrls.length + _selectedImages.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Item / Service' : 'Add Item or Service'),
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
              // --- 1. LISTING TYPE SELECTOR (Product vs Service) ---
              Text(
                'Listing Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedItemType = 'product'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedItemType == 'product'
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedItemType == 'product'
                                ? AppColors.primary
                                : Colors.grey.withAlpha(60),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              color: _selectedItemType == 'product' ? Colors.white : AppColors.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Physical Product',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _selectedItemType == 'product' ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            Text(
                              'Goods, Grocery, Food',
                              style: TextStyle(
                                fontSize: 10,
                                color: _selectedItemType == 'product' ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedItemType = 'service'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedItemType == 'service'
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedItemType == 'service'
                                ? AppColors.primary
                                : Colors.grey.withAlpha(60),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.home_repair_service_outlined,
                              color: _selectedItemType == 'service' ? Colors.white : AppColors.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bookable Service',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _selectedItemType == 'service' ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            Text(
                              'AC Repair, Gym, Stall',
                              style: TextStyle(
                                fontSize: 10,
                                color: _selectedItemType == 'service' ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Image upload section
              Text(
                'Photos & Media',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Add up to 5 photos • First photo is the primary cover',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add button
                    if (totalImages < 5)
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(60),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  size: 28, color: AppColors.primary.withAlpha(180)),
                              const SizedBox(height: 4),
                              const Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Existing images
                    ..._existingImageUrls.asMap().entries.map((entry) {
                      final index = entry.key;
                      final url = entry.value;
                      return Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: CachedNetworkImage(
                                imageUrl: AppConstants.getImageUrl(url),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.withAlpha(30),
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                      color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Selected images
                    ..._selectedImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(file.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => _removeNewImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                      color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              CustomTextField(
                controller: _nameController,
                label: _selectedItemType == 'service' ? 'Service Name' : 'Product Name',
                hint: _selectedItemType == 'service'
                    ? 'e.g. AC Deep Cleaning & Servicing'
                    : 'e.g. Fresh Tea Leaves 500g',
                prefixIcon: _selectedItemType == 'service' ? Icons.build : Icons.shopping_bag,
                validator: (v) => Validators.validateRequired(v, 'Name'),
              ),
              const SizedBox(height: 16),

              // Service Duration Field (If Service)
              if (_selectedItemType == 'service') ...[
                CustomTextField(
                  controller: _durationController,
                  label: 'Estimated Service Duration',
                  hint: 'e.g. 45 Mins, 1 Hour, 1 Day',
                  prefixIcon: Icons.timer_outlined,
                ),
                const SizedBox(height: 16),
                const Text('Booking Fulfillment Mode',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Instant Booking'),
                      selected: _selectedBookingType == 'instant',
                      onSelected: (_) => setState(() => _selectedBookingType = 'instant'),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedBookingType == 'instant' ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Slot Appointment'),
                      selected: _selectedBookingType == 'appointment',
                      onSelected: (_) => setState(() => _selectedBookingType = 'appointment'),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedBookingType == 'appointment' ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              CustomTextField(
                controller: _descController,
                label: 'Description & Highlights',
                hint: 'Details, scope of work, warranty, or ingredients...',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      label: _selectedItemType == 'service' ? 'Service Rate (₹)' : 'Price (₹)',
                      prefixIcon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      validator: Validators.validatePrice,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _discountController,
                      label: 'Discount (%)',
                      prefixIcon: Icons.discount,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_selectedItemType == 'product')
                CustomTextField(
                  controller: _stockController,
                  label: 'Available Stock Quantity',
                  prefixIcon: Icons.inventory,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateStock,
                ),

              const SizedBox(height: 32),

              CustomButton(
                text: _isEditing
                    ? 'Update ${_selectedItemType == 'service' ? 'Service' : 'Product'}'
                    : 'Publish ${_selectedItemType == 'service' ? 'Service Listing' : 'Product Listing'}',
                icon: _isEditing ? Icons.save : Icons.add_circle,
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
