import React from 'react';
import { useNavigate, useLocation, Link } from 'react-router-dom';

export default function Navbar() {
  const navigate = useNavigate();
  const location = useLocation();
  const userStr = localStorage.getItem('user');
  const user = userStr ? JSON.parse(userStr) : null;

  // Hàm xử lý đăng xuất
  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/login');
  };

  const isSongsActive = location.pathname === '/songs' || location.pathname === '/';
  const isArtistsActive = location.pathname === '/artists';
  const initial = user?.name ? user.name.trim().charAt(0).toUpperCase() : 'A';

  return (
    <header className="app-nav">
      <div className="app-brand">
        <div className="app-brand-logo">♫</div>
        <div>
          Music Studio
          <small>Bảng quản trị</small>
        </div>
      </div>

      <nav className="app-links">
        <Link to="/songs" className={`app-link ${isSongsActive ? 'active' : ''}`}>
          🎵 Bài hát
        </Link>
        <Link to="/artists" className={`app-link ${isArtistsActive ? 'active' : ''}`}>
          🎤 Nghệ sĩ
        </Link>
      </nav>

      <div className="app-user">
        {user && (
          <>
            <div className="app-avatar">{initial}</div>
            <span>{user.name}</span>
          </>
        )}
        <button className="btn-ghost-danger" onClick={handleLogout}>
          Đăng xuất
        </button>
      </div>
    </header>
  );
}
