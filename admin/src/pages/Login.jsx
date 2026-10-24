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
    <div className="login-wrap">
      <div className="login-card">
        <div className="login-logo">♫</div>
        <h2 className="login-title">Music Studio</h2>
        <p className="login-sub">Đăng nhập để quản trị bài hát, lời & nhạc Karaoke</p>

        {errorMsg && <div className="login-error">⚠️ {errorMsg}</div>}

        <form onSubmit={handleLogin}>
          <div style={{ marginBottom: '16px' }}>
            <label className="login-label">EMAIL</label>
            <input
              className="login-input"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>

          <div style={{ marginBottom: '24px' }}>
            <label className="login-label">MẬT KHẨU</label>
            <input
              className="login-input"
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>

          <button type="submit" disabled={isLoading} className="login-submit">
            {isLoading ? 'Đang xử lý...' : 'Đăng nhập'}
          </button>
        </form>
      </div>
    </div>
  );
}
