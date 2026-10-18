const mongoose = require('mongoose');
const dns = require('dns');

// Ép Node.js sử dụng Google DNS để tránh lỗi querySrv ECONNREFUSED của nhà mạng
dns.setServers(['8.8.8.8', '8.8.4.4']);

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`MongoDB Atlas đã kết nối thành công: ${conn.connection.host}`);
    const seedDatabaseIfEmpty = require('../seedData');
    await seedDatabaseIfEmpty();
  } catch (error) {
    console.error(`Lỗi kết nối MongoDB: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;