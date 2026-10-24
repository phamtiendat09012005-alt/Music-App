const bcrypt = require('bcrypt');
const User = require('./models/User');
const Song = require('./models/Song');
const Playlist = require('./models/Playlist');
const Artist = require('./models/Artist');

const initialSongs = [
  {
    title: 'Chúng Ta Của Tương Lai',
    artist: 'Sơn Tùng M-TP',
    genre: 'Pop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    coverUrl:
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Son_Tung_M-TP_1_%282017%29.png/500px-Son_Tung_M-TP_1_%282017%29.png',
    duration: 240,
    playCount: 990,
  },
  {
    title: 'Trong Đôi Mắt Thiếu Nữ',
    artist: 'RHYDER',
    genre: 'Pop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    coverUrl:
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400&auto=format&fit=crop&q=80',
    duration: 210,
    playCount: 950,
  },
  {
    title: 'Thấy Dùi',
    artist: 'Hoàng Thùy Linh',
    genre: 'Pop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    coverUrl:
      'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&auto=format&fit=crop&q=80',
    duration: 195,
    playCount: 890,
  },
  {
    title: 'Giá Như',
    artist: 'SOOBIN',
    genre: 'Ballad',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    coverUrl:
      'https://images.unsplash.com/photo-1445985543470-41fba5c3144a?w=400&auto=format&fit=crop&q=80',
    duration: 215,
    playCount: 870,
  },
  {
    title: 'Ngáo Ngơ',
    artist: 'HIEUTHUHAI',
    genre: 'Pop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    coverUrl:
      'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=400&auto=format&fit=crop&q=80',
    duration: 200,
    playCount: 840,
  },
  {
    title: 'Thành Đô',
    artist: 'GUrbane',
    genre: 'Ballad',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    coverUrl:
      'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&auto=format&fit=crop&q=80',
    duration: 225,
    playCount: 820,
  },
  {
    title: 'NEON',
    artist: 'A2O, A2O LITE',
    genre: 'Electronic',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    coverUrl:
      'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400&auto=format&fit=crop&q=80',
    duration: 188,
    playCount: 760,
  },
  {
    title: 'Nhẹ Buông',
    artist: 'Hằng ssi, Aries tis',
    genre: 'Lofi',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    coverUrl:
      'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=400&auto=format&fit=crop&q=80',
    duration: 205,
    playCount: 710,
  },
];

const buildSampleLrc = (title, artist) => `[00:00.00] ♪ ${title} - ${artist} ♪
[00:04.00] Giai điệu mở đầu vang lên...
[00:09.00] Từng khoảnh khắc trôi qua nhẹ nhàng trong tâm trí
[00:15.00] Ánh đèn phố thị phản chiếu những kỷ niệm xưa
[00:21.00] Liệu ngày mai chúng ta còn nhớ về nhau
[00:27.00] Giữa muôn vàn thanh âm của cuộc sống vội vã
[00:33.00] Điệp khúc ngân vang cùng nhịp đập con tim
[00:40.00] Giữ trọn từng giây phút đắm chìm trong âm nhạc
[00:48.00] Dù thời gian có trôi đi chẳng thể quay lại
[00:56.00] Giai điệu này vẫn còn mãi bên ta ♪`;

const seedDatabaseIfEmpty = async () => {
  try {
    // 1. Đảm bảo tài khoản Admin luôn tồn tại trên MongoDB
    const adminEmail = 'admin@music.com';
    let admin = await User.findOne({ email: adminEmail });
    if (!admin) {
      const passwordHash = await bcrypt.hash('123456', 10);
      admin = await User.create({
        name: 'Admin Music',
        email: adminEmail,
        passwordHash,
        role: 'admin',
      });
      console.log('Đã khởi tạo tài khoản Admin mặc định trên MongoDB (admin@music.com / 123456)');
    }

    // 2. Nếu bảng Song trên MongoDB đang trống -> nạp dữ liệu bài hát ban đầu vào MongoDB
    const songCount = await Song.countDocuments();
    if (songCount === 0) {
      const songsWithLyrics = initialSongs.map((s) => ({
        ...s,
        lyrics: buildSampleLrc(s.title, s.artist),
      }));
      const createdSongs = await Song.insertMany(songsWithLyrics);
      console.log(`Đã nạp ${createdSongs.length} bài hát khởi tạo vào MongoDB Atlas!`);

      // 3. Khởi tạo Playlist mẫu trên MongoDB liên kết tới ID thật của bài hát trên MongoDB
      const playlistCount = await Playlist.countDocuments();
      if (playlistCount === 0 && createdSongs.length >= 3) {
        await Playlist.insertMany([
          {
            name: 'Nhạc Học Bài',
            owner: 'user1',
            songs: [createdSongs[0]._id, createdSongs[1]._id],
          },
          {
            name: 'Chill Cuối Tuần',
            owner: 'user1',
            songs: [createdSongs[2]._id],
          },
        ]);
        console.log('Đã nạp 2 Playlist mẫu vào MongoDB Atlas!');
      }
    } else {
      // Tự động bổ sung lời .lrc cho các bài hát khởi tạo cũ chưa có lời trên MongoDB
      const songsWithoutLyrics = await Song.find({
        $or: [{ lyrics: { $exists: false } }, { lyrics: '' }],
        lyricsUrl: '',
      });
      for (const s of songsWithoutLyrics) {
        s.lyrics = buildSampleLrc(s.title, s.artist);
        await s.save();
      }
    }

    // 4. Khởi tạo sẵn ảnh đại diện chân dung chuẩn cho các nghệ sĩ nổi bật nếu chưa có
    const defaultArtistProfiles = [
      {
        name: 'Sơn Tùng M-TP',
        avatarUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Son_Tung_M-TP_1_%282017%29.png/500px-Son_Tung_M-TP_1_%282017%29.png',
        bio: 'Ca sĩ, nhạc sĩ, nhà sản xuất âm nhạc hàng đầu V-Pop.',
      },
      {
        name: 'RHYDER',
        avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
        bio: 'Ca sĩ, Rapper tài năng của làn sóng âm nhạc trẻ.',
      },
      {
        name: 'Hoàng Thùy Linh',
        avatarUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80',
        bio: 'Nữ ca sĩ kết hợp độc đáo giữa âm nhạc dân gian đương đại và EDM.',
      },
      {
        name: 'SOOBIN',
        avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80',
        bio: 'Hoàng tử R&B/Ballad với chất giọng ngọt ngào đầy cảm xúc.',
      },
      {
        name: 'HIEUTHUHAI',
        avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80',
        bio: 'Rapper nổi bật với phong cách hiện đại và nhiều bản hit triệu view.',
      },
      {
        name: 'MONO',
        avatarUrl:
          'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&auto=format&fit=crop&q=80',
        bio: 'Nghệ sĩ trẻ thế hệ mới với phong cách Pop R&B cuốn hút.',
      },
    ];

    for (const item of defaultArtistProfiles) {
      const exists = await Artist.findOne({
        name: { $regex: new RegExp(`^${item.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') },
      });
      if (!exists) {
        await Artist.create(item);
      }
    }
  } catch (error) {
    console.error('Lỗi khi kiểm tra/khởi tạo dữ liệu MongoDB:', error.message);
  }
};

module.exports = seedDatabaseIfEmpty;

