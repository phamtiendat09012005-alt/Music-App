const User = require('../models/User');
const Song = require('../models/Song');

// 1. POST /api/users/favorites/:songId - Bật/Tắt yêu thích bài hát
exports.toggleFavorite = async (req, res, next) => {
  try {
    const { songId } = req.params;
    const song = await Song.findById(songId);
    if (!song) {
      return res.status(404).json({ message: 'Không tìm thấy bài hát' });
    }

    const user = await User.findById(req.user._id);
    const index = user.favorites.findIndex((id) => id.toString() === songId);

    let isFavorite = false;
    if (index !== -1) {
      user.favorites.splice(index, 1);
      isFavorite = false;
    } else {
      user.favorites.push(songId);
      isFavorite = true;
    }

    await user.save();
    res.status(200).json({
      message: isFavorite ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích',
      isFavorite,
      favorites: user.favorites,
    });
  } catch (error) {
    next(error);
  }
};

// 2. GET /api/users/favorites - Lấy danh sách bài hát yêu thích
exports.getFavorites = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).populate('favorites');
    res.status(200).json(user.favorites || []);
  } catch (error) {
    next(error);
  }
};

