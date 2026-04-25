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
      transformation: [
        { quality: 'auto', fetch_format: 'auto' },
        { width: 800, crop: 'limit' }
      ]
    };
  },
});

const optimizeMediaUrl = (url, type) => {
  if (!url) return '';
  if (!url.includes('res.cloudinary.com')) return url;
  
  const uploadIndex = url.indexOf('/upload/');
  if (uploadIndex === -1) return url;
  
  const prefix = url.substring(0, uploadIndex + 8);
  const suffix = url.substring(uploadIndex + 8);
  
  if (type === 'image') {
    return `${prefix}f_auto,q_auto,w_500/${suffix}`;
  } else if (type === 'video') {
    return `${prefix}f_auto,q_auto/${suffix}`;
  }
  return url;
};

const getVideoThumbnail = (videoUrl) => {
  if (!videoUrl) return '';
  if (!videoUrl.includes('res.cloudinary.com')) return videoUrl;
  
  const uploadIndex = videoUrl.indexOf('/upload/');
  if (uploadIndex === -1) return videoUrl;
  
  const prefix = videoUrl.substring(0, uploadIndex + 8);
  let suffix = videoUrl.substring(uploadIndex + 8);
  
  // Replace extension with .jpg for thumbnail
  const extIndex = suffix.lastIndexOf('.');
  if (extIndex !== -1) {
    suffix = suffix.substring(0, extIndex) + '.jpg';
  }
  
  return `${prefix}f_auto,q_auto,w_500/${suffix}`;
};

module.exports = { cloudinary, storage, optimizeMediaUrl, getVideoThumbnail };
