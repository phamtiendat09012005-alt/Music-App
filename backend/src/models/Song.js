const mongoose = require('mongoose');

const songSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
  },
  artist: {
    type: String,
    required: true,
    trim: true,
  },
  genre: {
    type: String,
    default: 'Pop',
    trim: true,
  },
  // Link file .mp3 trên Cloudinary (Người 1 dùng link này để phát nhạc)
  audioUrl: {
    type: String,
    required: true,
  },
  // Link file nhạc Beat / Karaoke (.mp3 không lời) trên Cloudinary
  instrumentalUrl: {
    type: String,
    default: '',
  },
  // Link ảnh bìa bài hát trên Cloudinary
  coverUrl: {
    type: String,
    default: '',
  },
  // Link file lời bài hát .lrc trên Cloudinary (có thể rỗng theo Mục 7)
  lyricsUrl: {
    type: String,
    default: '',
  },
  // Nội dung lời bài hát (.lrc hoặc văn bản thuần) lưu trực tiếp trong MongoDB để tải tức thì
  lyrics: {
    type: String,
    default: '',
  },
  // Thời lượng bài hát tính bằng giây (ví dụ: 215)
  duration: {
    type: Number,
    default: 0,
  },
  // Số lượt nghe (sẽ tăng thêm 1 mỗi khi gọi API POST /api/history)
  playCount: {
    type: Number,
    default: 0,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Song', songSchema);
