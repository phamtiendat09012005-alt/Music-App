const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  // Tên hiển thị của người dùng
  name: {
    type: String,
    required: true,
    trim: true,
  },
  // Email dùng để đăng nhập (unique: true để không ai đăng ký trùng email)
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  // Mật khẩu đã được mã hóa bằng thư viện bcrypt
  passwordHash: {
    type: String,
    required: true,
  },
  // Phân quyền: 'user' (người nghe trên app Flutter) hoặc 'admin' (người quản lý trên Web React)
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user',
  },
  // Danh sách ID các bài hát yêu thích của người dùng này (liên kết tới bảng Song)
  favorites: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Song',
    },
  ],
  // Thời gian tạo tài khoản
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('User', userSchema);