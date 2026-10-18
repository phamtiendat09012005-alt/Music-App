import React from 'react';
import { useNavigate } from 'react-router-dom';

export default function Navbar() {
  const navigate = useNavigate();
  const userStr = localStorage.getItem('user');
  const user = userStr ? JSON.parse(userStr) : null;

  // Hàm xử lý đăng xuất
  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/login');
  };

  return (
    <header
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '14px 28px',
        backgroundColor: '#181818',
        borderBottom: '1px solid #282828',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
        <span style={{ fontSize: '22px', fontWeight: 'bold', color: '#1DB954' }}>
          🎵 Music App Admin
        </span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        {user && <span style={{ color: '#b3b3b3' }}>Xin chào, {user.name}</span>}
        <button
          onClick={handleLogout}
          style={{
            padding: '8px 16px',
            backgroundColor: '#e91429',
            color: '#fff',
            border: 'none',
            borderRadius: '6px',
            cursor: 'pointer',
            fontWeight: 'bold',
          }}
        >
          Đăng xuất
        </button>
      </div>
    </header>
  );
}