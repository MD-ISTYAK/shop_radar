const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

// Configuration is automatically picked up from CLOUDINARY_URL in .env
// but we can also set it explicitly if needed.
cloudinary.config({
  cloudinary_url: process.env.CLOUDINARY_URL,
});

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: async (req, file) => {
    let folder = 'shop_radar';
    let resource_type = 'auto'; // Handles both images and videos
    
    if (file.fieldname === 'video') {
      folder = 'shop_radar/videos';
      resource_type = 'video';
    } else if (file.fieldname === 'images' || file.fieldname === 'logo' || file.fieldname === 'banner' || file.fieldname === 'image') {
      folder = 'shop_radar/images';
      resource_type = 'image';
    }

    return {
      folder: folder,
      resource_type: resource_type,
      allowed_formats: ['jpg', 'png', 'jpeg', 'webp', 'mp4', 'mov', 'avi'],
      public_id: `${file.fieldname}-${Date.now()}`,
    };
  },
});

module.exports = { cloudinary, storage };
