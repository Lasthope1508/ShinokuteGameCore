# WATERNET GODOT - HANDOVER SPECIFICATION & GUIDE

Tài liệu này bàn giao chi tiết kiến trúc hệ thống, quy trình tích hợp tài nguyên âm thanh (BGM/SFX) và quy chuẩn đóng gói xuất bản HTML5 Web cho các Agent thế hệ tiếp theo tiếp quản dự án.

---

## 1. Kiến Trúc Hệ Thống & Trừu Tượng Hóa (Abstraction)

Dự án tuân thủ nghiêm ngặt nguyên lý **SSOT (Single Source of Truth)** và chia tách logic rõ ràng:

### 1.1. Hệ thống Âm thanh (Audio System)
*   **Singleton `AudioManager` ([res://Resources/Globals/AudioManager.gd](file:///C:/Users/Admin/Desktop/Godot%20Casual%20Games/WaternetGodot/Resources/Globals/AudioManager.gd))**:
    *   Quản lý một `AudioStreamPlayer` cho nhạc nền (BGM) và một Pool gồm 8 players cho hiệu ứng âm thanh (SFX) để tránh xung đột tiếng.
    *   **Tắt/Bật tiếng chuẩn hóa (Canonical)**: Cung cấp `toggle_master_mute()` và `is_master_muted()` để điều khiển Master bus. Các màn hình như `MainMenu` hay `GameScene` chỉ việc gọi qua các hàm này mà không được phép tự ý kiểm tra hay đặt lại volume trực tiếp qua AudioServer.
    *   **Nhạc nền động theo Theme (Theme-Aware BGM)**: 
        *   Tự động tải nhạc nền tương ứng từ thư mục theme hiện tại (`res://Audio/Music/{theme_name}/{file_name}`).
        *   Tự động fallback về thư mục gốc `res://Audio/Music/{file_name}` nếu theme đó không cấu hình nhạc riêng.
        *   Kết nối với tín hiệu thay đổi theme của `ThemeManager` để chuyển đổi nhạc (cross-fade transition) thời gian thực.

### 1.2. Hệ thống Giao diện & Chủ đề (Theme Customization)
*   **`ThemeConfig` ([res://Resources/Classes/ThemeConfig.gd](file:///C:/Users/Admin/Desktop/Godot%20Casual%20Games/WaternetGodot/Resources/Classes/ThemeConfig.gd))**:
    *   Lớp tài nguyên (Resource class) xuất bản các thuộc tính cấu hình mỹ thuật (màu sắc thương hiệu, bo góc button, kích thước chữ, khoảng cách lề, font chữ, và toàn bộ Sprites/Textures của lưới ống nước).
*   **`ThemeManager` ([res://Resources/Globals/ThemeManager.gd](file:///C:/Users/Admin/Desktop/Godot%20Casual%20Games/WaternetGodot/Resources/Globals/ThemeManager.gd))**:
    *   Quản lý việc tải các file cấu hình `.tres` động (`garden_theme.tres`, `wood_theme.tres`, `hacknet_theme.tres`).
    *   Tự động override thuộc tính vào file Theme toàn cục `res://Resources/Theme/main_theme.tres` và phát tín hiệu `theme_changed`.

---

## 2. Hướng Dẫn Tải & Xử Lý Âm Thanh Với Suno AI + FFmpeg

Quy trình chuẩn mực để tạo, nén chuẩn di động và tích hợp âm thanh vào dự án:

### 2.1. Sinh nhạc nền (BGM) bằng Suno AI
1.  Truy cập tab **Create (Simple)** trên Suno.
2.  Bật tùy chọn **Instrumental** (đảm bảo hiển thị dấu check `✓`).
3.  **Quy tắc tư vấn**: Phải hỏi ý kiến Owner để tư vấn nhạc phù hợp với chủ đề (ví dụ: nhạc cụ mộc, sáo concert, cello pizzicato và lo-fi beat cho chủ đề Garden).
4.  Điền prompt đã thống nhất và bấm **Create**. Giải quyết captcha trên Chrome (port 9223) ngay khi xuất hiện.

### 2.2. Tải trực tiếp qua CDN
*   Inspect ảnh cover của track nhạc trên trang Suno để tìm ID bài hát dưới dạng UUID (ví dụ: `1de8d5cd-c373-48fa-a08c-33a5b0af57d3`).
*   Tải trực tiếp bằng link CDN: `https://cdn1.suno.ai/{song_id}.mp3`.

### 2.3. Cắt tỉa (Trim) & Nén OGG (FFmpeg)
*   Nhạc Suno thô thường rất dài (~10s đối với SFX) và chứa khoảng lặng. Sử dụng FFmpeg để nén chất lượng di động (`q:a 1` ~80kbps) và cắt tỉa (Trim):
    *   **SFX Button click**: Cắt lấy `0.3s` đầu tiên.
    *   **SFX Báo lỗi (Invalid)**: Cắt lấy `0.6s` đầu tiên.
    *   **SFX Level Up**: Cắt lấy `2.4s` đầu tiên.
*   **Lệnh nén BGM**:
    ```bash
    ffmpeg -y -i "Paper Crane Garden.wav" -c:a libvorbis -q:a 1 "Gameplay.ogg"
    ```

### 2.4. BẮT BUỘC: Thiết lập lặp (Loop) cho BGM trong Godot 4
*   Đối với Godot 4 Web Assembly, không được phép ép lặp bằng code động mà **phải khai báo trực tiếp trong tệp `.import`** của bản nhạc để trình duyệt xử lý bộ đệm chuẩn xác.
*   Mở file `.import` của bản nhạc tương ứng (ví dụ: `res://Audio/Music/Gameplay.ogg.import`), tìm mục `[params]` và sửa thành:
    ```ini
    loop=true
    ```
*   Chạy quét import headless của Godot Editor để cập nhật:
    ```bash
    & "C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe" --path "C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot" --editor --headless --quit
    ```

---

## 3. Quy Trình Xuất Bản HTML5 Web & Deploy Lên Firebase

### 3.1. Thiết lập Export Presets
*   Bắt buộc đặt **`variant/thread_support = false`** trong cấu hình xuất bản Web để tương thích tốt nhất với Safari trên iOS/iPadOS, ngăn ngừa lỗi crash và tải lại lặp vô hạn.
*   Đảm bảo `exclude_filter` đã loại trừ toàn bộ thư mục build cũ, code nháp (`scratch/*`), dashboard, và các tệp video `.mp4`.

### 3.2. Cài đặt Tiêu đề COOP/COEP trên Firebase Hosting
*   Godot 4 WebAssembly chạy trên trình duyệt yêu cầu các tiêu đề bảo mật Cross-Origin để kích hoạt SharedArrayBuffer.
*   Cấu hình trong [firebase.json](file:///C:/Users/Admin/Desktop/Godot%20Casual%20Games/WaternetGodot/firebase.json):
    ```json
    {
      "hosting": {
        "public": "Export",
        "ignore": [
          "firebase.json",
          "**/.*",
          "**/node_modules/**"
        ],
        "headers": [
          {
            "source": "**/*",
            "headers": [
              { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" },
              { "key": "Cross-Origin-Embedder-Policy", "value": "require-corp" }
            ]
          }
        ]
      }
    }
    ```

### 3.3. Các lệnh xuất bản và triển khai nhanh
1.  **Biên dịch & xuất bản (Export)**:
    ```powershell
    & "C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe" --path "C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot" --headless --export-debug "Web" "C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot\Export\index.html"
    ```
2.  **Đưa lên Firebase Hosting**:
    ```powershell
    firebase deploy --only hosting
    ```
3.  **URL Kiểm thử**: **[https://shinokute-studio.web.app](https://shinokute-studio.web.app)**
