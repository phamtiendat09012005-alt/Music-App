import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { loginAdmin } from '../api';

export default function Login() {
  const [email, setEmail] = useState('admin@music.com');
  const [password, setPassword] = useState('123456');
  const [errorMsg, setErrorMsg] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setErrorMsg('');
    try {
      setIsLoading(true);
      const data = await loginAdmin(email, password);

      // Kiểm tra quyền admin theo Mục 7
      if (data.user && data.user.role !== 'admin') {
        setErrorMsg('Tài khoản này không có quyền Admin!');
        return;
      }

      // Lưu token vào localStorage theo Mục 5
      localStorage.setItem('token', data.token);
      localStorage.setItem('user', JSON.stringify(data.user));
      navigate('/songs');
    } catch (err) {
      setErrorMsg(err.response?.data?.message || 'Đăng nhập thất bại!');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#121212',
      }}
    >
      <div
        style={{
          width: '380px',
          padding: '32px',
          backgroundColor: '#181818',
          borderRadius: '12px',
          border: '1px solid #282828',
        }}
      >
        <h2 style={{ textAlign: 'center', color: '#1DB954', marginTop: 0 }}>
          🎵 Music App Admin
        </h2>
        <p style={{ textAlign: 'center', color: '#b3b3b3', fontSize: '13px', marginBottom: '20px' }}>
          Đăng nhập quản trị hệ thống bài hát
        </p>

        {errorMsg && (
          <div
            style={{
              backgroundColor: '#3b181b',
              color: '#ff6b6b',
              padding: '10px',
              borderRadius: '6px',
              marginBottom: '16px',
              fontSize: '13px',
            }}
          >
            {errorMsg}
          </div>
        )}

        <form onSubmit={handleLogin}>
          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#b3b3b3' }}>
              Email
            </label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              style={{
                width: '100%',
                padding: '10px',
                borderRadius: '6px',
                border: '1px solid #333',
                backgroundColor: '#242424',
                color: '#fff',
                boxSizing: 'border-box',
              }}
            />
          </div>

          <div style={{ marginBottom: '22px' }}>
            <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#b3b3b3' }}>
              Mật khẩu
            </label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              style={{
                width: '100%',
                padding: '10px',
                borderRadius: '6px',
                border: '1px solid #333',
                backgroundColor: '#242424',
                color: '#fff',
                boxSizing: 'border-box',
              }}
            />
          </div>

          <button
            type="submit"
            disabled={isLoading}
            style={{
              width: '100%',
              padding: '12px',
              backgroundColor: '#1DB954',
              color: '#000',
              fontWeight: 'bold',
              border: 'none',
              borderRadius: '24px',
              cursor: 'pointer',
              fontSize: '15px',
            }}
          >
            {isLoading ? 'Đang xử lý...' : 'Đăng nhập'}
          </button>
        </form>
      </div>
    </div>
  );
}