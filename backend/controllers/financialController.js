const Order = require('../models/Order');
const DeliveryPartner = require('../models/DeliveryPartner');
const Shop = require('../models/Shop');

exports.getDashboardStats = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const role = req.user.role; // 'owner' or 'delivery_partner'

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    
    const lastMonthStart = new Date(today.getFullYear(), today.getMonth() - 1, 1);
    const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0);
    lastMonthEnd.setHours(23, 59, 59, 999);

    let todayEarnings = 0;
    let thisMonthEarnings = 0;
    let lastMonthEarnings = 0;
    let totalEarnings = 0;

    let totalOrdersOrDeliveries = 0;

    if (role === 'owner') {
      const shop = await Shop.findOne({ ownerId: userId });
      if (!shop) return res.status(404).json({ success: false, message: 'Shop not found' });

      const orders = await Order.find({
        shopId: shop._id,
        status: { $in: ['delivered'] },
      });

      totalOrdersOrDeliveries = orders.length;

      orders.forEach(order => {
        const amount = order.totalAmount;
        totalEarnings += amount;

        const date = new Date(order.actualDeliveryTime || order.updatedAt);
        if (date >= today) {
          todayEarnings += amount;
        }
        if (date >= firstDayOfMonth) {
          thisMonthEarnings += amount;
        }
        if (date >= lastMonthStart && date <= lastMonthEnd) {
          lastMonthEarnings += amount;
        }
      });
    } else if (role === 'delivery_partner') {
      const partner = await DeliveryPartner.findOne({ userId });
      if (!partner) return res.status(404).json({ success: false, message: 'Partner not found' });

      totalEarnings = partner.totalEarnings;
      totalOrdersOrDeliveries = partner.completedDeliveries;

      const orders = await Order.find({
        deliveryPartnerId: userId,
        status: 'delivered',
      });

      orders.forEach(order => {
        const amount = order.deliveryFee * 0.85; // 85% to driver
        const date = new Date(order.actualDeliveryTime || order.updatedAt);
        
        if (date >= today) {
          todayEarnings += amount;
        }
        if (date >= firstDayOfMonth) {
          thisMonthEarnings += amount;
        }
        if (date >= lastMonthStart && date <= lastMonthEnd) {
          lastMonthEarnings += amount;
        }
      });
    } else {
      return res.status(403).json({ success: false, message: 'Not authorized for financial dashboard' });
    }

    res.json({
      success: true,
      data: {
        todayEarnings,
        thisMonthEarnings,
        lastMonthEarnings,
        totalEarnings,
        totalOrdersOrDeliveries,
      }
    });

  } catch (error) {
    next(error);
  }
};
