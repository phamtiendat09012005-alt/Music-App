import React, { useEffect, useRef, useState } from 'react';
import Navbar from '../components/Navbar';
import UploadSongForm from '../components/UploadSongForm';
import { getSongs, deleteSong, updateSongLyrics } from '../api';

// Hàm chuyển đổi mốc thời gian SRT (HH:MM:SS,mmm hoặc MM:SS,mmm) sang tổng số giây
function parseSrtTimeToSeconds(hoursStr, minsStr, secsStr, msStr) {
  const hours = hoursStr ? parseInt(hoursStr, 10) || 0 : 0;
  const mins = parseInt(minsStr, 10) || 0;
  const secs = parseInt(secsStr, 10) || 0;
  const ms = msStr ? parseFloat(`0.${msStr}`) : 0;
  return hours * 3600 + mins * 60 + secs + ms;
}

// Hàm bóc tách nội dung .lrc, .srt hoặc văn bản thường thành danh sách các dòng có mốc thời gian (giây)
function parseLrcLines(rawLyrics = '', duration = 180) {
  const cleaned = (rawLyrics || '').replace(/^\uFEFF/, '');
  const lines = cleaned.split(/\r?\n/);
  const lrcTagRegex = /\[(\d{1,3}):(\d{1,2}(?:\.\d{1,3})?)\]/g;
  const srtArrowRegex =
    /^(?:(\d{1,2}):)?(\d{1,2}):(\d{1,2})(?:[.,](\d{1,3}))?\s*-->\s*(?:(\d{1,2}):)?(\d{1,2}):(\d{1,2})(?:[.,](\d{1,3}))?/;
  const metaRegex = /^(\[(ti|ar|al|by|offset):.*\]|WEBVTT.*)$/i;

  const synced = [];
  const plain = [];

  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed || metaRegex.test(trimmed)) continue;

    // 1. Kiểm tra nếu là dòng số thứ tự của file .SRT (ngay phía trên dòng có mũi tên -->)
    if (
      /^\d+$/.test(trimmed) &&
      i + 1 < lines.length &&
      srtArrowRegex.test(lines[i + 1].trim())
    ) {
      continue;
    }

    // 2. Kiểm tra chuẩn .SRT (VD: 00:00:04,500 --> 00:00:10,000)
    const srtMatch = trimmed.match(srtArrowRegex);
    if (srtMatch) {
      const startSec = parseSrtTimeToSeconds(
        srtMatch[1],
        srtMatch[2],
        srtMatch[3],
        srtMatch[4]
      );
      const textParts = [];
      let j = i + 1;
      while (j < lines.length) {
        const nextLine = lines[j].trim();
        if (!nextLine) break;
        if (
          /^\d+$/.test(nextLine) &&
          j + 1 < lines.length &&
          srtArrowRegex.test(lines[j + 1].trim())
        ) {
          break;
        }
        if (srtArrowRegex.test(nextLine)) break;
        // Loại bỏ các thẻ HTML trong phụ đề SRT như <i>, <b> nếu có
        const strippedHtml = nextLine.replace(/<[^>]+>/g, '').trim();
        if (strippedHtml) textParts.push(strippedHtml);
        j++;
      }
      i = j - 1;
      if (textParts.length > 0) {
        synced.push({ timeSec: startSec, text: textParts.join(' ') });
      }
      continue;
    }

    // 3. Kiểm tra chuẩn .LRC (VD: [00:04.50] Dòng lời...)
    const lrcMatches = [...trimmed.matchAll(lrcTagRegex)];
    if (lrcMatches.length > 0) {
      const text = trimmed.replace(lrcTagRegex, '').trim();
      if (!text) continue;
      for (const m of lrcMatches) {
        const mins = parseInt(m[1], 10) || 0;
        const secs = parseFloat(m[2]) || 0;
        synced.push({ timeSec: mins * 60 + secs, text });
      }
      continue;
    }

    // 4. Văn bản thường
    plain.push(trimmed);
  }

  if (synced.length > 0) {
    return synced.sort((a, b) => a.timeSec - b.timeSec);
  }

  if (plain.length > 0) {
    const totalSec = duration > 0 ? duration : 180;
    const step = totalSec / (plain.length + 1);
    return plain.map((text, idx) => ({
      timeSec: Number((step * idx).toFixed(1)),
      text,
    }));
  }

  return [];
}

function formatLrcTimestamp(sec = 0) {
  const mins = Math.floor(sec / 60)
    .toString()
    .padStart(2, '0');
  const remain = (sec % 60).toFixed(2).padStart(5, '0');
  return `[${mins}:${remain}]`;
}

export default function Songs() {
  const [songs, setSongs] = useState([]);
  const [search, setSearch] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  // State cho Trình phát & Đồng bộ Lyric (.LRC)
  const [activeSong, setActiveSong] = useState(null);
  const [currentTime, setCurrentTime] = useState(0);
  const [editingLyrics, setEditingLyrics] = useState('');
  const [isSavingLyrics, setIsSavingLyrics] = useState(false);
  const [saveMessage, setSaveMessage] = useState('');
  const audioRef = useRef(null);
  const lyricsContainerRef = useRef(null);

  const fetchSongs = async (keyword = '') => {
    try {
      setIsLoading(true);
      const data = await getSongs(keyword);
      const list = Array.isArray(data) ? data : (data?.songs || []);
      setSongs(list);
      if (activeSong) {
        const updated = list.find((s) => s._id === activeSong._id);
        if (updated) {
          setActiveSong(updated);
        }
      }
    } catch (err) {
      console.error('Lỗi tải danh sách bài hát:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchSongs();
  }, []);

  const openLyricsStudio = (song, autoPlay = false) => {
    setActiveSong(song);
    setEditingLyrics(song.lyrics || '');
    setCurrentTime(0);
    setSaveMessage('');
    if (autoPlay) {
      setTimeout(() => {
        if (audioRef.current) {
          audioRef.current.currentTime = 0;
          audioRef.current.play().catch(() => {});
        }
      }, 100);
    }
  };

  const parsedLines = activeSong
    ? parseLrcLines(editingLyrics, activeSong.duration || 180)
    : [];

  // Xác định câu hát đang phát theo thời gian thực
  let activeLineIndex = -1;
  for (let i = parsedLines.length - 1; i >= 0; i--) {
    if (currentTime >= parsedLines[i].timeSec) {
      activeLineIndex = i;
      break;
    }
  }
  if (activeLineIndex === -1 && parsedLines.length > 0) {
    activeLineIndex = 0;
  }

  // Tự động cuộn khung lời bài hát theo câu đang phát
  useEffect(() => {
    if (activeLineIndex >= 0 && lyricsContainerRef.current) {
      const container = lyricsContainerRef.current;
      const lineElem = container.children[activeLineIndex];
      if (lineElem) {
        const targetTop =
          lineElem.offsetTop - container.clientHeight / 2 + lineElem.clientHeight / 2;
        container.scrollTo({ top: Math.max(0, targetTop), behavior: 'smooth' });
      }
    }
  }, [activeLineIndex]);

  const handleSaveLyrics = async () => {
    if (!activeSong) return;
    try {
      setIsSavingLyrics(true);
      setSaveMessage('');
      const updated = await updateSongLyrics(activeSong._id, editingLyrics);
      setActiveSong(updated);
      setSongs((prev) =>
        prev.map((s) => (s._id === updated._id ? updated : s))
      );
      setSaveMessage('✔ Đã lưu lời bài hát vào MongoDB!');
    } catch (err) {
      alert(err.response?.data?.message || 'Lỗi khi lưu lời bài hát');
    } finally {
      setIsSavingLyrics(false);
    }
  };

  const handleInsertCurrentTimestamp = () => {
    const tag = formatLrcTimestamp(currentTime);
    setEditingLyrics((prev) => {
      const prefix = prev.trim() ? `${prev.trimEnd()}\n` : '';
      return `${prefix}${tag} `;
    });
  };

  const handleDelete = async (id, title) => {
    if (!window.confirm(`Bạn có chắc muốn xoá bài hát "${title}"?`)) return;
    try {
      await deleteSong(id);
      if (activeSong?._id === id) {
        setActiveSong(null);
      }
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

        {/* TRÌNH PHÁT & ĐỒNG BỘ LYRIC (.LRC) TRỰC TIẾP */}
        {activeSong && (
          <div
            style={{
              backgroundColor: '#181818',
              borderRadius: '12px',
              border: '1px solid #1DB954',
              padding: '20px',
              marginBottom: '28px',
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: '16px',
                flexWrap: 'wrap',
                gap: '12px',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                <img
                  src={activeSong.coverUrl}
                  alt={activeSong.title}
                  style={{
                    width: '56px',
                    height: '56px',
                    borderRadius: '8px',
                    objectFit: 'cover',
                  }}
                />
                <div>
                  <div style={{ color: '#1DB954', fontSize: '12px', fontWeight: 'bold' }}>
                    🎤 TRÌNH CHẠY & ĐỒNG BỘ LỜI BÀI HÁT (.LRC)
                  </div>
                  <h3 style={{ margin: '4px 0 2px 0' }}>{activeSong.title}</h3>
                  <div style={{ color: '#b3b3b3', fontSize: '13px' }}>
                    {activeSong.artist} • {activeSong.genre}
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <audio
                  ref={audioRef}
                  controls
                  src={activeSong.audioUrl}
                  onTimeUpdate={(e) => setCurrentTime(e.currentTarget.currentTime)}
                  style={{ height: '38px', width: '280px' }}
                />
                <button
                  onClick={() => setActiveSong(null)}
                  style={{
                    padding: '8px 14px',
                    backgroundColor: '#282828',
                    color: '#fff',
                    border: '1px solid #444',
                    borderRadius: '6px',
                    cursor: 'pointer',
                  }}
                >
                  Đóng ✕
                </button>
              </div>
            </div>

            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
                gap: '18px',
              }}
            >
              {/* Cột trái: Màn hình chạy chữ Karaoke / .LRC đồng bộ thời gian thực */}
              <div
                style={{
                  backgroundColor: '#121212',
                  borderRadius: '10px',
                  padding: '16px',
                  border: '1px solid #282828',
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    marginBottom: '10px',
                    fontSize: '13px',
                    color: '#b3b3b3',
                  }}
                >
                  <span>Màn hình chạy Lyric (Bấm vào câu bất kỳ để tua nhạc)</span>
                  <span style={{ color: '#1DB954', fontWeight: 'bold' }}>
                    {formatLrcTimestamp(currentTime)}
                  </span>
                </div>

                <div
                  ref={lyricsContainerRef}
                  style={{
                    height: '250px',
                    overflowY: 'auto',
                    padding: '8px 10px',
                    position: 'relative',
                  }}
                >
                  {parsedLines.length === 0 ? (
                    <div
                      style={{
                        height: '100%',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: '#666',
                        textAlign: 'center',
                      }}
                    >
                      Chưa có lời bài hát. Hãy nhập hoặc dán lời vào khung bên phải!
                    </div>
                  ) : (
                    parsedLines.map((line, index) => {
                      const isCurrent = index === activeLineIndex;
                      return (
                        <div
                          key={`${line.timeSec}-${index}`}
                          onClick={() => {
                            if (audioRef.current) {
                              audioRef.current.currentTime = line.timeSec;
                              audioRef.current.play().catch(() => {});
                            }
                            setCurrentTime(line.timeSec);
                          }}
                          style={{
                            padding: '10px 12px',
                            borderRadius: '8px',
                            cursor: 'pointer',
                            transition: 'all 0.2s ease',
                            backgroundColor: isCurrent
                                ? 'rgba(29, 185, 84, 0.14)'
                                : 'transparent',
                            color: isCurrent ? '#1DB954' : '#b3b3b3',
                            fontWeight: isCurrent ? 'bold' : 'normal',
                            fontSize: isCurrent ? '17px' : '14px',
                            display: 'flex',
                            gap: '10px',
                            alignItems: 'center',
                          }}
                        >
                          <span
                            style={{
                              fontSize: '11px',
                              fontFamily: 'monospace',
                              opacity: isCurrent ? 1 : 0.5,
                              minWidth: '58px',
                            }}
                          >
                            {formatLrcTimestamp(line.timeSec)}
                          </span>
                          <span>{line.text}</span>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>

              {/* Cột phải: Trình chỉnh sửa lời .LRC & lưu trực tiếp vào MongoDB */}
              <div
                style={{
                  backgroundColor: '#121212',
                  borderRadius: '10px',
                  padding: '16px',
                  border: '1px solid #282828',
                  display: 'flex',
                  flexDirection: 'column',
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    marginBottom: '10px',
                    flexWrap: 'wrap',
                    gap: '8px',
                  }}
                >
                  <span style={{ fontSize: '13px', color: '#b3b3b3' }}>
                    Soạn thảo lời (<code>.LRC</code> / <code>.SRT</code> / văn bản)
                  </span>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button
                      type="button"
                      onClick={handleInsertCurrentTimestamp}
                      style={{
                        padding: '5px 10px',
                        fontSize: '12px',
                        backgroundColor: '#282828',
                        color: '#1DB954',
                        border: '1px solid #1DB954',
                        borderRadius: '6px',
                        cursor: 'pointer',
                      }}
                    >
                      + Chèn mốc {formatLrcTimestamp(currentTime)}
                    </button>
                    <label
                      style={{
                        padding: '5px 10px',
                        fontSize: '12px',
                        backgroundColor: '#282828',
                        color: '#fff',
                        border: '1px solid #444',
                        borderRadius: '6px',
                        cursor: 'pointer',
                      }}
                    >
                      📂 Nạp file .lrc / .srt
                      <input
                        type="file"
                        accept=".lrc,.srt,.vtt,.txt,text/plain"
                        style={{ display: 'none' }}
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (!file) return;
                          const reader = new FileReader();
                          reader.onload = (ev) => {
                            if (typeof ev.target?.result === 'string') {
                              setEditingLyrics(ev.target.result);
                            }
                          };
                          reader.readAsText(file, 'utf-8');
                        }}
                      />
                    </label>
                  </div>
                </div>

                <textarea
                  rows={8}
                  value={editingLyrics}
                  onChange={(e) => setEditingLyrics(e.target.value)}
                  placeholder="[00:00.00] Nhập lời bài hát có mốc thời gian hoặc từng dòng..."
                  style={{
                    flex: 1,
                    width: '100%',
                    boxSizing: 'border-box',
                    padding: '10px',
                    borderRadius: '8px',
                    border: '1px solid #333',
                    backgroundColor: '#1e1e1e',
                    color: '#fff',
                    fontFamily: 'monospace',
                    fontSize: '13px',
                    resize: 'vertical',
                    marginBottom: '10px',
                  }}
                />

                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                  }}
                >
                  <span style={{ color: '#1DB954', fontSize: '13px' }}>
                    {saveMessage}
                  </span>
                  <button
                    type="button"
                    disabled={isSavingLyrics}
                    onClick={handleSaveLyrics}
                    style={{
                      padding: '8px 18px',
                      backgroundColor: '#1DB954',
                      color: '#000',
                      fontWeight: 'bold',
                      border: 'none',
                      borderRadius: '20px',
                      cursor: isSavingLyrics ? 'not-allowed' : 'pointer',
                    }}
                  >
                    {isSavingLyrics ? 'Đang lưu...' : '💾 Lưu lời bài hát'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

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
                <th style={{ padding: '14px' }}>Lời bài hát (.lrc)</th>
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
                songs.map((song) => {
                  const hasLyrics = Boolean(
                    (song.lyrics && song.lyrics.trim()) ||
                      (song.lyricsUrl && song.lyricsUrl.trim())
                  );
                  const isSelected = activeSong?._id === song._id;

                  return (
                    <tr
                      key={song._id}
                      style={{
                        borderBottom: '1px solid #222',
                        backgroundColor: isSelected
                          ? 'rgba(29, 185, 84, 0.08)'
                          : 'transparent',
                      }}
                    >
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
                        <button
                          type="button"
                          onClick={() => openLyricsStudio(song, true)}
                          style={{
                            padding: '6px 12px',
                            backgroundColor: hasLyrics ? 'rgba(29, 185, 84, 0.18)' : '#282828',
                            color: hasLyrics ? '#1DB954' : '#ccc',
                            border: `1px solid ${hasLyrics ? '#1DB954' : '#444'}`,
                            borderRadius: '16px',
                            fontSize: '12px',
                            fontWeight: 'bold',
                            cursor: 'pointer',
                          }}
                        >
                          {hasLyrics ? '🎤 Chạy / Sửa Lyric' : '+ Thêm Lyric'}
                        </button>
                      </td>
                      <td style={{ padding: '12px 14px', color: '#b3b3b3' }}>{song.playCount || 0}</td>
                      <td style={{ padding: '12px 14px' }}>
                        <audio
                          controls
                          src={song.audioUrl}
                          onPlay={() => openLyricsStudio(song, false)}
                          onTimeUpdate={(e) => {
                            if (activeSong?._id === song._id) {
                              setCurrentTime(e.currentTarget.currentTime);
                            }
                          }}
                          style={{ height: '32px', width: '180px' }}
                        />
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
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}