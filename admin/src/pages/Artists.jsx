import React, { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import { getArtists, updateArtist, deleteArtist } from '../api';

export default function Artists() {
  const [artists, setArtists] = useState([]);
  const [search, setSearch] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  // State cho Modal thay đổi ảnh nghệ sĩ
  const [editingArtist, setEditingArtist] = useState(null);
  const [avatarFile, setAvatarFile] = useState(null);
  const [avatarUrlInput, setAvatarUrlInput] = useState('');
  const [bioInput, setBioInput] = useState('');
  const [previewUrl, setPreviewUrl] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [msg, setMsg] = useState({ type: '', text: '' });

  // State cho modal tạo mới nghệ sĩ
  const [isAddingNew, setIsAddingNew] = useState(false);
  const [newArtistName, setNewArtistName] = useState('');

  const fetchArtistsList = async (keyword = '') => {
    try {
      setIsLoading(true);
      const data = await getArtists(keyword);
      const list = Array.isArray(data) ? data : data?.artists || [];
      setArtists(list);
    } catch (err) {
      console.error('Lỗi tải danh sách nghệ sĩ:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchArtistsList();
  }, []);

  const openEditModal = (artist) => {
    setEditingArtist(artist);
    setIsAddingNew(false);
    setNewArtistName(artist.name);
    setAvatarUrlInput(artist.avatarUrl || '');
    setBioInput(artist.bio || '');
    setPreviewUrl(artist.avatarUrl || '');
    setAvatarFile(null);
    setMsg({ type: '', text: '' });
  };

  const openAddNewModal = () => {
    setEditingArtist(null);
    setIsAddingNew(true);
    setNewArtistName('');
    setAvatarUrlInput('');
    setBioInput('');
    setPreviewUrl('');
    setAvatarFile(null);
    setMsg({ type: '', text: '' });
  };

  const closeModal = () => {
    setEditingArtist(null);
    setIsAddingNew(false);
    setAvatarFile(null);
    setPreviewUrl('');
    setMsg({ type: '', text: '' });
  };

  const handleFileChange = (e) => {
    const file = e.target.files?.[0];
    if (file) {
      setAvatarFile(file);
      const objectUrl = URL.createObjectURL(file);
      setPreviewUrl(objectUrl);
    }
  };

  const handleUrlChange = (e) => {
    const url = e.target.value;
    setAvatarUrlInput(url);
    if (!avatarFile) {
      setPreviewUrl(url);
    }
  };

  const handleSave = async (e) => {
    e.preventDefault();
    const targetName = (isAddingNew ? newArtistName : editingArtist?.name || '').trim();

    if (!targetName) {
      setMsg({ type: 'error', text: 'Vui lòng nhập tên nghệ sĩ/ca sĩ!' });
      return;
    }

    try {
      setIsSubmitting(true);
      setMsg({ type: '', text: '' });

      // Nếu có chọn file ảnh từ máy -> gửi dạng FormData multipart
      if (avatarFile) {
        const formData = new FormData();
        formData.append('name', targetName);
        formData.append('avatar', avatarFile);
        if (bioInput) formData.append('bio', bioInput);
        await updateArtist(formData);
      } else {
        // Gửi link ảnh hoặc bio dạng JSON
        await updateArtist({
          name: targetName,
          avatarUrl: avatarUrlInput.trim(),
          bio: bioInput.trim(),
        });
      }

      setMsg({ type: 'success', text: '✔ Cập nhật ảnh đại diện thành công!' });
      setTimeout(() => {
        closeModal();
        fetchArtistsList(search);
      }, 700);
    } catch (err) {
      setMsg({
        type: 'error',
        text: err.response?.data?.message || 'Có lỗi xảy ra khi lưu ảnh nghệ sĩ!',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleResetToDefault = async (artist) => {
    if (!artist._id) return;
    if (
      !window.confirm(
        `Bạn có chắc muốn xóa ảnh đại diện tùy chỉnh của "${artist.name}" để dùng ảnh mặc định?`
      )
    )
      return;

    try {
      await deleteArtist(artist._id);
      fetchArtistsList(search);
    } catch (err) {
      alert(err.response?.data?.message || 'Lỗi khi đặt lại ảnh nghệ sĩ');
    }
  };

  const customCount = artists.filter((a) => a.hasCustomAvatar).length;

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#0A0A12', color: '#fff' }}>
      <Navbar />

      <main style={{ maxWidth: '1140px', margin: '0 auto', padding: '24px' }}>
        {/* Thanh tiêu đề và chức năng */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: '20px',
            flexWrap: 'wrap',
            gap: '14px',
          }}
        >
          <div>
            <h2 style={{ margin: '0 0 6px 0', fontSize: '24px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              🎤 Quản lý Nghệ sĩ & Ca sĩ
            </h2>
            <div style={{ color: '#A5A3BA', fontSize: '13px' }}>
              Tổng cộng <b>{artists.length}</b> nghệ sĩ ({customCount} đã có ảnh chân dung riêng,{' '}
              {artists.length - customCount} dùng bìa bài hát)
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <input
              type="text"
              placeholder="Tìm kiếm ca sĩ / nghệ sĩ..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                fetchArtistsList(e.target.value);
              }}
              style={{
                width: '240px',
                padding: '9px 14px',
                borderRadius: '20px',
                border: '1px solid #333',
                backgroundColor: '#1C1C2B',
                color: '#fff',
                fontSize: '13px',
              }}
            />
            <button
              onClick={openAddNewModal}
              style={{
                padding: '9px 18px',
                backgroundColor: '#B794FF',
                color: '#000',
                border: 'none',
                borderRadius: '20px',
                fontWeight: 'bold',
                fontSize: '13px',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
              }}
            >
              + Thêm nghệ sĩ mới
            </button>
          </div>
        </div>

        {/* Danh sách nghệ sĩ theo dạng Card Grid */}
        {isLoading ? (
          <div style={{ textAlign: 'center', padding: '60px 0', color: '#A5A3BA' }}>
            Đang tải danh sách nghệ sĩ...
          </div>
        ) : artists.length === 0 ? (
          <div
            style={{
              textAlign: 'center',
              padding: '60px 0',
              backgroundColor: '#12121D',
              borderRadius: '12px',
              border: '1px solid #1C1C2B',
              color: '#A5A3BA',
            }}
          >
            Chưa có nghệ sĩ nào phù hợp.
          </div>
        ) : (
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))',
              gap: '18px',
            }}
          >
            {artists.map((artist) => (
              <div
                key={artist._id || artist.name}
                style={{
                  backgroundColor: '#12121D',
                  borderRadius: '12px',
                  padding: '20px',
                  border: artist.hasCustomAvatar ? '1px solid #B794FF' : '1px solid #1C1C2B',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  textAlign: 'center',
                  position: 'relative',
                  transition: 'transform 0.2s ease',
                }}
              >
                {/* Ảnh đại diện nghệ sĩ */}
                <div
                  style={{
                    position: 'relative',
                    width: '110px',
                    height: '110px',
                    marginBottom: '14px',
                  }}
                >
                  <img
                    src={artist.avatarUrl || 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200'}
                    alt={artist.name}
                    style={{
                      width: '110px',
                      height: '110px',
                      borderRadius: '50%',
                      objectFit: 'cover',
                      border: '3px solid #1C1C2B',
                    }}
                    onError={(e) => {
                      e.target.src = 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200';
                    }}
                  />
                  <button
                    onClick={() => openEditModal(artist)}
                    title="Đổi ảnh đại diện"
                    style={{
                      position: 'absolute',
                      right: '0',
                      bottom: '0',
                      backgroundColor: '#B794FF',
                      color: '#000',
                      border: '2px solid #12121D',
                      borderRadius: '50%',
                      width: '32px',
                      height: '32px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      cursor: 'pointer',
                      fontSize: '14px',
                    }}
                  >
                    📷
                  </button>
                </div>

                {/* Tên nghệ sĩ */}
                <h3
                  style={{
                    margin: '0 0 6px 0',
                    fontSize: '17px',
                    fontWeight: 'bold',
                    maxWidth: '100%',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap',
                  }}
                >
                  {artist.name}
                </h3>

                {/* Badge trạng thái ảnh */}
                <div style={{ marginBottom: '10px' }}>
                  {artist.hasCustomAvatar ? (
                    <span
                      style={{
                        fontSize: '11px',
                        padding: '3px 8px',
                        borderRadius: '12px',
                        backgroundColor: 'rgba(183, 148, 255, 0.15)',
                        color: '#B794FF',
                        fontWeight: '600',
                      }}
                    >
                      ✔ Ảnh chân dung riêng
                    </span>
                  ) : (
                    <span
                      style={{
                        fontSize: '11px',
                        padding: '3px 8px',
                        borderRadius: '12px',
                        backgroundColor: '#1C1C2B',
                        color: '#888',
                      }}
                    >
                      Ảnh bài hát (tạm)
                    </span>
                  )}
                </div>

                {/* Thông tin số lượng bài hát và lượt nghe */}
                <div style={{ fontSize: '13px', color: '#A5A3BA', marginBottom: '14px' }}>
                  🎵 <b>{artist.songCount}</b> bài hát • 🎧 <b>{artist.totalPlayCount}</b> lượt nghe
                </div>

                {artist.bio && (
                  <div
                    style={{
                      fontSize: '12px',
                      color: '#777',
                      marginBottom: '14px',
                      fontStyle: 'italic',
                      display: '-webkit-box',
                      WebkitLineClamp: 2,
                      WebkitBoxOrient: 'vertical',
                      overflow: 'hidden',
                    }}
                  >
                    "{artist.bio}"
                  </div>
                )}

                {/* Nút hành động */}
                <div style={{ display: 'flex', gap: '8px', marginTop: 'auto', width: '100%' }}>
                  <button
                    onClick={() => openEditModal(artist)}
                    style={{
                      flex: 1,
                      padding: '8px 12px',
                      backgroundColor: '#1C1C2B',
                      color: '#B794FF',
                      border: '1px solid #B794FF',
                      borderRadius: '6px',
                      fontSize: '12px',
                      fontWeight: 'bold',
                      cursor: 'pointer',
                    }}
                  >
                    Thay ảnh
                  </button>

                  {artist.hasCustomAvatar && artist._id && (
                    <button
                      onClick={() => handleResetToDefault(artist)}
                      title="Đặt lại ảnh mặc định"
                      style={{
                        padding: '8px 10px',
                        backgroundColor: '#222',
                        color: '#888',
                        border: '1px solid #444',
                        borderRadius: '6px',
                        fontSize: '12px',
                        cursor: 'pointer',
                      }}
                    >
                      Đặt lại
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* MODAL THAY ĐỔI ẢNH ĐẠI DIỆN NGHỆ SĨ */}
        {(editingArtist || isAddingNew) && (
          <div
            style={{
              position: 'fixed',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              backgroundColor: 'rgba(0, 0, 0, 0.75)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              zIndex: 1000,
              padding: '16px',
            }}
          >
            <div
              style={{
                backgroundColor: '#161624',
                borderRadius: '14px',
                border: '1px solid #333',
                maxWidth: '480px',
                width: '100%',
                padding: '24px',
                boxSizing: 'border-box',
              }}
            >
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  marginBottom: '16px',
                }}
              >
                <h3 style={{ margin: 0, fontSize: '18px', color: '#B794FF' }}>
                  {isAddingNew
                    ? '+ Thêm Nghệ sĩ / Ca sĩ mới'
                    : `📷 Thay ảnh đại diện: ${editingArtist?.name}`}
                </h3>
                <button
                  onClick={closeModal}
                  style={{
                    background: 'none',
                    border: 'none',
                    color: '#888',
                    fontSize: '18px',
                    cursor: 'pointer',
                  }}
                >
                  ✕
                </button>
              </div>

              {msg.text && (
                <div
                  style={{
                    padding: '10px 14px',
                    borderRadius: '8px',
                    marginBottom: '14px',
                    fontSize: '13px',
                    backgroundColor: msg.type === 'success' ? 'rgba(183, 148, 255, 0.2)' : 'rgba(233, 20, 41, 0.2)',
                    color: msg.type === 'success' ? '#B794FF' : '#ff6b6b',
                    border: `1px solid ${msg.type === 'success' ? '#B794FF' : '#F43F5E'}`,
                  }}
                >
                  {msg.text}
                </div>
              )}

              <form onSubmit={handleSave}>
                {/* Xem trước ảnh chân dung */}
                <div
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    marginBottom: '18px',
                  }}
                >
                  <div
                    style={{
                      width: '120px',
                      height: '120px',
                      borderRadius: '50%',
                      border: '3px solid #B794FF',
                      overflow: 'hidden',
                      marginBottom: '8px',
                      backgroundColor: '#1C1C2B',
                    }}
                  >
                    <img
                      src={
                        previewUrl ||
                        'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200'
                      }
                      alt="Preview"
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      onError={(e) => {
                        e.target.src = 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200';
                      }}
                    />
                  </div>
                  <span style={{ fontSize: '12px', color: '#888' }}>Xem trước ảnh đại diện</span>
                </div>

                {isAddingNew && (
                  <div style={{ marginBottom: '14px' }}>
                    <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
                      Tên ca sĩ / nghệ sĩ *
                    </label>
                    <input
                      type="text"
                      placeholder="VD: Vũ, Chillies, HIEUTHUHAI..."
                      value={newArtistName}
                      onChange={(e) => setNewArtistName(e.target.value)}
                      required
                      style={{
                        width: '100%',
                        boxSizing: 'border-box',
                        padding: '10px',
                        borderRadius: '6px',
                        border: '1px solid #333',
                        backgroundColor: '#1C1C2B',
                        color: '#fff',
                        fontSize: '13px',
                      }}
                    />
                  </div>
                )}

                {/* Chọn file ảnh từ máy */}
                <div style={{ marginBottom: '14px' }}>
                  <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
                    Cách 1: Chọn ảnh từ máy tính (Tải lên Cloudinary)
                  </label>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleFileChange}
                    style={{
                      width: '100%',
                      boxSizing: 'border-box',
                      padding: '8px',
                      borderRadius: '6px',
                      border: '1px solid #333',
                      backgroundColor: '#1C1C2B',
                      color: '#fff',
                      fontSize: '13px',
                    }}
                  />
                </div>

                {/* Hoặc nhập link ảnh */}
                <div style={{ marginBottom: '14px' }}>
                  <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
                    Cách 2: Hoặc dán đường dẫn (URL) ảnh chân dung
                  </label>
                  <input
                    type="url"
                    placeholder="https://example.com/avatar.jpg"
                    value={avatarUrlInput}
                    onChange={handleUrlChange}
                    style={{
                      width: '100%',
                      boxSizing: 'border-box',
                      padding: '10px',
                      borderRadius: '6px',
                      border: '1px solid #333',
                      backgroundColor: '#1C1C2B',
                      color: '#fff',
                      fontSize: '13px',
                    }}
                  />
                </div>

                {/* Tiểu sử nghệ sĩ */}
                <div style={{ marginBottom: '20px' }}>
                  <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#A5A3BA' }}>
                    Giới thiệu / Tiểu sử ngắn (Tùy chọn)
                  </label>
                  <textarea
                    rows={3}
                    placeholder="Giới thiệu về phong cách âm nhạc, dấu ấn nghệ thuật..."
                    value={bioInput}
                    onChange={(e) => setBioInput(e.target.value)}
                    style={{
                      width: '100%',
                      boxSizing: 'border-box',
                      padding: '10px',
                      borderRadius: '6px',
                      border: '1px solid #333',
                      backgroundColor: '#1C1C2B',
                      color: '#fff',
                      fontSize: '13px',
                      resize: 'vertical',
                    }}
                  />
                </div>

                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                  <button
                    type="button"
                    onClick={closeModal}
                    style={{
                      padding: '10px 18px',
                      backgroundColor: '#1C1C2B',
                      color: '#fff',
                      border: '1px solid #444',
                      borderRadius: '20px',
                      cursor: 'pointer',
                      fontSize: '13px',
                    }}
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmitting}
                    style={{
                      padding: '10px 22px',
                      backgroundColor: isSubmitting ? '#555' : '#B794FF',
                      color: '#000',
                      border: 'none',
                      borderRadius: '20px',
                      fontWeight: 'bold',
                      cursor: isSubmitting ? 'not-allowed' : 'pointer',
                      fontSize: '13px',
                    }}
                  >
                    {isSubmitting ? 'Đang tải lên...' : '💾 Lưu ảnh đại diện'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

