const Product = require('../models/Product');
const Shop = require('../models/Shop');

// @desc    Add a product
// @route   POST /api/products
const addProduct = async (req, res, next) => {
  try {
    const { name, description, price, discount, stock } = req.body;

    // Find owner's shop
    const shop = await Shop.findOne({ ownerId: req.user._id });
    if (!shop) {
      return res.status(404).json({
        success: false,
        message: 'You must register a shop first',
      });
    }

    const productData = {
      shopId: shop._id,
      name,
      description: description || '',
      price: parseFloat(price),
      discount: discount ? parseFloat(discount) : 0,
      stock: parseInt(stock),
    };

    // Handle image uploads (Cloudinary gives full URL in path)
    if (req.files && req.files.length > 0) {
      productData.images = req.files.map((file) => file.path);
    }

    const product = await Product.create(productData);

    res.status(201).json({
      success: true,
      message: 'Product added successfully',
      data: product,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get products by shop
// @route   GET /api/products/shop/:shopId
const getProductsByShop = async (req, res, next) => {
  try {
    const { search, minPrice, maxPrice, sort } = req.query;
    let query = { shopId: req.params.shopId, isActive: true };

    if (search) {
      query.name = { $regex: search, $options: 'i' };
    }

    if (minPrice || maxPrice) {
      query.price = {};
      if (minPrice) query.price.$gte = parseFloat(minPrice);
      if (maxPrice) query.price.$lte = parseFloat(maxPrice);
    }

    let sortOption = { createdAt: -1 };
    if (sort === 'price_asc') sortOption = { price: 1 };
    if (sort === 'price_desc') sortOption = { price: -1 };
    if (sort === 'name') sortOption = { name: 1 };

    const products = await Product.find(query).sort(sortOption);

    res.status(200).json({
      success: true,
      count: products.length,
      data: products,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get product by ID
// @route   GET /api/products/:id
const getProductById = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id).populate('shopId', 'shopName address phone status');

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    res.status(200).json({
      success: true,
      data: product,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update product
// @route   PUT /api/products/:id
const updateProduct = async (req, res, next) => {
  try {
    let product = await Product.findById(req.params.id);

    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    // Verify ownership
    const shop = await Shop.findById(product.shopId);
    if (shop.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const updates = { ...req.body };
    if (updates.price) updates.price = parseFloat(updates.price);
    if (updates.discount) updates.discount = parseFloat(updates.discount);
    if (updates.stock) updates.stock = parseInt(updates.stock);

    // Handle image uploads (Cloudinary gives full URL in path)
    if (req.files && req.files.length > 0) {
      updates.images = req.files.map((file) => file.path);
    }

    product = await Product.findByIdAndUpdate(req.params.id, updates, { new: true, runValidators: true });

    res.status(200).json({
      success: true,
      message: 'Product updated successfully',
      data: product,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete product
// @route   DELETE /api/products/:id
const deleteProduct = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id);

    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    // Verify ownership
    const shop = await Shop.findById(product.shopId);
    if (shop.ownerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await Product.findByIdAndDelete(req.params.id);

    res.status(200).json({
      success: true,
      message: 'Product deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get owner's products
// @route   GET /api/products/my-products
const getOwnerProducts = async (req, res, next) => {
  try {
    const shop = await Shop.findOne({ ownerId: req.user._id });
    if (!shop) {
      return res.status(404).json({
        success: false,
        message: 'You must register a shop first',
      });
    }

    const products = await Product.find({ shopId: shop._id }).sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: products.length,
      data: products,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  addProduct,
  getProductsByShop,
  getProductById,
  updateProduct,
  deleteProduct,
  getOwnerProducts,
};
