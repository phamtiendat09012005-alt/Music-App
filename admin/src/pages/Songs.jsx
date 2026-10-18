import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import UploadSongForm from '../components/UploadSongForm';
import { getSongs, deleteSong } from '../api';

export default function Songs() {
  const [songs, setSongs] = useState([]);
  const [search, setSearch] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const fetchSongs = async (keyword = '') => {
    try {
      setIsLoading(true);
      const data = await getSongs(keyword);
      setSongs(data);
    } catch (err) {
      console.error('Lỗi tải danh sách bài hát:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchSongs();
  }, []);

  const handleDelete = async (id, title) => {
    if (!window.confirm(`Bạn có chắc muốn xoá bài hát "${title}"?`)) return;
    try {
      await deleteSong(id);
      fetchSongs(search);
    } catch (err) {
      alert(err.response?.data?.message || 'Lỗi khi xoá bài hát');
    }
  };

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#121212' }}>
      <Navbar />

      <main style={{ maxWidth: '1100px', margin: '0 auto', padding: '24px' }}>
        {/* Form upload bài hát */}
        <UploadSongForm onUploadSuccess={() => fetchSongs(search)} />

        {/* Thanh tìm kiếm & tổng số bài hát */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: '16px',
          }}
        >
          <h3 style={{ margin: 0 }}>Danh sách bài hát ({songs.length})</h3>
          <input
            type="text"
            placeholder="Tìm theo tên bài hát hoặc nghệ sĩ..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              fetchSongs(e.target.value);
            }}
            style={{
              width: '300px',
              padding: '9px 14px',
              borderRadius: '20px',
              border: '1px solid #333',
              backgroundColor: '#242424',
              color: '#fff',
            }}
          />
        </div>

        {/* Bảng hiển thị danh sách bài hát */}
        <div
          style={{
            backgroundColor: '#181818',
            borderRadius: '10px',
            border: '1px solid #282828',
            overflow: 'hidden',
          }}
        >
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #282828', color: '#b3b3b3', fontSize: '13px' }}>
                <th style={{ padding: '14px' }}>Ảnh bìa</th>
                <th style={{ padding: '14px' }}>Tên bài hát</th>
                <th style={{ padding: '14px' }}>Nghệ sĩ</th>
                <th style={{ padding: '14px' }}>Thể loại</th>
                <th style={{ padding: '14px' }}>Lời (.lrc)</th>
                <th style={{ padding: '14px' }}>Lượt nghe</th>
                <th style={{ padding: '14px' }}>Nghe thử</th>
                <th style={{ padding: '14px', textAlign: 'right' }}>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan="8" style={{ padding: '24px', textAlign: 'center', color: '#b3b3b3' }}>
                    Đang tải danh sách bài hát...
                  </td>
                </tr>
              ) : songs.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ padding: '24px', textAlign: 'center', color: '#b3b3b3' }}>
                    Chưa có bài hát nào.
                  </td>
                </tr>
              ) : (
                songs.map((song) => (
                  <tr key={song._id} style={{ borderBottom: '1px solid #222' }}>
                    <td style={{ padding: '12px 14px' }}>
                      <img
                        src={song.coverUrl}
                        alt={song.title}
                        style={{ width: '48px', height: '48px', borderRadius: '6px', objectFit: 'cover' }}
                      />
                    </td>
                    <td style={{ padding: '12px 14px', fontWeight: 'bold' }}>{song.title}</td>
                    <td style={{ padding: '12px 14px', color: '#b3b3b3' }}>{song.artist}</td>
                    <td style={{ padding: '12px 14px', color: '#b3b3b3' }}>{song.genre}</td>
                    <td style={{ padding: '12px 14px' }}>
                      {song.lyricsUrl ? (
                        <span style={{ color: '#1DB954', fontSize: '12px' }}>✔ Có .lrc</span>
                      ) : (
                        <span style={{ color: '#666', fontSize: '12px' }}>Không</span>
                      )}
                    </td>
                    <td style={{ padding: '12px 14px', color: '#b3b3b3' }}>{song.playCount || 0}</td>
                    <td style={{ padding: '12px 14px' }}>
                      <audio controls src={song.audioUrl} style={{ height: '32px', width: '180px' }} />
                    </td>
                    <td style={{ padding: '12px 14px', textAlign: 'right' }}>
                      <button
                        onClick={() => handleDelete(song._id, song.title)}
                        style={{
                          padding: '6px 12px',
                          backgroundColor: '#e91429',
                          color: '#fff',
                          border: 'none',
                          borderRadius: '4px',
                          cursor: 'pointer',
                        }}
                      >
                        Xoá
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}