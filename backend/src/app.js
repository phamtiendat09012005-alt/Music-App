require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Kết nối tới MongoDB Atlas
connectDB();

// Middleware cơ bản
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Route kiểm tra trạng thái server
app.get('/api/health', (req, res) => {
  res.status(200).json({ message: 'Server đang hoạt động ổn định!' });
});

// Gắn nhánh API xác thực với tiền tố /api/auth
app.use('/api/auth', require('./routes/auth'));
app.use('/api/songs', require('./routes/songs'));
// Middleware xử lý lỗi tập trung
app.use(errorHandler);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server đang chạy ở cổng ${PORT}`);
});