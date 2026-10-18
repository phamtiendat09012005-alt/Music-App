const mongoose = require('mongoose');

const playHistorySchema = new mongoose.Schema({
  // Người dùng nào vừa nghe nhạc
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  // Bài hát nào vừa được phát
  songId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Song',
    required: true,
  },
  // Thời điểm phát bài hát
  playedAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('PlayHistory', playHistorySchema);