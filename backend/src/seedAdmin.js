require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('./models/User');
const connectDB = require('./config/db');

const seedAdmin = async () => {
  try {
    await connectDB();

    const adminEmail = 'admin@music.com';
    let admin = await User.findOne({ email: adminEmail });

    if (admin) {
      if (admin.role !== 'admin') {
        admin.role = 'admin';
        await admin.save();
        console.log(`Đã cập nhật role 'admin' cho tài khoản ${adminEmail}`);
      } else {
        console.log(`Tài khoản Admin đã tồn tại: ${adminEmail}`);
      }
    } else {
      const passwordHash = await bcrypt.hash('123456', 10);
      admin = await User.create({
        name: 'Admin Music',
        email: adminEmail,
        passwordHash,
        role: 'admin',
      });
      console.log(`Tạo tài khoản Admin thành công! Email: ${adminEmail} | Mật khẩu: 123456`);
    }

    process.exit(0);
  } catch (error) {
    console.error('Lỗi khi tạo tài khoản Admin:', error.message);
    process.exit(1);
  }
};

seedAdmin();

