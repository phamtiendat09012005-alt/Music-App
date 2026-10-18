const Playlist = require('../models/Playlist');

// 1. GET /api/playlists - Lấy danh sách playlist từ MongoDB
exports.getPlaylists = async (req, res, next) => {
  try {
    const playlists = await Playlist.find()
      .populate('songs')
      .sort({ createdAt: -1 });
    res.status(200).json(playlists);
  } catch (error) {
    next(error);
  }
};

// 2. POST /api/playlists - Tạo playlist mới trên MongoDB
exports.createPlaylist = async (req, res, next) => {
  try {
    const { name, owner, songs } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ message: 'Vui lòng nhập tên playlist' });
    }

    const newPlaylist = await Playlist.create({
      name: name.trim(),
      owner: owner || 'user1',
      songs: songs || [],
    });

    const populated = await Playlist.findById(newPlaylist._id).populate('songs');
    res.status(201).json(populated);
  } catch (error) {
    next(error);
  }
};

// 3. DELETE /api/playlists/:id - Xóa playlist khỏi MongoDB
exports.deletePlaylist = async (req, res, next) => {
  try {
    const playlist = await Playlist.findById(req.params.id);
    if (!playlist) {
      return res.status(404).json({ message: 'Không tìm thấy playlist' });
    }
    await playlist.deleteOne();
    res.status(200).json({ message: 'Đã xóa playlist thành công' });
  } catch (error) {
    next(error);
  }
};

