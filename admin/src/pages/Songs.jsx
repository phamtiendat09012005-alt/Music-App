import React, { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import Navbar from '../components/Navbar';
import UploadSongForm from '../components/UploadSongForm';
import { getSongs, deleteSong, updateSongLyrics, updateSong } from '../api';

// Hàm chuyển đổi mốc thời gian SRT (HH:MM:SS,mmm hoặc MM:SS,mmm) sang tổng số giây
function parseSrtTimeToSeconds(hoursStr, minsStr, secsStr, msStr) {
  const hours = hoursStr ? parseInt(hoursStr, 10) || 0 : 0;
  const mins = parseInt(minsStr, 10) || 0;
  const secs = parseInt(secsStr, 10) || 0;
  const ms = msStr ? parseFloat(`0.${msStr}`) : 0;
  return hours * 3600 + mins * 60 + secs + ms;
}

// Hàm bóc tách nội dung .lrc, [start --> end], .srt hoặc văn bản thường thành danh sách các dòng có mốc thời gian (giây)
function parseLrcLines(rawLyrics = '', duration = 180) {
  const cleaned = (rawLyrics || '').replace(/^\uFEFF/, '');
  const lines = cleaned.split(/\r?\n/);
  const lrcTagRegex = /\[(\d{1,3}):(\d{1,2}(?:\.\d{1,3})?)\]/g;
  const lrcRangeRegex =
    /^\[(\d{1,3}):(\d{1,2}(?:\.\d{1,3})?)\s*-->\s*(\d{1,3}):(\d{1,2}(?:\.\d{1,3})?)\]\s*(.*)$/;
  const srtArrowRegex =
    /^(?:(\d{1,2}):)?(\d{1,2}):(\d{1,2})(?:[.,](\d{1,3}))?\s*-->\s*(?:(\d{1,2}):)?(\d{1,2}):(\d{1,2})(?:[.,](\d{1,3}))?/;
  const metaRegex = /^(\[(ti|ar|al|by|offset|re|ve|length):.*\]|WEBVTT.*)$/i;

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

    // 2. Kiểm tra cú pháp [mm:ss.xx --> mm:ss.xx] Dòng lời (có cả mốc vào câu & ngắt câu)
    const rangeMatch = trimmed.match(lrcRangeRegex);
    if (rangeMatch) {
      const startSec =
        (parseInt(rangeMatch[1], 10) || 0) * 60 +
        (parseFloat(rangeMatch[2]) || 0);
      const endSec =
        (parseInt(rangeMatch[3], 10) || 0) * 60 +
        (parseFloat(rangeMatch[4]) || 0);
      const text = (rangeMatch[5] || '').trim();
      if (text) {
        synced.push({
          timeSec: startSec,
          endTimeSec: endSec > startSec ? endSec : null,
          text,
        });
      }
      continue;
    }

    // 3. Kiểm tra chuẩn .SRT (VD: 00:00:04,500 --> 00:00:10,000)
    const srtMatch = trimmed.match(srtArrowRegex);
    if (srtMatch) {
      const startSec = parseSrtTimeToSeconds(
        srtMatch[1],
        srtMatch[2],
        srtMatch[3],
        srtMatch[4]
      );
      const endSec = parseSrtTimeToSeconds(
        srtMatch[5],
        srtMatch[6],
        srtMatch[7],
        srtMatch[8]
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
        const strippedHtml = nextLine.replace(/<[^>]+>/g, '').trim();
        if (strippedHtml) textParts.push(strippedHtml);
        j++;
      }
      i = j - 1;
      if (textParts.length > 0) {
        synced.push({
          timeSec: startSec,
          endTimeSec: endSec > startSec ? endSec : null,
          text: textParts.join(' '),
        });
      }
      continue;
    }

    // 4. Kiểm tra chuẩn .LRC (VD: [00:04.50] Dòng lời... hoặc dòng ngắt câu [00:08.00])
    const lrcMatches = [...trimmed.matchAll(lrcTagRegex)];
    if (lrcMatches.length > 0) {
      const text = trimmed.replace(lrcTagRegex, '').trim();
      if (!text || text === '♪' || text === '...') {
        const firstM = lrcMatches[0];
        const breakSec =
          (parseInt(firstM[1], 10) || 0) * 60 + (parseFloat(firstM[2]) || 0);
        if (
          synced.length > 0 &&
          !synced[synced.length - 1].endTimeSec &&
          breakSec > synced[synced.length - 1].timeSec
        ) {
          synced[synced.length - 1].endTimeSec = breakSec;
        }
        continue;
      }
      for (const m of lrcMatches) {
        const mins = parseInt(m[1], 10) || 0;
        const secs = parseFloat(m[2]) || 0;
        synced.push({ timeSec: mins * 60 + secs, endTimeSec: null, text });
      }
      continue;
    }

    // 5. Văn bản thường
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
  const [studioAudioMode, setStudioAudioMode] = useState('vocal'); // 'vocal' | 'beat'
  const [tapSyncIndex, setTapSyncIndex] = useState(0); // Chỉ số câu đang chờ bấm nhịp trực tiếp
  const audioRef = useRef(null);
  const lyricsContainerRef = useRef(null);

  // State cho Form Chỉnh sửa & Bổ sung thông tin còn thiếu của bài hát đã tạo trước đó
  const [editingSong, setEditingSong] = useState(null);
  const [editTitle, setEditTitle] = useState('');
  const [editArtist, setEditArtist] = useState('');
  const [editGenre, setEditGenre] = useState('Pop');
  const [editDuration, setEditDuration] = useState(0);
  const [editAudioFile, setEditAudioFile] = useState(null);
  const [editInstrumentalFile, setEditInstrumentalFile] = useState(null);
  const [editInstrumentalUrl, setEditInstrumentalUrl] = useState('');
  const [removeInstrumental, setRemoveInstrumental] = useState(false);
  const [editCoverFile, setEditCoverFile] = useState(null);
  const [editLyricsFile, setEditLyricsFile] = useState(null);
  const [editLyricsText, setEditLyricsText] = useState('');
  const [isUpdatingSong, setIsUpdatingSong] = useState(false);
  const [editErrorMsg, setEditErrorMsg] = useState('');
  const [editSuccessMsg, setEditSuccessMsg] = useState('');
  const editPanelRef = useRef(null);

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
      if (editingSong) {
        const updatedEdit = list.find((s) => s._id === editingSong._id);
        if (updatedEdit) {
          setEditingSong(updatedEdit);
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

  const openEditModal = (song) => {
    setEditingSong(song);
    setEditTitle(song.title || '');
    setEditArtist(song.artist || '');
    setEditGenre(song.genre || 'Pop');
    setEditDuration(song.duration || 0);
    setEditAudioFile(null);
    setEditInstrumentalFile(null);
    setEditInstrumentalUrl(song.instrumentalUrl || '');
    setRemoveInstrumental(false);
    setEditCoverFile(null);
    setEditLyricsFile(null);
    setEditLyricsText(song.lyrics || '');
    setEditErrorMsg('');
    setEditSuccessMsg('');
    setTimeout(() => {
      editPanelRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 80);
  };

  const handleEditAudioChange = (file) => {
    setEditAudioFile(file || null);
    if (file) {
      const audio = new Audio();
      const objectUrl = URL.createObjectURL(file);
      audio.src = objectUrl;
      audio.onloadedmetadata = () => {
        setEditDuration(Math.round(audio.duration) || editDuration);
        URL.revokeObjectURL(objectUrl);
      };
    }
  };

  const handleEditLyricsFileChange = (file) => {
    setEditLyricsFile(file || null);
    if (file) {
      const reader = new FileReader();
      reader.onload = (ev) => {
        if (typeof ev.target?.result === 'string') {
          setEditLyricsText(ev.target.result);
        }
      };
      reader.readAsText(file, 'utf-8');
    }
  };

  const handleUpdateSongSubmit = async (e) => {
    e.preventDefault();
    if (!editingSong) return;
    setEditErrorMsg('');
    setEditSuccessMsg('');

    if (!editTitle.trim() || !editArtist.trim()) {
      setEditErrorMsg('Tên bài hát và Nghệ sĩ không được để trống!');
      return;
    }

    const normalizedArtist = editArtist
      .normalize('NFC')
      .split(
        /(?:\s*[,;/&]\s*|\s+(?:ft|feat|featuring|vs)\.?\s+|\b(?:ft|feat|featuring|vs)\.\s*|\s+x\s+|\s+v[àa]\s+)/i
      )
      .map((a) =>
        a
          .trim()
          .replace(/^[(\[\s]+|[)\]\s]+$/g, '')
          .replace(/\s+/g, ' ')
      )
      .filter(Boolean)
      .join(', ');

    const formData = new FormData();
    formData.append('title', editTitle.trim());
    formData.append('artist', normalizedArtist);
    formData.append('genre', editGenre.trim() || 'Pop');
    if (editDuration > 0) {
      formData.append('duration', editDuration);
    }
    if (editAudioFile) {
      formData.append('audio', editAudioFile);
    }
    if (editInstrumentalFile) {
      formData.append('instrumental', editInstrumentalFile);
    } else if (removeInstrumental) {
      formData.append('removeInstrumental', 'true');
    } else if (editInstrumentalUrl.trim()) {
      formData.append('instrumentalUrl', editInstrumentalUrl.trim());
    }
    if (editCoverFile) {
      formData.append('cover', editCoverFile);
    }
    if (editLyricsFile) {
      formData.append('lyrics', editLyricsFile);
    }
    formData.append('lyricsText', editLyricsText.trim());

    try {
      setIsUpdatingSong(true);
      const updated = await updateSong(editingSong._id, formData);
      setEditingSong(updated);
      setEditInstrumentalFile(null);
      setEditAudioFile(null);
      setEditCoverFile(null);
      setEditLyricsFile(null);
      setEditInstrumentalUrl(updated.instrumentalUrl || '');
      setRemoveInstrumental(false);

      setSongs((prev) =>
        prev.map((s) => (s._id === updated._id ? updated : s))
      );
      if (activeSong && activeSong._id === updated._id) {
        setActiveSong(updated);
        setEditingLyrics(updated.lyrics || '');
      }
      setEditSuccessMsg('✔ Đã cập nhật & bổ sung thành công vào MongoDB!');
    } catch (err) {
      setEditErrorMsg(
        err.response?.data?.message || 'Lỗi khi cập nhật bài hát vào MongoDB!'
      );
    } finally {
      setIsUpdatingSong(false);
    }
  };

  const openLyricsStudio = (song, autoPlay = false) => {
    setActiveSong(song);
    setEditingLyrics(song.lyrics || '');
    setCurrentTime(0);
    setTapSyncIndex(0);
    setSaveMessage('');
    setStudioAudioMode('vocal');
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

  const formatLineToLrc = (item) => {
    const startStr = formatLrcTimestamp(item.timeSec).slice(1, -1);
    if (item.endTimeSec && item.endTimeSec > item.timeSec) {
      const endStr = formatLrcTimestamp(item.endTimeSec).slice(1, -1);
      return `[${startStr} --> ${endStr}] ${item.text}`;
    }
    return `[${startStr}] ${item.text}`;
  };

  // Dịch toàn bộ mốc thời gian của tất cả các câu hát thêm/bớt deltaSec giây (Khắc phục lệch nhạc dạo đầu / lệch toàn bài)
  const handleShiftAllTimestamps = (deltaSec) => {
    if (!parsedLines.length) return;
    const shiftedLrc = parsedLines
      .map((item) => {
        const newSec = Math.max(0, item.timeSec + deltaSec);
        const newEnd =
          item.endTimeSec && item.endTimeSec > item.timeSec
            ? Math.max(newSec + 0.3, item.endTimeSec + deltaSec)
            : null;
        return formatLineToLrc({ ...item, timeSec: newSec, endTimeSec: newEnd });
      })
      .join('\n');
    setEditingLyrics(shiftedLrc);
    setSaveMessage(
      `⏱ Đã dịch toàn bộ lời ${deltaSec > 0 ? `+${deltaSec}s` : `${deltaSec}s`}. Bấm "Lưu lời bài hát" để lưu vào MongoDB!`
    );
  };

  // Chấm nhịp trực tiếp (Tap-to-Sync): Gắn thời gian bắt đầu câu hát
  const handleTapSyncNextLine = () => {
    if (!parsedLines.length) return;
    const idx = Math.min(Math.max(0, tapSyncIndex), parsedLines.length - 1);
    const syncedSec = Math.max(0, currentTime - 0.15);
    const updatedList = parsedLines.map((item, i) =>
      i === idx ? { ...item, timeSec: syncedSec } : item
    );
    const lrcString = updatedList.map(formatLineToLrc).join('\n');
    setEditingLyrics(lrcString);
    setTapSyncIndex(idx + 1 < parsedLines.length ? idx + 1 : 0);
    setSaveMessage(
      `🎯 Đã gắn mốc vào câu ${formatLrcTimestamp(syncedSec)} cho câu #${idx + 1}!`
    );
  };

  // Chốt thời điểm ngắt câu (Hát xong câu hiện tại - Khắc phục câu hát nhanh/chậm)
  const handleTapEndCurrentLine = () => {
    if (!parsedLines.length) return;
    const targetIdx = activeLineIndex >= 0 ? activeLineIndex : tapSyncIndex;
    const idx = Math.min(Math.max(0, targetIdx), parsedLines.length - 1);
    const line = parsedLines[idx];
    if (currentTime <= line.timeSec + 0.2) {
      setSaveMessage('⚠️ Thời điểm ngắt câu phải lớn hơn thời điểm bắt đầu câu!');
      return;
    }
    const updatedList = parsedLines.map((item, i) =>
      i === idx ? { ...item, endTimeSec: currentTime } : item
    );
    const lrcString = updatedList.map(formatLineToLrc).join('\n');
    setEditingLyrics(lrcString);
    setSaveMessage(
      `✂️ Đã chốt ngắt câu #${idx + 1} tại ${formatLrcTimestamp(currentTime)} (Thời lượng hát: ${(currentTime - line.timeSec).toFixed(1)}s)!`
    );
  };

  // Tự động cuộn khung lời bài hát theo câu đang phát
  useEffect(() => {
    if (activeLineIndex >= 0 && lyricsContainerRef.current) {
      const container = lyricsContainerRef.current;
      const lineElem = container.children[activeLineIndex];
      if (lineElem) {
        const targetTop =
          lineElem.offsetTop -
          container.clientHeight / 2 +
          lineElem.clientHeight / 2;
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
      if (editingSong && editingSong._id === updated._id) {
        setEditingSong(updated);
        setEditLyricsText(updated.lyrics || '');
      }
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
      if (editingSong?._id === id) {
        setEditingSong(null);
      }
      fetchSongs(search);
    } catch (err) {
      alert(err.response?.data?.message || 'Lỗi khi xoá bài hát');
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
    <div style={{ minHeight: '100vh', backgroundColor: '#0A0A12' }}>
      <Navbar />

      <main style={{ maxWidth: '1180px', margin: '0 auto', padding: '24px' }}>
        {/* Form upload bài hát mới */}
        <UploadSongForm onUploadSuccess={() => fetchSongs(search)} />

        {/* PANEL CHỈNH SỬA & BỔ SUNG THÀNH PHẦN CÒN THIẾU CHO BÀI HÁT ĐÃ THÊM TRƯỚC ĐÓ */}
        {editingSong && (
          <div
            ref={editPanelRef}
            style={{
              backgroundColor: '#12121D',
              borderRadius: '12px',
              border: '2px solid #f59e0b',
              padding: '22px',
              marginBottom: '28px',
              boxShadow: '0 8px 24px rgba(0, 0, 0, 0.45)',
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'flex-start',
                flexWrap: 'wrap',
                gap: '12px',
                marginBottom: '16px',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                <img
                  src={editingSong.coverUrl}
                  alt={editingSong.title}
                  style={{
                    width: '64px',
                    height: '64px',
                    borderRadius: '8px',
                    objectFit: 'cover',
                    border: '1px solid #333',
                  }}
                />
                <div>
                  <div
                    style={{
                      color: '#f59e0b',
                      fontSize: '12px',
                      fontWeight: 'bold',
                      letterSpacing: '0.6px',
                    }}
                  >
                    ✏️ CHỈNH SỬA & BỔ SUNG THÀNH PHẦN CÒN THIẾU (MONGODB)
                  </div>
                  <h3 style={{ margin: '4px 0 6px 0', color: '#fff' }}>
                    {editingSong.title} — <span style={{ color: '#B794FF' }}>{editingSong.artist}</span>
                  </h3>
                  {/* Thanh trạng thái các thành phần đã có / còn thiếu */}
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', fontSize: '12px' }}>
                    <span
                      style={{
                        padding: '3px 10px',
                        borderRadius: '12px',
                        backgroundColor: editingSong.audioUrl ? 'rgba(183, 148, 255,0.15)' : 'rgba(245,158,11,0.2)',
                        color: editingSong.audioUrl ? '#B794FF' : '#f59e0b',
                        border: `1px solid ${editingSong.audioUrl ? '#B794FF' : '#f59e0b'}`,
                      }}
                    >
                      {editingSong.audioUrl ? '✔ Đã có Nhạc gốc' : '⚠️ Thiếu Nhạc gốc'}
                    </span>
                    <span
                      style={{
                        padding: '3px 10px',
                        borderRadius: '12px',
                        backgroundColor:
                          editingSong.instrumentalUrl && editingSong.instrumentalUrl.trim()
                            ? 'rgba(183, 148, 255,0.15)'
                            : 'rgba(245,158,11,0.2)',
                        color:
                          editingSong.instrumentalUrl && editingSong.instrumentalUrl.trim()
                            ? '#B794FF'
                            : '#f59e0b',
                        border: `1px solid ${
                          editingSong.instrumentalUrl && editingSong.instrumentalUrl.trim()
                            ? '#B794FF'
                            : '#f59e0b'
                        }`,
                      }}
                    >
                      {editingSong.instrumentalUrl && editingSong.instrumentalUrl.trim()
                        ? '✔ Đã có Beat Karaoke'
                        : '⚠️ Chưa có Beat Karaoke (Cần bổ sung)'}
                    </span>
                    <span
                      style={{
                        padding: '3px 10px',
                        borderRadius: '12px',
                        backgroundColor:
                          (editingSong.lyrics && editingSong.lyrics.trim()) ||
                          (editingSong.lyricsUrl && editingSong.lyricsUrl.trim())
                            ? 'rgba(183, 148, 255,0.15)'
                            : 'rgba(245,158,11,0.2)',
                        color:
                          (editingSong.lyrics && editingSong.lyrics.trim()) ||
                          (editingSong.lyricsUrl && editingSong.lyricsUrl.trim())
                            ? '#B794FF'
                            : '#f59e0b',
                        border: `1px solid ${
                          (editingSong.lyrics && editingSong.lyrics.trim()) ||
                          (editingSong.lyricsUrl && editingSong.lyricsUrl.trim())
                            ? '#B794FF'
                            : '#f59e0b'
                        }`,
                      }}
                    >
                      {(editingSong.lyrics && editingSong.lyrics.trim()) ||
                      (editingSong.lyricsUrl && editingSong.lyricsUrl.trim())
                        ? '✔ Đã có Lời (.LRC/.SRT)'
                        : '⚠️ Chưa có Lời bài hát (Cần bổ sung)'}
                    </span>
                  </div>
                </div>
              </div>

              <button
                type="button"
                onClick={() => setEditingSong(null)}
                style={{
                  padding: '8px 14px',
                  backgroundColor: '#1C1C2B',
                  color: '#fff',
                  border: '1px solid #444',
                  borderRadius: '6px',
                  cursor: 'pointer',
                }}
              >
                Đóng ✕
              </button>
            </div>

            {editErrorMsg && (
              <div
                style={{
                  padding: '10px 14px',
                  backgroundColor: 'rgba(233, 20, 41, 0.15)',
                  border: '1px solid #F43F5E',
                  color: '#ff6b6b',
                  borderRadius: '6px',
                  marginBottom: '14px',
                  fontSize: '13px',
                }}
              >
                ⚠️ {editErrorMsg}
              </div>
            )}

            {editSuccessMsg && (
              <div
                style={{
                  padding: '10px 14px',
                  backgroundColor: 'rgba(183, 148, 255, 0.15)',
                  border: '1px solid #B794FF',
                  color: '#B794FF',
                  borderRadius: '6px',
                  marginBottom: '14px',
                  fontSize: '13px',
                  fontWeight: 'bold',
                }}
              >
                {editSuccessMsg}
              </div>
            )}

            <form onSubmit={handleUpdateSongSubmit}>
              {/* Hàng 1: Tên bài hát, Nghệ sĩ, Thể loại */}
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
                  gap: '14px',
                  marginBottom: '16px',
                }}
              >
                <div>
                  <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
                    Tên bài hát (title) *
                  </label>
                  <input
                    type="text"
                    value={editTitle}
                    onChange={(e) => setEditTitle(e.target.value)}
                    style={inputStyle}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
                    Nghệ sĩ (cách nhau dấu phẩy nếu nhiều người) *
                  </label>
                  <input
                    type="text"
                    value={editArtist}
                    onChange={(e) => setEditArtist(e.target.value)}
                    style={inputStyle}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
                    Thể loại (genre)
                  </label>
                  <input
                    type="text"
                    value={editGenre}
                    onChange={(e) => setEditGenre(e.target.value)}
                    style={inputStyle}
                  />
                </div>
              </div>

              {/* Hàng 2: Bổ sung / Thay thế các file thành phần */}
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
                  gap: '14px',
                  marginBottom: '16px',
                }}
              >
                {/* 1. Bổ sung / Thay File Nhạc Beat Karaoke */}
                <div
                  style={{
                    backgroundColor: '#0A0A12',
                    padding: '12px',
                    borderRadius: '8px',
                    border:
                      editingSong.instrumentalUrl && editingSong.instrumentalUrl.trim()
                        ? '1px solid #1C1C2B'
                        : '1px dashed #f59e0b',
                  }}
                >
                  <label
                    style={{
                      display: 'block',
                      marginBottom: '6px',
                      fontSize: '13px',
                      fontWeight: 'bold',
                      color: '#B794FF',
                    }}
                  >
                    🎤 Bổ sung / Đổi File Nhạc Beat (.mp3)
                  </label>
                  {editingSong.instrumentalUrl && editingSong.instrumentalUrl.trim() && !removeInstrumental ? (
                    <div style={{ marginBottom: '8px' }}>
                      <div style={{ fontSize: '11px', color: '#A5A3BA', marginBottom: '4px' }}>
                        Đang có sẵn Beat trong MongoDB:
                      </div>
                      <audio
                        controls
                        src={editingSong.instrumentalUrl}
                        style={{ height: '30px', width: '100%', marginBottom: '6px' }}
                      />
                      <button
                        type="button"
                        onClick={() => {
                          setRemoveInstrumental(true);
                          setEditInstrumentalUrl('');
                        }}
                        style={{
                          padding: '3px 8px',
                          fontSize: '11px',
                          backgroundColor: 'transparent',
                          color: '#ff6b6b',
                          border: '1px solid #ff6b6b',
                          borderRadius: '4px',
                          cursor: 'pointer',
                        }}
                      >
                        ✕ Gỡ bỏ file Beat hiện tại
                      </button>
                    </div>
                  ) : (
                    <div style={{ fontSize: '11px', color: '#f59e0b', marginBottom: '6px' }}>
                      Chưa có file Beat riêng — Chọn file .mp3 bên dưới để bổ sung:
                    </div>
                  )}
                  <input
                    type="file"
                    accept="audio/*"
                    onChange={(e) => {
                      setEditInstrumentalFile(e.target.files?.[0] || null);
                      setRemoveInstrumental(false);
                    }}
                    style={inputStyle}
                  />
                </div>

                {/* 2. Bổ sung / Thay File Lời bài hát (.LRC / .SRT) */}
                <div
                  style={{
                    backgroundColor: '#0A0A12',
                    padding: '12px',
                    borderRadius: '8px',
                    border:
                      (editingSong.lyrics && editingSong.lyrics.trim()) ||
                      (editingSong.lyricsUrl && editingSong.lyricsUrl.trim())
                        ? '1px solid #1C1C2B'
                        : '1px dashed #f59e0b',
                  }}
                >
                  <label
                    style={{
                      display: 'block',
                      marginBottom: '6px',
                      fontSize: '13px',
                      fontWeight: 'bold',
                      color: '#B794FF',
                    }}
                  >
                    📝 Bổ sung / Đổi File Lyric (.lrc, .srt, .txt)
                  </label>
                  <div style={{ fontSize: '11px', color: '#A5A3BA', marginBottom: '6px' }}>
                    Chọn file .lrc hoặc .srt để tự động trích xuất lời vào khung bên dưới:
                  </div>
                  <input
                    type="file"
                    accept=".lrc,.srt,.vtt,.txt,text/plain"
                    onChange={(e) => handleEditLyricsFileChange(e.target.files?.[0])}
                    style={inputStyle}
                  />
                </div>

                {/* 3. Đổi Ảnh bìa (Tùy chọn) */}
                <div
                  style={{
                    backgroundColor: '#0A0A12',
                    padding: '12px',
                    borderRadius: '8px',
                    border: '1px solid #1C1C2B',
                  }}
                >
                  <label
                    style={{
                      display: 'block',
                      marginBottom: '6px',
                      fontSize: '13px',
                      color: '#A5A3BA',
                    }}
                  >
                    🖼️ Đổi Ảnh bìa mới (Để trống nếu giữ nguyên)
                  </label>
                  <div style={{ fontSize: '11px', color: '#888', marginBottom: '6px' }}>
                    Chỉ chọn khi bạn muốn thay ảnh bìa khác cho bài hát này:
                  </div>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(e) => setEditCoverFile(e.target.files?.[0] || null)}
                    style={inputStyle}
                  />
                </div>

                {/* 4. Đổi File Nhạc gốc (Tùy chọn) */}
                <div
                  style={{
                    backgroundColor: '#0A0A12',
                    padding: '12px',
                    borderRadius: '8px',
                    border: '1px solid #1C1C2B',
                  }}
                >
                  <label
                    style={{
                      display: 'block',
                      marginBottom: '6px',
                      fontSize: '13px',
                      color: '#A5A3BA',
                    }}
                  >
                    🎵 Đổi File Nhạc gốc .mp3 (Để trống nếu giữ nguyên)
                  </label>
                  <div style={{ fontSize: '11px', color: '#888', marginBottom: '6px' }}>
                    Chỉ chọn khi muốn thay thế file âm thanh gốc:
                  </div>
                  <input
                    type="file"
                    accept="audio/*"
                    onChange={(e) => handleEditAudioChange(e.target.files?.[0])}
                    style={inputStyle}
                  />
                </div>
              </div>

              {/* Hàng 3: Soạn thảo trực tiếp nội dung lời bài hát (.LRC / .SRT) */}
              <div style={{ marginBottom: '16px' }}>
                <label
                  style={{
                    display: 'block',
                    marginBottom: '6px',
                    fontSize: '13px',
                    color: '#A5A3BA',
                  }}
                >
                  Nội dung lời bài hát lưu trong MongoDB (Hỗ trợ <code>.LRC [mm:ss.xx]</code>, <code>.SRT</code> hoặc văn bản)
                </label>
                <textarea
                  rows={5}
                  value={editLyricsText}
                  onChange={(e) => setEditLyricsText(e.target.value)}
                  placeholder="Dán nội dung lời bài hát .LRC hoặc .SRT vào đây, hoặc chọn file ở ô phía trên..."
                  style={{
                    ...inputStyle,
                    fontFamily: 'monospace',
                    fontSize: '13px',
                    resize: 'vertical',
                  }}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button
                  type="button"
                  onClick={() => setEditingSong(null)}
                  style={{
                    padding: '10px 20px',
                    backgroundColor: '#1C1C2B',
                    color: '#fff',
                    border: '1px solid #444',
                    borderRadius: '20px',
                    cursor: 'pointer',
                  }}
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  disabled={isUpdatingSong}
                  style={{
                    padding: '10px 26px',
                    backgroundColor: isUpdatingSong ? '#555' : '#f59e0b',
                    color: '#000',
                    fontWeight: 'bold',
                    border: 'none',
                    borderRadius: '20px',
                    cursor: isUpdatingSong ? 'not-allowed' : 'pointer',
                  }}
                >
                  {isUpdatingSong
                    ? 'Đang cập nhật lên MongoDB...'
                    : '💾 Lưu cập nhật vào MongoDB'}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* TRÌNH PHÁT & ĐỒNG BỘ LYRIC (.LRC) TRỰC TIẾP */}
        {activeSong && (
          <div
            style={{
              backgroundColor: '#12121D',
              borderRadius: '12px',
              border: '1px solid #B794FF',
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
                  <div style={{ color: '#B794FF', fontSize: '12px', fontWeight: 'bold' }}>
                    🎤 TRÌNH CHẠY & ĐỒNG BỘ LỜI BÀI HÁT (.LRC / .SRT)
                  </div>
                  <h3 style={{ margin: '4px 0 2px 0' }}>{activeSong.title}</h3>
                  <div style={{ color: '#A5A3BA', fontSize: '13px' }}>
                    {activeSong.artist} • {activeSong.genre}
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                {activeSong.instrumentalUrl && activeSong.instrumentalUrl.trim() && (
                  <div
                    style={{
                      display: 'flex',
                      backgroundColor: '#1C1C2B',
                      borderRadius: '20px',
                      padding: '3px',
                      border: '1px solid #333',
                    }}
                  >
                    <button
                      type="button"
                      onClick={() => setStudioAudioMode('vocal')}
                      style={{
                        padding: '5px 12px',
                        borderRadius: '16px',
                        border: 'none',
                        fontSize: '12px',
                        fontWeight: 'bold',
                        cursor: 'pointer',
                        backgroundColor:
                          studioAudioMode === 'vocal' ? '#B794FF' : 'transparent',
                        color: studioAudioMode === 'vocal' ? '#000' : '#ccc',
                      }}
                    >
                      🔊 Nhạc có lời
                    </button>
                    <button
                      type="button"
                      onClick={() => setStudioAudioMode('beat')}
                      style={{
                        padding: '5px 12px',
                        borderRadius: '16px',
                        border: 'none',
                        fontSize: '12px',
                        fontWeight: 'bold',
                        cursor: 'pointer',
                        backgroundColor:
                          studioAudioMode === 'beat' ? '#B794FF' : 'transparent',
                        color: studioAudioMode === 'beat' ? '#000' : '#ccc',
                      }}
                    >
                      🎵 Nhạc Beat
                    </button>
                  </div>
                )}
                <audio
                  ref={audioRef}
                  controls
                  src={
                    studioAudioMode === 'beat' &&
                    activeSong.instrumentalUrl &&
                    activeSong.instrumentalUrl.trim()
                      ? activeSong.instrumentalUrl
                      : activeSong.audioUrl
                  }
                  onTimeUpdate={(e) => setCurrentTime(e.currentTarget.currentTime)}
                  style={{ height: '38px', width: '260px' }}
                />
                <button
                  onClick={() => setActiveSong(null)}
                  style={{
                    padding: '8px 14px',
                    backgroundColor: '#1C1C2B',
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
                  backgroundColor: '#0A0A12',
                  borderRadius: '10px',
                  padding: '16px',
                  border: '1px solid #1C1C2B',
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    marginBottom: '10px',
                    fontSize: '13px',
                    color: '#A5A3BA',
                  }}
                >
                  <span>Màn hình chạy Lyric (Bấm vào câu bất kỳ để tua nhạc)</span>
                  <span style={{ color: '#B794FF', fontWeight: 'bold' }}>
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
                      const isTapTarget = index === tapSyncIndex;
                      return (
                        <div
                          key={`${line.timeSec}-${index}`}
                          onClick={() => {
                            setTapSyncIndex(index);
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
                              ? 'rgba(183, 148, 255, 0.14)'
                              : 'transparent',
                            borderLeft: isTapTarget
                              ? '3px solid #f59e0b'
                              : '3px solid transparent',
                            color: isCurrent ? '#B794FF' : '#A5A3BA',
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
                  backgroundColor: '#0A0A12',
                  borderRadius: '10px',
                  padding: '16px',
                  border: '1px solid #1C1C2B',
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
                  <span style={{ fontSize: '13px', color: '#A5A3BA' }}>
                    Soạn thảo lời (<code>.LRC</code> / <code>.SRT</code> / văn bản)
                  </span>
                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                    <button
                      type="button"
                      onClick={handleInsertCurrentTimestamp}
                      style={{
                        padding: '5px 10px',
                        fontSize: '12px',
                        backgroundColor: '#1C1C2B',
                        color: '#B794FF',
                        border: '1px solid #B794FF',
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
                        backgroundColor: '#1C1C2B',
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

                {/* THANH CÔNG CỤ SỬA LỆCH NHỊP NHANH (SHIFT TIMESTAMPS & TAP-TO-SYNC) */}
                {parsedLines.length > 0 && (
                  <div
                    style={{
                      backgroundColor: '#1a1a1a',
                      border: '1px solid #333',
                      borderRadius: '8px',
                      padding: '8px 10px',
                      marginBottom: '10px',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '8px',
                    }}
                  >
                    {/* 1. Dịch đồng loạt toàn bộ mốc thời gian của bài hát */}
                    <div
                      style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        flexWrap: 'wrap',
                        gap: '6px',
                      }}
                    >
                      <span style={{ fontSize: '12px', color: '#ccc' }}>
                        ⏱ <b>Sửa lệch toàn bài:</b>
                      </span>
                      <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                        <button
                          type="button"
                          onClick={() => handleShiftAllTimestamps(-1.0)}
                          title="Kéo toàn bộ lời hiện sớm hơn 1 giây"
                          style={{
                            padding: '4px 8px',
                            fontSize: '11px',
                            backgroundColor: '#1C1C2B',
                            color: '#f59e0b',
                            border: '1px solid #f59e0b',
                            borderRadius: '5px',
                            cursor: 'pointer',
                          }}
                        >
                          ⏪ -1.0s (Sớm hơn)
                        </button>
                        <button
                          type="button"
                          onClick={() => handleShiftAllTimestamps(-0.5)}
                          title="Kéo toàn bộ lời hiện sớm hơn 0.5 giây"
                          style={{
                            padding: '4px 8px',
                            fontSize: '11px',
                            backgroundColor: '#1C1C2B',
                            color: '#f59e0b',
                            border: '1px solid #f59e0b',
                            borderRadius: '5px',
                            cursor: 'pointer',
                          }}
                        >
                          ◀ -0.5s
                        </button>
                        <button
                          type="button"
                          onClick={() => handleShiftAllTimestamps(0.5)}
                          title="Đẩy toàn bộ lời hiện trễ hơn 0.5 giây"
                          style={{
                            padding: '4px 8px',
                            fontSize: '11px',
                            backgroundColor: '#1C1C2B',
                            color: '#38bdf8',
                            border: '1px solid #38bdf8',
                            borderRadius: '5px',
                            cursor: 'pointer',
                          }}
                        >
                          +0.5s ▶
                        </button>
                        <button
                          type="button"
                          onClick={() => handleShiftAllTimestamps(1.0)}
                          title="Đẩy toàn bộ lời hiện trễ hơn 1 giây"
                          style={{
                            padding: '4px 8px',
                            fontSize: '11px',
                            backgroundColor: '#1C1C2B',
                            color: '#38bdf8',
                            border: '1px solid #38bdf8',
                            borderRadius: '5px',
                            cursor: 'pointer',
                          }}
                        >
                          +1.0s (Trễ hơn) ⏩
                        </button>
                      </div>
                    </div>

                    {/* 2. Bấm nhịp trực tiếp từng câu theo nhạc đang phát (Tap-to-Sync) */}
                    <div
                      style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        flexWrap: 'wrap',
                        gap: '8px',
                        borderTop: '1px solid #1C1C2B',
                        paddingTop: '6px',
                      }}
                    >
                      <div style={{ fontSize: '12px', color: '#A5A3BA', flex: 1 }}>
                        🎯 Câu chờ chấm nhịp (#{tapSyncIndex + 1}/{parsedLines.length}):{' '}
                        <b style={{ color: '#B794FF' }}>
                          {parsedLines[tapSyncIndex]?.text || ''}
                        </b>
                      </div>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button
                          type="button"
                          onClick={() => setTapSyncIndex(0)}
                          style={{
                            padding: '4px 8px',
                            fontSize: '11px',
                            backgroundColor: '#1C1C2B',
                            color: '#ccc',
                            border: '1px solid #444',
                            borderRadius: '5px',
                            cursor: 'pointer',
                          }}
                        >
                          Về câu #1
                        </button>
                        <button
                          type="button"
                          onClick={handleTapSyncNextLine}
                          style={{
                            padding: '5px 12px',
                            fontSize: '12px',
                            fontWeight: 'bold',
                            backgroundColor: '#B794FF',
                            color: '#000',
                            border: 'none',
                            borderRadius: '6px',
                            cursor: 'pointer',
                          }}
                        >
                          🎯 Bấm vào câu #{tapSyncIndex + 1} ({formatLrcTimestamp(currentTime)})
                        </button>
                        <button
                          type="button"
                          onClick={handleTapEndCurrentLine}
                          title="Bấm ngay khi ca sĩ vừa hát xong câu đang phát để khóa tốc độ nhanh/chậm của câu đó"
                          style={{
                            padding: '5px 12px',
                            fontSize: '12px',
                            fontWeight: 'bold',
                            backgroundColor: '#f59e0b',
                            color: '#000',
                            border: 'none',
                            borderRadius: '6px',
                            cursor: 'pointer',
                          }}
                        >
                          ✂️ Chốt ngắt câu đang hát ({formatLrcTimestamp(currentTime)})
                        </button>
                      </div>
                    </div>
                  </div>
                )}

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
                    backgroundColor: '#161624',
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
                  <span style={{ color: '#B794FF', fontSize: '13px' }}>
                    {saveMessage}
                  </span>
                  <button
                    type="button"
                    disabled={isSavingLyrics}
                    onClick={handleSaveLyrics}
                    style={{
                      padding: '8px 18px',
                      backgroundColor: '#B794FF',
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
              backgroundColor: '#1C1C2B',
              color: '#fff',
            }}
          />
        </div>

        {/* Bảng hiển thị danh sách bài hát */}
        <div
          style={{
            backgroundColor: '#12121D',
            borderRadius: '10px',
            border: '1px solid #1C1C2B',
            overflowX: 'auto',
          }}
        >
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #1C1C2B', color: '#A5A3BA', fontSize: '13px' }}>
                <th style={{ padding: '14px' }}>Ảnh bìa</th>
                <th style={{ padding: '14px' }}>Tên bài hát</th>
                <th style={{ padding: '14px' }}>Nghệ sĩ</th>
                <th style={{ padding: '14px' }}>Nhạc Beat (Karaoke)</th>
                <th style={{ padding: '14px' }}>Lời bài hát (.lrc/.srt)</th>
                <th style={{ padding: '14px' }}>Lượt nghe</th>
                <th style={{ padding: '14px' }}>Nghe thử</th>
                <th style={{ padding: '14px', textAlign: 'right' }}>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan="8" style={{ padding: '24px', textAlign: 'center', color: '#A5A3BA' }}>
                    Đang tải danh sách bài hát...
                  </td>
                </tr>
              ) : songs.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ padding: '24px', textAlign: 'center', color: '#A5A3BA' }}>
                    Chưa có bài hát nào.
                  </td>
                </tr>
              ) : (
                songs.map((song) => {
                  const hasLyrics = Boolean(
                    (song.lyrics && song.lyrics.trim()) ||
                      (song.lyricsUrl && song.lyricsUrl.trim())
                  );
                  const hasBeat = Boolean(
                    song.instrumentalUrl && song.instrumentalUrl.trim()
                  );
                  const isSelected =
                    activeSong?._id === song._id || editingSong?._id === song._id;

                  return (
                    <tr
                      key={song._id}
                      style={{
                        borderBottom: '1px solid #222',
                        backgroundColor: isSelected
                          ? 'rgba(183, 148, 255, 0.08)'
                          : 'transparent',
                      }}
                    >
                      <td style={{ padding: '12px 14px' }}>
                        <img
                          src={song.coverUrl}
                          alt={song.title}
                          style={{
                            width: '48px',
                            height: '48px',
                            borderRadius: '6px',
                            objectFit: 'cover',
                          }}
                        />
                      </td>
                      <td style={{ padding: '12px 14px' }}>
                        <div style={{ fontWeight: 'bold' }}>{song.title}</div>
                        <div style={{ fontSize: '11px', color: '#888', marginTop: '2px' }}>
                          {song.genre}
                        </div>
                      </td>
                      <td style={{ padding: '12px 14px', color: '#A5A3BA' }}>
                        <Link
                          to="/artists"
                          title="Xem & Đổi ảnh đại diện của ca sĩ/nghệ sĩ này"
                          style={{
                            color: '#B794FF',
                            textDecoration: 'none',
                            fontWeight: '500',
                          }}
                        >
                          {song.artist} ↗
                        </Link>
                      </td>
                      {/* Cột trạng thái Nhạc Beat Karaoke */}
                      <td style={{ padding: '12px 14px' }}>
                        <button
                          type="button"
                          onClick={() => openEditModal(song)}
                          title={
                            hasBeat
                              ? 'Đã có nhạc Beat Karaoke (Bấm để nghe hoặc thay đổi)'
                              : 'Bấm để bổ sung file nhạc Beat Karaoke cho bài hát này'
                          }
                          style={{
                            padding: '6px 12px',
                            backgroundColor: hasBeat
                              ? 'rgba(183, 148, 255, 0.18)'
                              : 'rgba(245, 158, 11, 0.14)',
                            color: hasBeat ? '#B794FF' : '#f59e0b',
                            border: `1px solid ${hasBeat ? '#B794FF' : '#f59e0b'}`,
                            borderRadius: '16px',
                            fontSize: '12px',
                            fontWeight: 'bold',
                            cursor: 'pointer',
                          }}
                        >
                          {hasBeat ? '🎵 Đã có Beat' : '+ Bổ sung Beat'}
                        </button>
                      </td>
                      {/* Cột trạng thái Lời bài hát */}
                      <td style={{ padding: '12px 14px' }}>
                        <button
                          type="button"
                          onClick={() => openLyricsStudio(song, true)}
                          style={{
                            padding: '6px 12px',
                            backgroundColor: hasLyrics
                              ? 'rgba(183, 148, 255, 0.18)'
                              : 'rgba(245, 158, 11, 0.14)',
                            color: hasLyrics ? '#B794FF' : '#f59e0b',
                            border: `1px solid ${hasLyrics ? '#B794FF' : '#f59e0b'}`,
                            borderRadius: '16px',
                            fontSize: '12px',
                            fontWeight: 'bold',
                            cursor: 'pointer',
                          }}
                        >
                          {hasLyrics ? '🎤 Chạy / Sửa Lyric' : '+ Thêm Lyric'}
                        </button>
                      </td>
                      <td style={{ padding: '12px 14px', color: '#A5A3BA' }}>
                        {song.playCount || 0}
                      </td>
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
                          style={{ height: '32px', width: '170px' }}
                        />
                      </td>
                      <td style={{ padding: '12px 14px', textAlign: 'right' }}>
                        <div
                          style={{
                            display: 'flex',
                            justifyContent: 'flex-end',
                            gap: '8px',
                          }}
                        >
                          <button
                            type="button"
                            onClick={() => openEditModal(song)}
                            style={{
                              padding: '6px 12px',
                              backgroundColor: '#f59e0b',
                              color: '#000',
                              fontWeight: 'bold',
                              border: 'none',
                              borderRadius: '4px',
                              cursor: 'pointer',
                              fontSize: '12px',
                            }}
                          >
                            ✏️ Sửa / Bổ sung
                          </button>
                          <button
                            type="button"
                            onClick={() => handleDelete(song._id, song.title)}
                            style={{
                              padding: '6px 12px',
                              backgroundColor: '#F43F5E',
                              color: '#fff',
                              border: 'none',
                              borderRadius: '4px',
                              cursor: 'pointer',
                              fontSize: '12px',
                            }}
                          >
                            Xoá
                          </button>
                        </div>
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
