const Artist = require('../models/Artist');
const Song = require('../models/Song');
const cloudinary = require('../config/cloudinary');
const streamifier = require('streamifier');

// Hàm hỗ trợ upload buffer ảnh lên Cloudinary
const uploadToCloudinary = (fileBuffer, folderName, resourceType = 'image') => {
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

// Bỏ dấu tiếng Việt (chuẩn hóa NFD và thay thế ký tự)
const removeVietnameseDiacritics = (str = '') => {
  return (str || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, (m) => (m === 'đ' ? 'd' : 'D'));
};

// Chuẩn hóa tên nghệ sĩ hiển thị sạch sẽ
const cleanArtistName = (raw = '') => {
  return (raw || '')
    .normalize('NFC')
    .trim()
    .replace(/^[(\[\s]+|[)\]\s]+$/g, '')
    .replace(/\s+/g, ' ');
};

// Chuẩn hóa canonical key so sánh nghệ sĩ (bỏ qua dấu tiếng Việt, dấu nối, khoảng trắng và hợp nhất các biến thể bí danh)
const normalizeArtistKey = (raw = '') => {
  const cleaned = cleanArtistName(raw);
  if (!cleaned) return '';
  const simple = removeVietnameseDiacritics(cleaned)
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');

  // Hợp nhất các biến thể tên gọi thường gặp của cùng một nghệ sĩ
  if (simple === 'sontung' || simple === 'sontungmtp' || simple === 'sontungm') {
    return 'sontungmtp';
  }
  if (simple === 'jack' || simple === 'j97' || simple === 'jackj97' || simple === 'jack97') {
    return 'jackj97';
  }
  if (simple === 'soobin' || simple === 'soobinhoangson') {
    return 'soobin';
  }
  if (simple === 'hieuthuhai' || simple === 'hieuthu2') {
    return 'hieuthuhai';
  }
  if (simple === 'hoangthuylinh') {
    return 'hoangthuylinh';
  }
  if (simple === 'phuongly') {
    return 'phuongly';
  }
  if (simple === 'vu' || simple === 'hoangthaiu') {
    return 'vu';
  }

  return simple;
};

// Hàm tách danh sách nghệ sĩ từ chuỗi (hỗ trợ nhiều nghệ sĩ cách nhau bởi , ; / & ft. feat. featuring vs. x và)
const splitArtists = (artistString = '') => {
  if (!artistString) return [];
  const normalized = artistString.normalize('NFC').trim();
  return normalized
    .split(/(?:\s*[,;/&]\s*|\s+(?:ft|feat|featuring|vs)\.?\s+|\b(?:ft|feat|featuring|vs)\.\s*|\s+x\s+|\s+v[àa]\s+)/i)
    .map(cleanArtistName)
    .filter(Boolean);
};

// 1. GET /api/artists - Lấy danh sách tất cả nghệ sĩ kèm ảnh đại diện tùy chỉnh hoặc fallback
exports.getArtists = async (req, res, next) => {
  try {
    const { search = '' } = req.query;

    // Lấy tất cả bài hát để thống kê nghệ sĩ và số lượng bài hát, lượt nghe
    const songs = await Song.find({}, 'title artist coverUrl playCount').lean();

    // Map thống kê từ bài hát: key là canonical key (tránh tách thành 2 khi cùng 1 nghệ sĩ)
    const artistStats = new Map();

    for (const song of songs) {
      const names = splitArtists(song.artist);
      for (const name of names) {
        const key = normalizeArtistKey(name);
        if (!key) continue;
        if (!artistStats.has(key)) {
          artistStats.set(key, {
            name,
            songCount: 0,
            totalPlayCount: 0,
            fallbackCover: song.coverUrl || '',
          });
        } else {
          // Ưu tiên tên hiển thị dài và đầy đủ hơn
          const existing = artistStats.get(key);
          if (name.length > existing.name.length) {
            existing.name = name;
          }
        }
        const stat = artistStats.get(key);
        stat.songCount += 1;
        stat.totalPlayCount += song.playCount || 0;
        if (!stat.fallbackCover && song.coverUrl) {
          stat.fallbackCover = song.coverUrl;
        }
      }
    }

    // Lấy danh sách nghệ sĩ đã được lưu hoặc cài đặt ảnh riêng trong MongoDB
    const customArtists = await Artist.find({}).lean();
    const customMap = new Map();
    for (const ca of customArtists) {
      const key = normalizeArtistKey(ca.name);
      if (!customMap.has(key)) {
        customMap.set(key, ca);
      } else {
        const existing = customMap.get(key);
        // Ưu tiên bản ghi có ảnh đại diện tùy chỉnh hợp lệ
        if ((!existing.avatarUrl || !existing.avatarUrl.trim()) && ca.avatarUrl && ca.avatarUrl.trim()) {
          customMap.set(key, ca);
        }
      }
    }

    // Kết hợp dữ liệu bằng Map để đảm bảo 1 nghệ sĩ không bao giờ bị tách làm 2
    const mergedMap = new Map();

    // 1. Duyệt qua tất cả nghệ sĩ xuất hiện trong bài hát
    for (const [key, stat] of artistStats.entries()) {
      const custom = customMap.get(key);
      const avatarUrl =
        custom && custom.avatarUrl && custom.avatarUrl.trim()
          ? custom.avatarUrl.trim()
          : stat.fallbackCover;

      mergedMap.set(key, {
        _id: custom?._id || null,
        name: custom?.name || stat.name,
        avatarUrl,
        hasCustomAvatar: Boolean(custom && custom.avatarUrl && custom.avatarUrl.trim()),
        bio: custom?.bio || '',
        songCount: stat.songCount,
        totalPlayCount: stat.totalPlayCount,
      });
    }

    // 2. Thêm các nghệ sĩ có trong collection Artist nhưng chưa có bài hát nào trong MongoDB
    for (const [key, custom] of customMap.entries()) {
      if (!mergedMap.has(key)) {
        mergedMap.set(key, {
          _id: custom._id,
          name: custom.name,
          avatarUrl: custom.avatarUrl || '',
          hasCustomAvatar: Boolean(custom.avatarUrl && custom.avatarUrl.trim()),
          bio: custom.bio || '',
          songCount: 0,
          totalPlayCount: 0,
        });
      }
    }

    const mergedList = Array.from(mergedMap.values());

    // Sắp xếp: ưu tiên số lượt nghe hoặc số bài hát
    mergedList.sort((a, b) => b.totalPlayCount - a.totalPlayCount || b.songCount - a.songCount);

    // Lọc theo từ khóa tìm kiếm nếu có
    const keyword = normalizeArtistKey(search);
    const result = keyword
      ? mergedList.filter((a) => normalizeArtistKey(a.name).includes(keyword))
      : mergedList;

    res.status(200).json({
      artists: result,
      total: result.length,
    });
  } catch (error) {
    next(error);
  }
};

// 2. POST /api/artists (hoặc PUT /api/artists/update) - Thêm/Cập nhật ảnh đại diện nghệ sĩ (Admin)
exports.createOrUpdateArtist = async (req, res, next) => {
  try {
    const { name, avatarUrl: providedUrl, bio } = req.body;
    const targetName = cleanArtistName(name || req.params.name || '');

    if (!targetName) {
      return res.status(400).json({ message: 'Vui lòng cung cấp tên nghệ sĩ/ca sĩ!' });
    }

    let finalAvatarUrl = providedUrl ? providedUrl.trim() : '';

    // Nếu người dùng upload file ảnh từ máy
    if (req.file) {
      const uploadRes = await uploadToCloudinary(
        req.file.buffer,
        'music-app/artists',
        'image'
      );
      finalAvatarUrl = uploadRes.secure_url;
    }

    const targetKey = normalizeArtistKey(targetName);

    // Tìm trong database xem đã có bản ghi nào của nghệ sĩ này chưa (dựa theo key chuẩn hóa)
    const allArtists = await Artist.find({});
    let artist = allArtists.find((a) => normalizeArtistKey(a.name) === targetKey);

    if (artist) {
      artist.name = targetName;
      if (finalAvatarUrl) {
        artist.avatarUrl = finalAvatarUrl;
      }
      if (bio !== undefined) {
        artist.bio = bio.trim();
      }
      await artist.save();
    } else {
      const newArtistData = {
        name: targetName,
      };
      if (finalAvatarUrl) {
        newArtistData.avatarUrl = finalAvatarUrl;
      }
      if (bio !== undefined) {
        newArtistData.bio = bio.trim();
      }
      artist = await Artist.create(newArtistData);
    }

    res.status(200).json({
      message: 'Cập nhật thông tin nghệ sĩ thành công!',
      artist,
    });
  } catch (error) {
    next(error);
  }
};

// 3. DELETE /api/artists/:id - Xóa cấu hình ảnh riêng (trở về ảnh mặc định)
exports.deleteArtist = async (req, res, next) => {
  try {
    const artist = await Artist.findById(req.params.id);
    if (!artist) {
      return res.status(404).json({ message: 'Không tìm thấy nghệ sĩ' });
    }
    await artist.deleteOne();
    res.status(200).json({ message: 'Đã xóa ảnh tùy chỉnh của nghệ sĩ, quay về mặc định.' });
  } catch (error) {
    next(error);
  }
};

