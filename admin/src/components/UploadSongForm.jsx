import React, { useState } from 'react';
import { uploadSong } from '../api';

export default function UploadSongForm({ onUploadSuccess }) {
  const [title, setTitle] = useState('');
  const [artist, setArtist] = useState('');
  const [genre, setGenre] = useState('Pop');
  const [audioFile, setAudioFile] = useState(null);
  const [coverFile, setCoverFile] = useState(null);
  const [lyricsFile, setLyricsFile] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrorMsg('');

    if (!title.trim() || !artist.trim() || !audioFile || !coverFile) {
      setErrorMsg('Vui lòng nhập tên bài, nghệ sĩ và chọn đủ file nhạc (.mp3) + ảnh bìa!');
      return;
    }

    // Đóng gói dữ liệu dạng multipart/form-data đúng Hợp đồng API Mục 8
    const formData = new FormData();
    formData.append('title', title.trim());
    formData.append('artist', artist.trim());
    formData.append('genre', genre.trim());
    formData.append('audio', audioFile);
    formData.append('cover', coverFile);
    if (lyricsFile) {
      formData.append('lyrics', lyricsFile);
    }

    try {
      setIsLoading(true);
      await uploadSong(formData);
      // Reset form sau khi upload thành công
      setTitle('');
      setArtist('');
      setGenre('Pop');
      setAudioFile(null);
      setCoverFile(null);
      setLyricsFile(null);
      e.target.reset();
      onUploadSuccess();
    } catch (err) {
      setErrorMsg(err.response?.data?.message || 'Lỗi khi tải bài hát lên!');
    } finally {
      setIsLoading(false);
    }
  };

  const inputStyle = {
    padding: '10px',
    borderRadius: '6px',
    border: '1px solid #333',
    backgroundColor: '#242424',
    color: '#fff',
    width: '100%',
    boxSizing: 'border-box',
  };

  return (
    <div
      style={{
        backgroundColor: '#181818',
        padding: '20px',
        borderRadius: '10px',
        marginBottom: '28px',
        border: '1px solid #282828',
      }}
    >
      <h3 style={{ marginTop: 0, color: '#1DB954' }}>+ Upload Bài Hát Mới</h3>
      {errorMsg && (
        <div style={{ color: '#ff6b6b', marginBottom: '12px', fontSize: '14px' }}>
          ⚠️ {errorMsg}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
            gap: '14px',
            marginBottom: '14px',
          }}
        >
          <div>
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#b3b3b3' }}>
              Tên bài hát (title) *
            </label>
            <input
              type="text"
              placeholder="Nhập tên bài hát..."
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              style={inputStyle}
            />
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#b3b3b3' }}>
              Nghệ sĩ (artist) *
            </label>
            <input
              type="text"
              placeholder="Nhập tên nghệ sĩ..."
              value={artist}
              onChange={(e) => setArtist(e.target.value)}
              style={inputStyle}
            />
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#b3b3b3' }}>
              Thể loại (genre)
            </label>
            <input
              type="text"
              placeholder="Pop, Acoustic, Lofi..."
              value={genre}
              onChange={(e) => setGenre(e.target.value)}
              style={inputStyle}
            />
          </div>
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
            gap: '14px',
            marginBottom: '18px',
          }}
        >
          <div>
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#b3b3b3' }}>
              File nhạc (.mp3) *
            </label>
            <input
              type="file"
              accept="audio/*"
              onChange={(e) => setAudioFile(e.target.files[0])}
              style={inputStyle}
            />
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#b3b3b3' }}>
              Ảnh bìa (.jpg, .png) *
            </label>
            <input
              type="file"
              accept="image/*"
              onChange={(e) => setCoverFile(e.target.files[0])}
              style={inputStyle}
            />
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#b3b3b3' }}>
              Lời bài hát đồng bộ (.lrc - Tùy chọn)
            </label>
            <input
              type="file"
              accept=".lrc,text/plain"
              onChange={(e) => setLyricsFile(e.target.files[0])}
              style={inputStyle}
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={isLoading}
          style={{
            padding: '10px 24px',
            backgroundColor: isLoading ? '#555' : '#1DB954',
            color: '#000',
            fontWeight: 'bold',
            border: 'none',
            borderRadius: '20px',
            cursor: isLoading ? 'not-allowed' : 'pointer',
          }}
        >
          {isLoading ? 'Đang tải lên...' : 'Tải bài hát lên'}
        </button>
      </form>
    </div>
  );
}