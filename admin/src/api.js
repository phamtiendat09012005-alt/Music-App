import axios from 'axios';

// Bật USE_MOCK = true để test giao diện khi chưa chạy Backend (TV1)
// Đổi thành false khi đã chạy server Backend ở cổng 5000
const USE_MOCK = false;

// Nếu đang dùng Backend thật mà trong trình duyệt còn lưu token giả từ chế độ Mock trước đó -> tự động xoá
if (!USE_MOCK && localStorage.getItem('token') === 'mock-jwt-token-admin-123456') {
  localStorage.removeItem('token');
  localStorage.removeItem('user');
}

const api = axios.create({
  baseURL: 'http://localhost:5000/api',
});

// Tự động đính kèm JWT token vào Header Authorization cho mọi request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Tự động đăng xuất và chuyển về /login nếu token không hợp lệ hoặc hết hạn (401)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (
      error.response?.status === 401 &&
      !error.config?.url?.includes('/auth/login')
    ) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Dữ liệu mẫu để test khi USE_MOCK = true
let mockSongs = [
  {
    _id: '665f1a2b3c4d5e6f7a8b9c01',
    title: 'Nơi Này Có Anh',
    artist: 'Sơn Tùng M-TP',
    genre: 'Pop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    coverUrl: 'https://picsum.photos/seed/song1/200/200',
    lyricsUrl: 'https://res.cloudinary.com/demo/raw/upload/noi-nay-co-anh.lrc',
    duration: 260,
    playCount: 1520,
  },
  {
    _id: '665f1a2b3c4d5e6f7a8b9c02',
    title: 'Waiting For You',
    artist: 'MONO',
    genre: 'Pop',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    coverUrl: 'https://picsum.photos/seed/song2/200/200',
    lyricsUrl: '',
    duration: 265,
    playCount: 980,
  },
];

// 1. Đăng nhập Admin: POST /api/auth/login
export const loginAdmin = async (email, password) => {
  if (USE_MOCK) {
    if (email === 'admin@music.com' && password === '123456') {
      return {
        token: 'mock-jwt-token-admin-123456',
        user: {
          _id: '665f00000000000000000001',
          name: 'Admin Music',
          email: 'admin@music.com',
          role: 'admin',
        },
      };
    }
    const err = new Error('Sai email hoặc mật khẩu');
    err.response = { data: { message: 'Sai email hoặc mật khẩu! (Dùng admin@music.com / 123456)' } };
    throw err;
  }
  const res = await api.post('/auth/login', { email, password });
  return res.data;
};

// 2. Lấy danh sách bài hát (& tìm kiếm): GET /api/songs?search=...
export const getSongs = async (search = '') => {
  if (USE_MOCK) {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return [...mockSongs];
    return mockSongs.filter(
      (s) =>
        s.title.toLowerCase().includes(keyword) ||
        s.artist.toLowerCase().includes(keyword)
    );
  }
  const res = await api.get('/songs', {
    params: search ? { search } : {},
  });
  return res.data.songs || res.data;
};

// 3. Upload bài hát: POST /api/songs (multipart/form-data)
export const uploadSong = async (formData) => {
  if (USE_MOCK) {
    const audioFile = formData.get('audio');
    const coverFile = formData.get('cover');
    const lyricsFile = formData.get('lyrics');

    const localAudioUrl = audioFile ? URL.createObjectURL(audioFile) : '';
    const localCoverUrl = coverFile ? URL.createObjectURL(coverFile) : '';
    const localLyricsUrl = lyricsFile ? URL.createObjectURL(lyricsFile) : '';

    const newSong = {
      _id: '665f' + Date.now(),
      title: formData.get('title'),
      artist: formData.get('artist'),
      genre: formData.get('genre') || 'Pop',
      audioUrl: localAudioUrl,
      coverUrl: localCoverUrl,
      lyricsUrl: localLyricsUrl,
      duration: 210,
      playCount: 0,
    };
    mockSongs = [newSong, ...mockSongs];
    return newSong;
  }
  const res = await api.post('/songs', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  return res.data;
};

// 4. Xoá bài hát: DELETE /api/songs/:id
export const deleteSong = async (id) => {
  if (USE_MOCK) {
    mockSongs = mockSongs.filter((s) => s._id !== id);
    return { message: 'Đã xóa bài hát' };
  }
  const res = await api.delete(`/songs/${id}`);
  return res.data;
};

// 5. Cập nhật lời bài hát (.lrc): PUT /api/songs/:id/lyrics
export const updateSongLyrics = async (id, lyrics) => {
  if (USE_MOCK) {
    mockSongs = mockSongs.map((s) => (s._id === id ? { ...s, lyrics } : s));
    return mockSongs.find((s) => s._id === id);
  }
  const res = await api.put(`/songs/${id}/lyrics`, { lyrics });
  return res.data;
};

// 5b. Chỉnh sửa & bổ sung các phần còn thiếu vào bài hát đã thêm trước đó: PUT /api/songs/:id
export const updateSong = async (id, formData) => {
  if (USE_MOCK) {
    mockSongs = mockSongs.map((s) =>
      s._id === id
        ? {
            ...s,
            title: formData.get('title') || s.title,
            artist: formData.get('artist') || s.artist,
            genre: formData.get('genre') || s.genre,
            lyrics:
              formData.get('lyricsText') !== null
                ? formData.get('lyricsText')
                : s.lyrics,
          }
        : s
    );
    return mockSongs.find((s) => s._id === id);
  }
  const res = await api.put(`/songs/${id}`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  return res.data;
};

// 6. Lấy danh sách nghệ sĩ: GET /api/artists
export const getArtists = async (search = '') => {
  if (USE_MOCK) {
    return [
      {
        name: 'Sơn Tùng M-TP',
        avatarUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Son_Tung_M-TP_1_%282017%29.png/500px-Son_Tung_M-TP_1_%282017%29.png',
        hasCustomAvatar: true,
        songCount: 1,
        totalPlayCount: 990,
      },
    ];
  }
  const res = await api.get('/artists', {
    params: search ? { search } : {},
  });
  return res.data.artists || res.data;
};

// 7. Cập nhật / Đổi ảnh đại diện nghệ sĩ: POST /api/artists
export const updateArtist = async (formDataOrData) => {
  const isMultipart = formDataOrData instanceof FormData;
  const res = await api.post('/artists', formDataOrData, {
    headers: isMultipart ? { 'Content-Type': 'multipart/form-data' } : {},
  });
  return res.data.artist || res.data;
};

// 8. Xóa ảnh đại diện riêng của nghệ sĩ (quay về ảnh mặc định): DELETE /api/artists/:id
export const deleteArtist = async (id) => {
  const res = await api.delete(`/artists/${id}`);
  return res.data;
};

export default api;
