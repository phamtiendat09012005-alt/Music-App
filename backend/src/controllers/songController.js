const Song = require('../models/Song');
const cloudinary = require('../config/cloudinary');
const streamifier = require('streamifier');

// Hàm hỗ trợ upload buffer lên Cloudinary
const uploadToCloudinary = (fileBuffer, folderName) => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      { folder: folderName, resource_type: 'auto' },
      (error, result) => {
        if (result) resolve(result);
        else reject(error);
      }
    );
    streamifier.createReadStream(fileBuffer).pipe(uploadStream);
  });
};

// 1. GET /api/songs - Lấy danh sách bài hát (có tìm kiếm theo tên/nghệ sĩ, phân trang)[cite: 7]
exports.getSongs = async (req, res, next) => {
  try {
    const { search, page = 1, limit = 20 } = req.query;
    let query = {};

    if (search) {
      query = {
        $or: [
          { title: { $regex: search, $options: 'i' } },
          { artist: { $regex: search, $options: 'i' } },
        ],
      };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const songs = await Song.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Song.countDocuments(query);

    res.status(200).json({
      songs,
      totalPages: Math.ceil(total / limit),
      currentPage: parseInt(page),
      totalSongs: total,
    });
  } catch (error) {
    next(error);
  }
};

// 2. GET /api/songs/:id - Lấy chi tiết một bài hát[cite: 7]
exports.getSongById = async (req, res, next) => {
  try {
    const song = await Song.findById(req.params.id);
    if (!song) {
      return res.status(404).json({ message: 'Không tìm thấy bài hát' });
    }
    res.status(200).json(song);
  } catch (error) {
    next(error);
  }
};

// 3. POST /api/songs - Upload bài hát mới (Chỉ dành cho Admin)[cite: 7]
exports.createSong = async (req, res, next) => {
  try {
    const { title, artist, genre, duration } = req.body;

    if (!title || !artist || !req.files || !req.files.audio) {
      return res.status(400).json({ message: 'Vui lòng cung cấp tiêu đề, nghệ sĩ và file âm thanh' });
    }

    // Upload file audio lên Cloudinary
    const audioResult = await uploadToCloudinary(req.files.audio[0].buffer, 'music-app/audios');
    let coverUrl = '';
    let lyricsUrl = '';

    // Nếu có ảnh bìa
    if (req.files.cover) {
      const coverResult = await uploadToCloudinary(req.files.cover[0].buffer, 'music-app/covers');
      coverUrl = coverResult.secure_url;
    }

    // Nếu có file lời bài hát (.lrc)
    if (req.files.lyrics) {
      const lyricsResult = await uploadToCloudinary(req.files.lyrics[0].buffer, 'music-app/lyrics');
      lyricsUrl = lyricsResult.secure_url;
    }

    // Tạo bản ghi trong MongoDB
    const newSong = await Song.create({
      title,
      artist,
      genre: genre || 'Pop',
      audioUrl: audioResult.secure_url,
      coverUrl,
      lyricsUrl,
      duration: duration ? parseInt(duration) : 0,
    });

    res.status(201).json(newSong);
  } catch (error) {
    next(error);
  }
};

// 4. DELETE /api/songs/:id - Xóa bài hát (Chỉ dành cho Admin)[cite: 7]
exports.deleteSong = async (req, res, next) => {
  try {
    const song = await Song.findById(req.params.id);
    if (!song) {
      return res.status(404).json({ message: 'Không tìm thấy bài hát' });
    }

    await song.deleteOne();
    res.status(200).json({ message: 'Đã xóa bài hát thành công' });
  } catch (error) {
    next(error);
  }
};