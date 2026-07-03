# Hướng Dẫn Kế Thừa & Khởi Tạo Dự Án Mẫu (Godot Template Core)

Dự án mẫu này chứa toàn bộ các hệ thống cốt lõi (Core Modules) và các thiết lập tối ưu hóa đã được đúc rút qua quá trình phát triển dự án **BloxChain**. Mỗi khi bắt đầu một tựa game mới, bạn chỉ cần kế thừa từ thư mục này.

---

## 1. Cấu Trúc Các Module Cốt Lõi (Core Modules)

Tất cả các module này đã được đăng ký sẵn dưới dạng **Autoload (Singletons)** trong cài đặt dự án:

### 1.1. `AdManager.gd` ([res://Resources/Globals/AdManager.gd](file:///c:/Users/Admin/Desktop/Godot_Template/Resources/Globals/AdManager.gd))
*   **Đa nền tảng di động:** Hỗ trợ quảng cáo AdMob trên cả **Google Play** và **Amazon Appstore**. Tự động phát hiện nguồn cài đặt ứng dụng (`com.android.vending` vs `com.amazon.venezia`) để nạp chính xác bộ ID Ads tương ứng tại thời điểm runtime.
*   **Đa nền tảng Web:** Tích hợp sẵn JS Bridge tự động kết nối với SDK quảng cáo của **CrazyGames**, **GameMonetize**, và **GameDistribution**.
*   **Tự động hóa:** Tự động gọi sự kiện dừng/chạy game (`gameplayStart()`/`gameplayStop()`) khi chuyển đổi màn hình chơi game.

### 1.2. `AudioManager.gd` ([res://Resources/Globals/AudioManager.gd](file:///c:/Users/Admin/Desktop/Godot_Template/Resources/Globals/AudioManager.gd))
*   Hỗ trợ phát nhạc nền (Music) và hiệu ứng âm thanh (SFX).
*   Tự động lưu và tải trạng thái âm lượng (Mute / Slider volume) đồng bộ từ `SaveManager`.

### 1.3. `SaveManager.gd` ([res://Resources/Globals/SaveManager.gd](file:///c:/Users/Admin/Desktop/Godot_Template/Resources/Globals/SaveManager.gd))
*   Tự động mã hóa và lưu trữ dữ liệu người chơi (Username, Best Score cho từng chế độ Classic/Chaos, cài đặt âm thanh).

### 1.4. `SceneRouter.gd` ([res://Resources/Globals/SceneRouter.gd](file:///c:/Users/Admin/Desktop/Godot_Template/Resources/Globals/SceneRouter.gd))
*   Điều phối chuyển đổi màn hình (Scene swapping).
*   Sử dụng một `CanvasLayer` đè lên trên (`FadeTransition`) để tạo hiệu ứng mờ dần (Fade out / Fade in) khi đổi màn hình, tránh giật lag khung hình.

### 1.5. `LeaderboardManager.gd` ([res://Scripts/LeaderboardManager.gd](file:///c:/Users/Admin/Desktop/Godot_Template/Scripts/LeaderboardManager.gd))
*   Tự động kết nối cơ sở dữ liệu để truy xuất bảng xếp hạng theo phân vùng (Thế giới, Châu lục, Quốc gia) cho cả chế độ Basic (Classic) và Chaos.

### 1.6. `McpInteractionServer.gd` ([res://Scripts/mcp_interaction_server.gd](file:///c:/Users/Admin/Desktop/Godot_Template/Scripts/mcp_interaction_server.gd))
*   Công cụ kết nối runtime của Godot để Agent (Antigravity) có thể chạy kiểm thử game tự động, giả lập click chuột, chụp ảnh màn hình và lấy thông tin cây node thời gian thực.

---

## 2. Các Quy Tắc Tối Ưu Hóa Tĩnh (Optimizations & Presets)

Trong file cấu hình xuất bản [export_presets.cfg](file:///c:/Users/Admin/Desktop/Godot_Template/export_presets.cfg) đã được cài đặt sẵn các thiết lập tối ưu dung lượng và độ ổn định cao nhất:

### 2.1. Cấu hình xuất bản Web HTML5
*   **`variant/thread_support = false`** (Single-threaded): Bắt buộc tắt đa luồng để tránh lỗi nạp đơ, crash và tự động reload lặp vô hạn trên trình duyệt Safari của iOS/iPadOS.
*   **`exclude_filter`**: Đã loại trừ sẵn toàn bộ các thư mục chứa file build cũ (`Export/*`, `Export_clean/*`), code nháp (`scratch/*`), dashboard (`reskin_dashboard/*`), các file video `.mp4` và thư mục nodeJS. Điều này giúp gói nén ZIP game web giảm hơn 30MB dung lượng thừa.

### 2.2. Cấu hình xuất bản Android
*   **CPU Architectures**: Chỉ kích hoạt `armeabi-v7a` và `arm64-v8a`. Đã **tắt** (`false`) kiến trúc `x86` và `x86_64` (dành cho máy tính giả lập) để giảm 50% dung lượng bản cài đặt thực tế `.aab` trên Play Store.
*   **Gradle Target SDK**: Sử dụng cơ chế hardcode target SDK `35` trong `config.gradle` để vượt qua yêu cầu bắt buộc của Google Play Console mà không bị Godot tự động ghi đè về mức thấp hơn.

---

## 3. Các Bước Khởi Tạo Game Mới Từ Dự Án Mẫu

Khi bạn muốn bắt đầu một game mới:

1.  **Sao chép thư mục**: Sao chép thư mục `Godot_Template` thành tên thư mục dự án mới của bạn (ví dụ: `MyNewGame`).
2.  **Định danh lại dự án**:
    *   Mở file `project.godot` trong thư mục mới, chỉnh sửa trường `config/name="Tên Game Mới"` và `config/version="1.0.0"`.
3.  **Định danh gói Android**:
    *   Mở file `export_presets.cfg`, sửa trường `package/unique_name="com.shinokutestudio.ten_game_moi"` và cập nhật lại ID quảng cáo thực tế của game mới trong [AdManager.gd](file:///c:/Users/Admin/Desktop/Godot_Template/Resources/Globals/AdManager.gd).
4.  **Kết nối Git**: Khởi tạo kho lưu trữ git mới (`git init`) trong thư mục mới. Mọi thứ đã có sẵn `.gitignore` chuẩn.
5.  **Mở phiên chat với Antigravity**: Chọn thư mục `MyNewGame` làm Workspace mới, Agent sẽ tự động nạp tài liệu này và hiểu rõ toàn bộ cấu trúc lõi để code hỗ trợ bạn ngay lập tức.
