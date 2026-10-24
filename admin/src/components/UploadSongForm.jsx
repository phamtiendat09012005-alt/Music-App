import React, { useState } from 'react';
import { uploadSong } from '../api';

export default function UploadSongForm({ onUploadSuccess }) {
  const [title, setTitle] = useState('');
  const [artist, setArtist] = useState('');
  const [genre, setGenre] = useState('Pop');
  const [audioFile, setAudioFile] = useState(null);
  const [instrumentalFile, setInstrumentalFile] = useState(null);
  const [duration, setDuration] = useState(0);
  const [coverFile, setCoverFile] = useState(null);
  const [lyricsFile, setLyricsFile] = useState(null);
  const [lyricsText, setLyricsText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleLyricsFileChange = (file) => {
    setLyricsFile(file || null);
    if (file) {
      const reader = new FileReader();
      reader.onload = (ev) => {
        if (typeof ev.target?.result === 'string') {
          setLyricsText(ev.target.result);
        }
      };
      reader.readAsText(file, 'utf-8');
    }
  };

  const handleAudioChange = (file) => {
    setAudioFile(file);
    if (file) {
      const audio = new Audio();
      const objectUrl = URL.createObjectURL(file);
      audio.src = objectUrl;
      audio.onloadedmetadata = () => {
        setDuration(Math.round(audio.duration) || 0);
        URL.revokeObjectURL(objectUrl);
      };
    } else {
      setDuration(0);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrorMsg('');

    if (!title.trim() || !artist.trim() || !audioFile || !coverFile) {
      setErrorMsg('Vui lòng nhập tên bài, nghệ sĩ và chọn đủ file nhạc (.mp3) + ảnh bìa!');
      return;
    }

    // Chuẩn hóa danh sách nghệ sĩ (VD: "Sơn Tùng M-TP ft. RHYDER", "Sơn Tùng M-TP x RHYDER")
    const normalizedArtist = artist
      .normalize('NFC')
      .split(/(?:\s*[,;/&]\s*|\s+(?:ft|feat|featuring|vs)\.?\s+|\b(?:ft|feat|featuring|vs)\.\s*|\s+x\s+|\s+v[àa]\s+)/i)
      .map((a) => a.trim().replace(/^[(\[\s]+|[)\]\s]+$/g, '').replace(/\s+/g, ' '))
      .filter(Boolean)
      .join(', ');

    // Đóng gói dữ liệu dạng multipart/form-data đúng Hợp đồng API Mục 8
    const formData = new FormData();
    formData.append('title', title.trim());
    formData.append('artist', normalizedArtist);
    formData.append('genre', genre.trim());
    formData.append('duration', duration || 0);
    formData.append('audio', audioFile);
    if (instrumentalFile) {
      formData.append('instrumental', instrumentalFile);
    }
    formData.append('cover', coverFile);
    if (lyricsFile) {
      formData.append('lyrics', lyricsFile);
    }
    if (lyricsText.trim()) {
      formData.append('lyricsText', lyricsText.trim());
    }

    try {
      setIsLoading(true);
      await uploadSong(formData);
      // Reset form sau khi upload thành công
      setTitle('');
      setArtist('');
      setGenre('Pop');
      setAudioFile(null);
      setInstrumentalFile(null);
      setCoverFile(null);
      setLyricsFile(null);
      setLyricsText('');
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
    backgroundColor: '#1C1C2B',
    color: '#fff',
    width: '100%',
    boxSizing: 'border-box',
  };

  return (
    <div
      style={{
        backgroundColor: '#12121D',
        padding: '20px',
        borderRadius: '10px',
        marginBottom: '28px',
        border: '1px solid #1C1C2B',
      }}
    >
      <h3 style={{ marginTop: 0, color: '#B794FF' }}>+ Upload Bài Hát Mới</h3>
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
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
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
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
              Nghệ sĩ (artist - cách nhau dấu phẩy nếu nhiều người) *
            </label>
            <input
              type="text"
              placeholder="VD: Sơn Tùng M-TP, RHYDER..."
              value={artist}
              onChange={(e) => setArtist(e.target.value)}
              style={inputStyle}
            />
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
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
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
              File nhạc gốc có lời (.mp3) *
            </label>
            <input
              type="file"
              accept="audio/*"
              onChange={(e) => handleAudioChange(e.target.files[0])}
              style={inputStyle}
            />
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#B794FF' }}>
              🎤 File nhạc Beat / Karaoke (.mp3 - Tùy chọn)
            </label>
            <input
              type="file"
              accept="audio/*"
              onChange={(e) => setInstrumentalFile(e.target.files[0] || null)}
              style={inputStyle}
            />
          </div>

          <div>
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
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
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
              File lời bài hát (.lrc / .srt / .txt - Tùy chọn)
            </label>
            <input
              type="file"
              accept=".lrc,.srt,.vtt,.txt,text/plain"
              onChange={(e) => handleLyricsFileChange(e.target.files[0])}
              style={inputStyle}
            />
          </div>
        </div>

        <div style={{ marginBottom: '18px' }}>
          <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
            Nội dung lời bài hát (Hỗ trợ chuẩn <code>.LRC [mm:ss.xx]</code>, chuẩn <code>.SRT (00:00:04,500 --&gt; 00:00:10,000)</code> hoặc văn bản thường)
          </label>
          <textarea
            rows={4}
            placeholder={"Hỗ trợ .LRC:\n[00:00.00] ♪ Nhạc dạo đầu...\n\nHoặc .SRT:\n1\n00:00:04,500 --> 00:00:10,000\nDòng lời bài hát thứ nhất..."}
            value={lyricsText}
            onChange={(e) => setLyricsText(e.target.value)}
            style={{
              ...inputStyle,
              fontFamily: 'monospace',
              fontSize: '13px',
              resize: 'vertical',
            }}
          />
        </div>

        <button
          type="submit"
          disabled={isLoading}
          style={{
            padding: '10px 24px',
            backgroundColor: isLoading ? '#555' : '#B794FF',
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
