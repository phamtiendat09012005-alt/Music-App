const mongoose = require('mongoose');

const artistSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    // Link ảnh đại diện chân dung ca sĩ/nghệ sĩ trên Cloudinary hoặc link web
    avatarUrl: {
      type: String,
      default: '',
      trim: true,
    },
    // Thông tin giới thiệu / tiểu sử nghệ sĩ
    bio: {
      type: String,
      default: '',
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Artist', artistSchema);

