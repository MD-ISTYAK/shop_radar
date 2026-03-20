const Cart = require('../models/Cart');
const Product = require('../models/Product');
const Order = require('../models/Order');

// @desc    Add item to cart
// @route   POST /api/cart/add
const addToCart = async (req, res, next) => {
  try {
    const { productId, quantity = 1 } = req.body;

    // Verify product exists and has stock
    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    if (product.stock < quantity) {
      return res.status(400).json({ success: false, message: 'Insufficient stock' });
    }

    let cart = await Cart.findOne({ userId: req.user._id });

    if (!cart) {
      cart = await Cart.create({
        userId: req.user._id,
        items: [{ productId, quantity }],
      });
    } else {
      // Check if item already in cart
      const existingItem = cart.items.find((item) => item.productId.toString() === productId);

      if (existingItem) {
        existingItem.quantity += quantity;
      } else {
        cart.items.push({ productId, quantity });
      }

      await cart.save();
    }

    // Populate cart for response
    await cart.populate('items.productId', 'name price discount images stock shopId');

    res.status(200).json({
      success: true,
      message: 'Item added to cart',
      data: cart,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get cart
// @route   GET /api/cart
const getCart = async (req, res, next) => {
  try {
    let cart = await Cart.findOne({ userId: req.user._id }).populate(
      'items.productId',
      'name price discount images stock shopId'
    );

    if (!cart) {
      cart = { items: [], totalItems: 0, totalPrice: 0 };
    } else {
      const cartObj = cart.toObject();
      cartObj.totalItems = cartObj.items.reduce((sum, item) => sum + item.quantity, 0);
      cartObj.totalPrice = cartObj.items.reduce((sum, item) => {
        const product = item.productId;
        const price = product.discount > 0 ? product.price - (product.price * product.discount) / 100 : product.price;
        return sum + price * item.quantity;
      }, 0);
      return res.status(200).json({ success: true, data: cartObj });
    }

    res.status(200).json({ success: true, data: cart });
  } catch (error) {
    next(error);
  }
};

// @desc    Update cart item quantity
// @route   PUT /api/cart/update
const updateCartItem = async (req, res, next) => {
  try {
    const { productId, quantity } = req.body;

    const cart = await Cart.findOne({ userId: req.user._id });
    if (!cart) {
      return res.status(404).json({ success: false, message: 'Cart not found' });
    }

    const item = cart.items.find((item) => item.productId.toString() === productId);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Item not in cart' });
    }

    // Verify stock
    const product = await Product.findById(productId);
    if (product.stock < quantity) {
      return res.status(400).json({ success: false, message: 'Insufficient stock' });
    }

    item.quantity = quantity;
    await cart.save();
    await cart.populate('items.productId', 'name price discount images stock shopId');

    res.status(200).json({
      success: true,
      message: 'Cart updated',
      data: cart,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Remove item from cart
// @route   DELETE /api/cart/remove/:productId
const removeFromCart = async (req, res, next) => {
  try {
    const cart = await Cart.findOne({ userId: req.user._id });
    if (!cart) {
      return res.status(404).json({ success: false, message: 'Cart not found' });
    }

    cart.items = cart.items.filter((item) => item.productId.toString() !== req.params.productId);
    await cart.save();
    await cart.populate('items.productId', 'name price discount images stock shopId');

    res.status(200).json({
      success: true,
      message: 'Item removed from cart',
      data: cart,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Checkout / Place order
// @route   POST /api/cart/checkout
const checkout = async (req, res, next) => {
  try {
    const cart = await Cart.findOne({ userId: req.user._id }).populate('items.productId');

    if (!cart || cart.items.length === 0) {
      return res.status(400).json({ success: false, message: 'Cart is empty' });
    }

    // Group items by shop
    const shopOrders = {};
    for (const item of cart.items) {
      const product = item.productId;
      const shopId = product.shopId.toString();

      if (!shopOrders[shopId]) {
        shopOrders[shopId] = { items: [], totalAmount: 0 };
      }

      const price = product.discount > 0 ? product.price - (product.price * product.discount) / 100 : product.price;

      shopOrders[shopId].items.push({
        productId: product._id,
        name: product.name,
        quantity: item.quantity,
        price,
      });
      shopOrders[shopId].totalAmount += price * item.quantity;

      // Reduce stock
      product.stock -= item.quantity;
      await product.save();
    }

    // Create orders
    const orders = [];
    for (const [shopId, orderData] of Object.entries(shopOrders)) {
      const order = await Order.create({
        userId: req.user._id,
        shopId,
        items: orderData.items,
        totalAmount: orderData.totalAmount,
        deliveryAddress: req.body.deliveryAddress || '',
      });
      orders.push(order);
    }

    // Clear cart
    cart.items = [];
    await cart.save();

    res.status(201).json({
      success: true,
      message: 'Order placed successfully',
      data: orders,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  addToCart,
  getCart,
  updateCartItem,
  removeFromCart,
  checkout,
};
