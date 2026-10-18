const mongoose = require('mongoose');

const playlistSchema = new mongoose.Schema({
  // Tên danh sách phát do người dùng đặt
  name: {
    type: String,
    required: true,
    trim: true,
  },
  // ID của người dùng sở hữu playlist này
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  // Danh sách ID các bài hát được thêm vào playlist
  songs: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Song',
    },
  ],
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Playlist', playlistSchema);