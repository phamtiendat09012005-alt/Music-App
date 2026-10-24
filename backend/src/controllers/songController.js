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

// Kiểm tra xem lyrics có phải chuỗi mẫu giả lập cũ hay không để làm sạch dữ liệu MongoDB
const isFakePlaceholderLyrics = (text) =>
  typeof text === 'string' &&
  text.includes('Giai điệu mở đầu nhẹ nhàng vang lên...');

// 1. GET /api/songs - Lấy danh sách bài hát trực tiếp từ MongoDB (có tìm kiếm theo tên/nghệ sĩ, phân trang)[cite: 7]
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

    // Dọn sạch lời giả lập cũ (nếu có) để đảm bảo 100% dữ liệu trả về là dữ liệu thật từ MongoDB
    for (const song of songs) {
      if (isFakePlaceholderLyrics(song.lyrics)) {
        song.lyrics = '';
        await Song.updateOne({ _id: song._id }, { $set: { lyrics: '' } });
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

// 2. GET /api/songs/:id - Lấy chi tiết một bài hát từ MongoDB[cite: 7]
exports.getSongById = async (req, res, next) => {
  try {
    const song = await Song.findById(req.params.id);
    if (!song) {
      return res.status(404).json({ message: 'Không tìm thấy bài hát' });
    }
    if (isFakePlaceholderLyrics(song.lyrics)) {
      song.lyrics = '';
      await Song.updateOne({ _id: song._id }, { $set: { lyrics: '' } });
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
    let instrumentalUrl = req.body.instrumentalUrl ? req.body.instrumentalUrl.trim() : '';
    let coverUrl = '';
    let lyricsUrl = '';
    let lyricsContent = lyricsText ? lyricsText.trim() : '';

    // Nếu có upload file nhạc Beat / Karaoke riêng
    if (req.files.instrumental) {
      const instResult = await uploadToCloudinary(
        req.files.instrumental[0].buffer,
        'music-app/instrumentals',
        'video'
      );
      instrumentalUrl = instResult.secure_url;
    }

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
      instrumentalUrl,
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

// 7. PUT /api/songs/:id - Chỉnh sửa & bổ sung các thành phần còn thiếu (Beat, Lyric, Ảnh bìa, Audio, Thông tin) cho bài hát đã tạo trước đó
exports.updateSong = async (req, res, next) => {
  try {
    const song = await Song.findById(req.params.id);
    if (!song) {
      return res.status(404).json({ message: 'Không tìm thấy bài hát trong MongoDB' });
    }

    const {
      title,
      artist,
      genre,
      duration,
      lyricsText,
      instrumentalUrl,
      coverUrl,
      removeInstrumental,
    } = req.body;

    // 1. Cập nhật các trường thông tin cơ bản nếu được gửi lên
    if (typeof title === 'string' && title.trim()) {
      song.title = title.trim();
    }
    if (typeof artist === 'string' && artist.trim()) {
      song.artist = artist.trim();
    }
    if (typeof genre === 'string' && genre.trim()) {
      song.genre = genre.trim();
    }
    if (duration !== undefined && parseInt(duration, 10) > 0) {
      song.duration = parseInt(duration, 10);
    }

    // 2. Nếu có thay file nhạc gốc (.mp3) mới
    if (req.files && req.files.audio && req.files.audio[0]) {
      const audioResult = await uploadToCloudinary(
        req.files.audio[0].buffer,
        'music-app/audios',
        'video'
      );
      song.audioUrl = audioResult.secure_url;
      if ((!duration || parseInt(duration, 10) <= 0) && audioResult.duration) {
        song.duration = Math.round(audioResult.duration);
      }
    }

    // 3. Nếu có bổ sung / thay thế file nhạc Beat Karaoke (.mp3)
    if (req.files && req.files.instrumental && req.files.instrumental[0]) {
      const instResult = await uploadToCloudinary(
        req.files.instrumental[0].buffer,
        'music-app/instrumentals',
        'video'
      );
      song.instrumentalUrl = instResult.secure_url;
    } else if (removeInstrumental === 'true') {
      song.instrumentalUrl = '';
    } else if (typeof instrumentalUrl === 'string' && instrumentalUrl.trim()) {
      song.instrumentalUrl = instrumentalUrl.trim();
    }

    // 4. Nếu có bổ sung / thay thế ảnh bìa
    if (req.files && req.files.cover && req.files.cover[0]) {
      const coverResult = await uploadToCloudinary(
        req.files.cover[0].buffer,
        'music-app/covers',
        'image'
      );
      song.coverUrl = coverResult.secure_url;
    } else if (typeof coverUrl === 'string' && coverUrl.trim()) {
      song.coverUrl = coverUrl.trim();
    }

    // 5. Nếu có bổ sung / thay thế file lời bài hát (.lrc / .srt / .txt) hoặc nội dung văn bản lyricsText
    if (typeof lyricsText === 'string') {
      song.lyrics = lyricsText.trim();
    }
    if (req.files && req.files.lyrics && req.files.lyrics[0]) {
      const fileBuffer = req.files.lyrics[0].buffer;
      const extractedText = fileBuffer
        .toString('utf-8')
        .replace(/^\uFEFF/, '')
        .trim();
      if (extractedText && (!lyricsText || !lyricsText.trim())) {
        song.lyrics = extractedText;
      }
      try {
        const lyricsResult = await uploadToCloudinary(
          fileBuffer,
          'music-app/lyrics',
          'raw'
        );
        song.lyricsUrl = lyricsResult.secure_url;
      } catch (e) {
        console.warn(
          'Không đẩy được file lời bài hát lên Cloudinary, đã lưu nội dung trực tiếp vào MongoDB:',
          e.message
        );
      }
    }

    await song.save();
    res.status(200).json(song);
  } catch (error) {
    next(error);
  }
};
