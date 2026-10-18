const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Hàm phụ trợ: Tạo JWT token có hạn sử dụng 7 ngày
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

// 1. Xử lý Đăng ký: POST /api/auth/register
exports.register = async (req, res, next) => {
  try {
    const { name, email, password } = req.body;

    // Kiểm tra người dùng có gửi thiếu thông tin không
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Vui lòng nhập đầy đủ name, email và password' });
    }

    // Kiểm tra xem email này đã có ai đăng ký chưa
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ message: 'Email này đã được sử dụng' });
    }

    // Mã hóa mật khẩu bằng bcrypt (độ khó saltRounds = 10)
    const passwordHash = await bcrypt.hash(password, 10);

    // Lưu người dùng mới vào MongoDB
    const user = await User.create({
      name,
      email: email.toLowerCase(),
      passwordHash,
    });

    // Tạo token đăng nhập luôn cho người dùng vừa đăng ký
    const token = generateToken(user._id);

    // Trả về { token, user } đúng chuẩn Hợp đồng API Mục 8
    res.status(201).json({
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        favorites: user.favorites,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

// 2. Xử lý Đăng nhập: POST /api/auth/login
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Vui lòng nhập email và password' });
    }

    // Tìm user theo email
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ message: 'Email hoặc mật khẩu không đúng' });
    }

    // So sánh mật khẩu người dùng nhập vào với passwordHash trong DB
    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json({ message: 'Email hoặc mật khẩu không đúng' });
    }

    const token = generateToken(user._id);

    // Trả về { token, user } đúng chuẩn Hợp đồng API Mục 8
    res.status(200).json({
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        favorites: user.favorites,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

// 3. Lấy thông tin user hiện tại: GET /api/auth/me
exports.getMe = async (req, res, next) => {
  try {
    // req.user đã được middleware auth.js tìm sẵn từ token
    res.status(200).json(req.user);
  } catch (error) {
    next(error);
  }
};