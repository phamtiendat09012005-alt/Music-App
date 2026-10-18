const Song = require('../models/Song');
const cloudinary = require('../config/cloudinary');
const streamifier = require('streamifier');

// Hàm hỗ trợ upload buffer lên Cloudinary
const uploadToCloudinary = (fileBuffer, folderName, resourceType = 'auto') => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      { folder: folderName, resource_type: resourceType },
      (error, result) => {
        if (result) resolve(result);
        else reject(error);
      }
    );
    streamifier.createReadStream(fileBuffer).pipe(uploadStream);
  });
};

const buildDefaultLrc = (title, artist) =>
  [
    `[00:00.00] ♪ ${title} - ${artist}`,
    `[00:04.50] Giai điệu mở đầu nhẹ nhàng vang lên...`,
    `[00:10.00] Đưa cảm xúc trôi theo từng nốt nhạc`,
    `[00:16.50] Từng lời ca ngân vang giữa không gian`,
    `[00:23.00] Khoảnh khắc bình yên lắng đọng trong tim`,
    `[00:30.00] Điệp khúc cao trào đầy cảm xúc (${title})`,
    `[00:38.00] Hòa quyện cùng giọng hát của ${artist}`,
    `[00:46.00] Giai điệu còn mãi ngân nga...`,
    `[00:54.00] ♪ Kết thúc bản nhạc ♪`,
  ].join('\n');

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

    // Tự động bổ sung lời .lrc mẫu cho các bài hát cũ trong DB chưa có lyrics
    for (const song of songs) {
      if ((!song.lyrics || !song.lyrics.trim()) && (!song.lyricsUrl || !song.lyricsUrl.trim())) {
        song.lyrics = buildDefaultLrc(song.title, song.artist);
        await Song.updateOne({ _id: song._id }, { $set: { lyrics: song.lyrics } });
      }
    }

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
    const { title, artist, genre, duration, lyricsText } = req.body;

    if (!title || !artist || !req.files || !req.files.audio) {
      return res.status(400).json({ message: 'Vui lòng cung cấp tiêu đề, nghệ sĩ và file âm thanh' });
    }

    // Upload file audio lên Cloudinary
    const audioResult = await uploadToCloudinary(req.files.audio[0].buffer, 'music-app/audios', 'video');
    let coverUrl = '';
    let lyricsUrl = '';
    let lyricsContent = lyricsText ? lyricsText.trim() : '';

    // Nếu có ảnh bìa
    if (req.files.cover) {
      const coverResult = await uploadToCloudinary(req.files.cover[0].buffer, 'music-app/covers', 'image');
      coverUrl = coverResult.secure_url;
    }

    // Nếu có file lời bài hát (.lrc / .srt / .txt)
    if (req.files.lyrics) {
      const fileBuffer = req.files.lyrics[0].buffer;
      // Đọc trực tiếp nội dung UTF-8 của file .lrc / .srt (loại bỏ ký tự BOM \uFEFF nếu có) lưu vào MongoDB
      const extractedText = fileBuffer.toString('utf-8').replace(/^\uFEFF/, '').trim();
      if (extractedText) {
        lyricsContent = extractedText;
      }
      try {
        const lyricsResult = await uploadToCloudinary(fileBuffer, 'music-app/lyrics', 'raw');
        lyricsUrl = lyricsResult.secure_url;
      } catch (e) {
        console.warn('Không đẩy được file lời bài hát lên Cloudinary, đã lưu nội dung trực tiếp vào MongoDB:', e.message);
      }
    }

    const parsedDuration =
      duration && parseInt(duration) > 0
        ? parseInt(duration)
        : audioResult.duration
          ? Math.round(audioResult.duration)
          : 0;

    // Tạo bản ghi trong MongoDB
    const newSong = await Song.create({
      title,
      artist,
      genre: genre || 'Pop',
      audioUrl: audioResult.secure_url,
      coverUrl,
      lyricsUrl,
      lyrics: lyricsContent,
      duration: parsedDuration,
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

// 5. POST /api/songs/:id/play - Tăng số lượt nghe bài hát lên 1
exports.incrementPlayCount = async (req, res, next) => {
  try {
    const song = await Song.findByIdAndUpdate(
      req.params.id,
      { $inc: { playCount: 1 } },
      { new: true }
    );
    if (!song) {
      return res.status(404).json({ message: 'Không tìm thấy bài hát' });
    }
    res.status(200).json({ message: 'Đã cập nhật lượt nghe', playCount: song.playCount });
  } catch (error) {
    next(error);
  }
};

// 6. PUT /api/songs/:id/lyrics - Cập nhật lời bài hát (.lrc) cho bài hát đã có sẵn
exports.updateSongLyrics = async (req, res, next) => {
  try {
    const { lyrics } = req.body;
    const song = await Song.findByIdAndUpdate(
      req.params.id,
      { $set: { lyrics: typeof lyrics === 'string' ? lyrics.trim() : '' } },
      { new: true }
    );
    if (!song) {
      return res.status(404).json({ message: 'Không tìm thấy bài hát' });
    }
    res.status(200).json(song);
  } catch (error) {
    next(error);
  }
};