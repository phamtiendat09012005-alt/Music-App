const jwt = require('jsonwebtoken');
const User = require('../models/User');

const auth = async (req, res, next) => {
  try {
    // 1. Lấy header Authorization từ client gửi lên
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Không có token xác thực, từ chối truy cập' });
    }

    // 2. Cắt bỏ chữ "Bearer " để lấy phần chuỗi token phía sau
    const token = authHeader.split(' ')[1];

    // 3. Giải mã token bằng khóa bí mật JWT_SECRET trong file .env
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 4. Tìm người dùng trong DB theo ID giải mã được (ẩn trường passwordHash đi)
    const user = await User.findById(decoded.userId).select('-passwordHash');
    if (!user) {
      return res.status(401).json({ message: 'Người dùng không tồn tại' });
    }

    // 5. Gắn thông tin user vào biến req để các controller phía sau sử dụng
    req.user = user;
    next(); // Cho phép đi tiếp vào controller
  } catch (error) {
    return res.status(401).json({ message: 'Token không hợp lệ hoặc đã hết hạn' });
  }
};

module.exports = auth;