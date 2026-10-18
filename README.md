# 🎵 Music App - Hệ Thống Ứng Dụng Nghe Nhạc 

Dự án gồm 3 phân hệ chính hoạt động đồng bộ trên **MongoDB Atlas** & **Cloudinary**:
1. **`backend/`**: RESTful API (Node.js, Express, MongoDB Atlas, Cloudinary, JWT, Multer).
2. **`admin/`**: Trang quản trị Web dành cho Admin quản lý và tải bài hát (React 18, Vite).
3. **`mobile/`**: Ứng dụng nghe nhạc di động phong cách Spotify (Flutter).

---

## 🚀 Thứ Tự Khởi Chạy Dự Án (Từ A - Z)

Để hệ thống hoạt động trơn tru, bạn hãy mở **3 cửa sổ Terminal riêng biệt** và chạy đúng theo thứ tự **Bước 1 $\rightarrow$ Bước 2 $\rightarrow$ Bước 3** dưới đây:

---

### BƯỚC 1: Chạy Backend Server (Bắt buộc chạy đầu tiên)
Backend cần chạy trước để kết nối tới **MongoDB Atlas** và mở cổng API `5000` cho Web Admin cùng Mobile App gọi tới.

Mở **Terminal 1**:
```powershell
cd backend
npm install
npm run dev
```
* **Dấu hiệu chạy thành công:**
  * `Server đang chạy ở cổng 5000`
  * `MongoDB Atlas đã kết nối thành công`
  * *(Trong lần chạy đầu tiên nếu DB trống, Backend sẽ tự động tạo sẵn tài khoản Admin `admin@music.com` / `123456`, 8 bài hát và 2 Playlist mẫu lên MongoDB Atlas).*

---

### BƯỚC 2: Chạy Web Admin (Quản trị & Upload nhạc)
Giúp bạn kiểm tra danh sách bài hát trong MongoDB hoặc tải bài hát mới (`.mp3`, ảnh bìa, `.lrc`) lên Cloudinary & MongoDB.

Mở **Terminal 2**:
```powershell
cd admin
npm install
npm run dev
```
* Mở trình duyệt tại đường link hiển thị trên terminal (thường là `http://localhost:5173`).
* **Thông tin đăng nhập Admin:**
  * **Email:** `admin@music.com`
  * **Mật khẩu:** `123456`

---

### BƯỚC 3: Chạy Mobile App (Flutter / Android Studio)
Sau khi Backend đã chạy ở Bước 1, bạn khởi chạy ứng dụng di động để lấy dữ liệu bài hát & playlist từ MongoDB.

1. **Khởi động máy ảo Android:**
   * Mở **Android Studio** $\rightarrow$ vào **Device Manager** $\rightarrow$ bấm **Play (▶)** để bật máy ảo (Emulator) lên trước.
2. **Chạy ứng dụng Flutter:**
   Mở **Terminal 3**:
   ```powershell
   cd mobile
   flutter pub get
   flutter run
   ```
   *(Hoặc nếu bạn mở thư mục `mobile` trực tiếp trong Android Studio thì chỉ cần chọn máy ảo và bấm nút **Run ▶**).*

---

## 🔄 Kiểm Tra Tính Đồng Bộ Giữa 3 Phân Hệ
1. Vào **Web Admin** (`http://localhost:5173`), thử tải lên 1 bài hát mới hoặc xóa 1 bài hát.
2. Qua **Mobile App** trên máy ảo Android, tại màn hình **Khám phá (Trang chủ)**, dùng chuột **kéo từ trên xuống (Pull-to-refresh)** $\rightarrow$ Danh sách bài hát mới nhất từ MongoDB sẽ lập tức xuất hiện!

## 🔄 Kiểm Tra Tính Đồng Bộ Giữa 3 Phân Hệ
1. Vào **Web Admin** (`http://localhost:5173`), thử tải lên 1 bài hát mới hoặc xóa 1 bài hát.
2. Qua **Mobile App** trên máy ảo Android, tại màn hình **Khám phá (Trang chủ)**, dùng chuột **kéo từ trên xuống (Pull-to-refresh)** $\rightarrow$ Danh sách bài hát mới nhất từ MongoDB sẽ lập tức xuất hiện!

