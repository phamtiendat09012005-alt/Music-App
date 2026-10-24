# 🎵 Music App - Hệ Thống Ứng Dụng Nghe Nhạc 

Dự án gồm 3 phân hệ chính hoạt động đồng bộ:
1. **`backend/`**: RESTful API (Node.js, Express, MongoDB Atlas, Cloudinary, JWT, Multer).
2. **`admin/`**: Web Quản trị Admin (React 18, Vite, Axios).
3. **`mobile/`**: Ứng dụng di động phong cách Spotify (Flutter, Just Audio, Dio, Provider, GoRouter).

---

## ⚠️ CÁC BƯỚC BẮT BUỘC KHI CLONE DỰ ÁN VỀ MÁY MỚI

Khi clone từ GitHub về máy khác, các thư mục thư viện (`node_modules/`, `.dart_tool/`) và file cấu hình bảo mật (`.env`) **sẽ không có sẵn trên Git**. Bạn cần chuẩn bị và tạo các file sau trước khi chạy.

### 1. Yêu cầu môi trường (Prerequisites)
* **Node.js**: Phiên bản `v18.x` hoặc `v20.x` trở lên ([Tải tại đây](https://nodejs.org/)).
* **Flutter SDK**: Phiên bản `>= 3.0.0` ([Tải tại đây](https://docs.flutter.dev/get-started/install)).
* **Android Studio**: Đã cài đặt Android SDK, Command-line Tools và tạo sẵn 1 Máy ảo Android (Android Emulator).

---

### 2. Tạo file cấu hình Backend (`backend/.env`)
> 💡 **Quan trọng**: Git tự động bỏ qua file `.env`. Nếu thiếu file này, Backend sẽ **báo lỗi sập ngay lập tức** khi khởi động.

1. Vào thư mục `backend/`.
2. Tạo một file tên là `.env` (nằm cùng cấp với `package.json`).
3. Sao chép nội dung từ `backend/.env.example` hoặc dán cấu hình sau vào:

```env
PORT=5000
# Đường dẫn kết nối MongoDB Atlas (Cluster của bạn hoặc dùng chung)
MONGO_URI=mongodb+srv://<username>:<password>@cluster0.mongodb.net/music-app?retryWrites=true&w=majority

# Mã bí mật tạo token đăng nhập JWT
JWT_SECRET=huy_music_super_secret_key_2026

# Cấu hình Cloudinary để tải ảnh bìa và file nhạc (Lấy tại https://cloudinary.com)
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

---

## 🚀 THỨ TỰ CÀI ĐẶT VÀ KHỞI CHẠY (TỪ A - Z)

Hãy mở **3 cửa sổ Terminal (hoặc PowerShell) riêng biệt** và chạy đúng thứ tự:

### 🔹 BƯỚC 1: Khởi động Backend (Chạy đầu tiên)
Backend phải chạy trước để kết nối Database và mở API cổng `5000`.

Mở **Terminal 1**:
```powershell
cd backend
npm install
npm run dev
```

* **Dấu hiệu chạy thành công:**
  ```text
  Server đang chạy ở cổng 5000
  MongoDB Atlas đã kết nối thành công: cluster0-shard-...
  ```
* 🎁 **Tự động khởi tạo dữ liệu (Auto-Seed)**: Lần đầu chạy trên DB trống, Backend tự động nạp sẵn tài khoản Admin, 8 bài hát mẫu (kèm lời `.lrc`/`.srt`) và 2 playlist mẫu.

---

### 🔹 BƯỚC 2: Khởi động Web Admin (Quản trị & Upload)
Mở **Terminal 2**:
```powershell
cd admin
npm install
npm run dev
```

* Truy cập trình duyệt tại: `http://localhost:5173`
* **Tài khoản Admin mặc định:**
  * **Email:** `admin@music.com`
  * **Mật khẩu:** `123456`
* **Tính năng:**
  * Quản lý bài hát: Upload nhạc (`.mp3`), ảnh bìa, file lời đồng bộ (`.lrc`, `.srt`, `.txt`), nghe thử và đồng bộ thời gian thực.
  * Quản lý nghệ sĩ (`/artists`): Xem danh sách ca sĩ, thay đổi ảnh đại diện chân dung (tải ảnh từ máy lên Cloudinary hoặc dán link ảnh), cập nhật tiểu sử.

---

### 🔹 BƯỚC 3: Khởi động Mobile App (Flutter)
Mở máy ảo Android trong **Android Studio** trước, sau đó:

Mở **Terminal 3**:
```powershell
cd mobile
flutter pub get
flutter run
```
*(Hoặc mở thư mục `mobile` trong Android Studio / VS Code và nhấn nút **Run ▶**).*

---

## 🛠️ TỔNG HỢP CÁC LỖI THƯỜNG GẶP KHI TEST TRÊN THIẾT BỊ KHÁC

### ❌ Lỗi 1: Backend báo lỗi `MongooseError: The MONGO_URI environment variable is not defined`
* **Nguyên nhân:** Quên chưa tạo file `backend/.env` sau khi clone từ Git.
* **Cách sửa:** Tạo file `backend/.env` như hướng dẫn ở Mục 2 phía trên.

---

### ❌ Lỗi 2: Backend báo `querySrv ECONNREFUSED` khi kết nối MongoDB Atlas
* **Nguyên nhân:** DNS của mạng/WiFi chặn truy vấn SRV của MongoDB Atlas.
* **Cách sửa:**
  1. Thêm IP máy tính vào mục **Network Access** trên bảng điều khiển [MongoDB Atlas](https://cloud.mongodb.com/) (chọn `Add Current IP Address` hoặc `Allow Access from Anywhere - 0.0.0.0/0`).
  2. Đổi DNS trên máy tính sang Google DNS (`8.8.8.8` / `8.8.4.4`). *(Trong code `backend/src/config/db.js` đã được tích hợp sẵn ép DNS Google).*

---

### ❌ Lỗi 3: App Mobile báo "Không kết nối được tới Backend (http://10.0.2.2:5000/api)"
* **Cơ chế IP của Mobile App ([`api_service.dart`](file:///c:/Users/MSII/Desktop/New%20folder%20(4)/Music-App-Huy/mobile/lib/services/api_service.dart#L17-L25)):**
  * **Chạy máy ảo Android Emulator:** App tự động gọi `http://10.0.2.2:5000/api` (đây là IP đại diện cho localhost máy tính).
  * **Chạy Web / Windows Desktop:** App tự động gọi `http://localhost:5000/api`.
  * **Chạy trên Điện thoại Android thật (cắm dây USB):**
    * Mở `mobile/lib/services/api_service.dart`.
    * Thay `10.0.2.2` bằng **Địa chỉ IP mạng LAN của máy tính** (mở `cmd` gõ `ipconfig` xem dòng `IPv4 Address`, ví dụ `http://192.168.1.15:5000/api`).
    * Điện thoại và máy tính phải bắt chung 1 mạng WiFi.

---

### ❌ Lỗi 4: Máy khác chạy `flutter run` báo lỗi Gradle hoặc Java Version
* **Nguyên nhân:** Android Studio trên máy khác dùng phiên bản Java khác hoặc chưa cấp quyền.
* **Cách sửa:**
  1. Vào Android Studio $\rightarrow$ **Settings** $\rightarrow$ **Build, Execution, Deployment** $\rightarrow$ **Build Tools** $\rightarrow$ **Gradle** $\rightarrow$ Chọn **Gradle JDK** là **Java 17**.
  2. Chạy lệnh dọn dẹp cache:
     ```powershell
     cd mobile
     flutter clean
     flutter pub get
     flutter run
     ```

---

### ❌ Lỗi 5: Tiếng nhạc lách tách nhỏ trên Android Emulator
* **Nguyên nhân:** Xung đột bộ đệm âm thanh của giả lập QEMU trên Windows.
* **Cách sửa:**
  1. Trong máy ảo Android, bấm dấu **`...` (Extended Controls)** $\rightarrow$ **Microphone** $\rightarrow$ tắt **Virtual microphone uses host audio input**.
  2. Test trên **Điện thoại thật** hoặc trên trình duyệt **Chrome (`flutter run -d chrome`)** để âm thanh trong trẻo 100%.

---

## ⚡ CÁCH CÀI TẤT CẢ THƯ VIỆN & MÔI TRƯỜNG TRỰC TIẾP TRÊN VS CODE

Nếu bạn muốn làm việc hoàn toàn trong **VS Code** (không cần mở nhiều cửa sổ terminal hay thao tác thủ công từng thư mục), hãy làm theo các bước cực nhanh sau:

### 1. Cài Extension cần thiết trên VS Code (Chỉ làm lần đầu)
Mở mục **Extensions** (`Ctrl + Shift + X`) trên thanh bên trái VS Code và cài 2 tiện ích:
1. **Flutter** (của *Dart Code*): Tự động cài luôn tiện ích Dart, hỗ trợ chạy và debug app Flutter bằng phím `F5`, tự động phát hiện thiết bị và máy ảo Android.
2. **ES7+ React/Redux/React-Native snippets**: Hỗ trợ code React cho phần Web Admin.

---

### 2. Một lệnh cài đặt toàn bộ thư viện (All-In-One Command)
Mở Terminal tích hợp ngay trong VS Code bằng phím tắt **`Ctrl + ~`** (hoặc menu **Terminal $\rightarrow$ New Terminal**) tại thư mục gốc của dự án (`Music-App`), sau đó dán duy nhất 1 dòng lệnh này rồi nhấn **Enter**:

```powershell
npm --prefix backend install; npm --prefix admin install; cd mobile; flutter pub get; cd ..
```

> 🎯 **Lệnh này tự động làm gì?**
> - Tự động cài đặt sạch sẽ tất cả gói cho **`backend/`**.
> - Tự động cài đặt toàn bộ dependencies cho **`admin/`**.
> - Tự động tải đầy đủ thư viện Flutter cho **`mobile/`**.

---

### 3. Khởi chạy trực tiếp từ Terminal VS Code
Bạn có thể chia màn hình Terminal trong VS Code thành nhiều cột (bấm biểu tượng **Split Terminal `|`** hoặc dấu `+` ở góc trên tab Terminal) để chạy cả 3 cùng lúc:
- **Cột 1**: `cd backend; npm run dev`
- **Cột 2**: `cd admin; npm run dev`
- **Cột 3**: `cd mobile; flutter run` *(hoặc bấm phím `F5` trên VS Code để chạy bằng Flutter Debugger)*.

## 📁 Cấu Trúc Thư Mục Dự Án
```text
Music-App-Huy/
├── backend/            # REST API (Node.js/Express/MongoDB)
│   ├── .env.example    # Mẫu cấu hình môi trường
│   ├── src/
│   │   ├── config/     # Kết nối Database & Cloudinary
│   │   ├── controllers/# Xử lý API (Song, User, Playlist, Auth)
│   │   ├── models/     # Mongoose Schemas
│   │   └── seedData.js # Khởi tạo dữ liệu mẫu & lời bài hát
├── admin/              # Giao diện Web Quản trị (React + Vite)
│   ├── src/
│   │   ├── components/ # Form Upload, Studio Lyric, Navbar
│   │   └── pages/      # Quản lý bài hát, Đăng nhập
└── mobile/             # Ứng dụng di động (Flutter)
    ├── lib/
    │   ├── models/     # Song, Playlist, Artist
    │   ├── providers/  # Quản lý phát nhạc, yêu thích, playlist
    │   ├── screens/    # Khám phá, Đang phát, Tìm kiếm, Thư viện
    │   └── widgets/    # MiniPlayer, LyricsView đồng bộ .lrc/.srt
```


