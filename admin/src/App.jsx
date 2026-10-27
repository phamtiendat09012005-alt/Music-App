import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Songs from './pages/Songs';
import Artists from './pages/Artists';

// Bảo vệ route: chưa có token thì chuyển về trang /login
const PrivateRoute = ({ children }) => {
  const token = localStorage.getItem('token');
  return token ? children : <Navigate to="/login" replace />;
};

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route
          path="/songs"
          element={
            <PrivateRoute>
              <Songs />
            </PrivateRoute>
          }
        />
        <Route
          path="/artists"
          element={
            <PrivateRoute>
              <Artists />
            </PrivateRoute>
          }
        />
        <Route path="*" element={<Navigate to="/songs" replace />} />
      </Routes>
    </BrowserRouter>
  );
}