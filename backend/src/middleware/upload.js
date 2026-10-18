const multer = require('multer');

// Lưu file vào bộ nhớ tạm (memoryStorage) trước khi đẩy lên Cloudinary
const storage = multer.memoryStorage();

const upload = multer({
  storage: storage,
  limits: { fileSize: 50 * 1024 * 1024 }, // Giới hạn file tối đa 50MB
});

module.exports = upload;