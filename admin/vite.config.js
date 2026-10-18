import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Cấu hình Vite cho React Admin
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
  },
});