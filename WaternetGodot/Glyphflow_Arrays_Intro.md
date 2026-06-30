# GLYPHFLOW ARRAYS - INTRODUCTION & ARCHITECTURE

Welcome to **Glyphflow Arrays**, a commercial-grade, premium 2D grid connection puzzle game built with **Godot Engine 4.3**.

---

## 🌌 1. Game Lore & Concept

In **Glyphflow Arrays**, you play as a cyber-network calibration engineer in a high-tech quantum computing grid. Your mission is to align data transmission streams (Data Conduits) to establish a continuous path from the **Source Power Core** to the target **Glyph Array nodes**. Once all target nodes receive the correct data stream, the network sector calibrates, and you progress to the next array sector.

---

## 🎮 2. Core Gameplay Mechanics

- **The Grid Puzzle**: Players interact with a grid of cells (ranging from 3x3 up to 9x9).
- **Click-to-Rotate**: Clicking any tile rotates it $90^\circ$ clockwise, updating its routing ports.
- **Connection Port Rules**: 
  - `pipe_cap` (1-port end cap)
  - `pipe_i` (2-port straight conduit)
  - `pipe_l` (2-port corner curve)
  - `pipe_t` (3-port junction)
  - `pipe_x` (4-port cross intersection)
- **Path Resolution**: The solver runs a recursive flood-fill algorithm starting from the **Source node** (`source.png`). If the flow reaches all **Target nodes** (`target.png`) with matching connection ports, the level resolves successfully.

---

## 🎨 3. Design System & Mascot Brand Visuals

Glyphflow Arrays implements a strict **Single Source of Truth (SSOT)** style design system. The visual skin is loaded from a central [ThemeConfig.gd](file:///C:/Users/Admin/Desktop/Godot%20Casual%20Games/WaternetGodot/Resources/Classes/ThemeConfig.gd) configuration.

### Visual Architecture:
-   **Anthropomorphized Mascot**: The game is represented by a cute cybernetic mascot character (`logo.png`) that is integrated into the boot splash and welcome screen.
-   **Color Palette Configuration**:
    -   *Background Panel (`panel_bg_color`)*: Dark space-black (`#010103`) to allow neon circuits to glow with high contrast.
    -   *Data Conduits & Text (`text_color`)*: Digital Green (`#1ae633`) for unwatered pipes and source/target direction indicators.
    -   *Energy Accents (`accent_color`)*: Energy Orange (`#ff7300`) for the Source Power Core, active flowing paths, and active highlights.
    -   *Secondary/Alerts (`alert_color`)*: Electric Blue (`#0099ff`) for target nodes and UI borders.

---

## ⚙️ 4. Software Architecture Specifications

- **Decoupled Asset Loading**: UI components read textures, colors, and layout bounds (margins, widths) dynamically from the active `ThemeConfig` resource, completely eliminating hardcoded script values.
- **Proportional UI Scaling**: Utility buttons (Reset, Mute) scale their heights dynamically based on the active theme's `utility_button_height`.
- **Dynamic Icon Modulation**: Icon-only buttons (like `MuteBtn`) dynamically tint their white textures at runtime to contrast perfectly against button backgrounds, resolving contrast accessibility issues.
- **Responsive Viewport Manager**: The camera zoom and grid positioning scale dynamically to support notched mobile displays, widescreen desktop, and iPads seamlessly.
- **Autoload singletons**:
  - `ThemeManager`: Manages `.tres` theme swapping and exports shared styles.
  - `AudioManager`: Manages theme-aware BGM loop streams and normalized SFX pools.
  - `SaveManager`: Encrypts unlocked levels, progress, and volumes.
  - `SceneRouter`: Transition controller with fading overlays.

---

## 🎨 5. Specific Theme Design Rules (Waternet Pipe Rules)

Để tránh lỗi không đồng bộ thị giác và mù hướng UX khi tích hợp các Theme mới, mọi asset thuộc Theme trong dự án phải tuân thủ nghiêm ngặt các quy chuẩn hình học sau:

### 5.1 Nhất Quán Độ Rộng & Tiếp Xúc Biên (Stroke & Reach Edge Contract)
*   **Đường kính ống dẫn:** Trong ảnh 256x256 pixel đã được căn tâm, phần thân ống của mọi sprite (`pipe_i`, `pipe_cap`, `pipe_l`, `pipe_t`, `pipe_x`) phải có đường kính thân ống chiếm chính xác **`35%`** kích thước canvas (khoảng **`90 pixel`** độ rộng nét vẽ thực tế).
*   **Kích thước mối nối bọc vàng:** Có đường kính ngoài chiếm **`45%`** canvas (khoảng **`115 pixel`**).
*   **QUY TẮC TIẾP XÚC BIÊN (Reach Edge Rule - Chống hở khớp):** Để khi ghép các ô gạch lại với nhau, các mối nối bọc vàng chạm khít vào nhau mà không có khe hở:
    *   `pipe_i.png` (ống thẳng đứng): Cổng kết nối phải đi sát sạt và **chạm đúng biên trên và biên dưới** (tức là hàng pixel $y=0$ và $y=255$ bắt buộc phải có alpha $> 0$ tại vùng mối nối).
    *   `pipe_l.png` (ống cong góc): Phải chạm đúng **biên trên và biên phải** ($y=0$ và $x=255$).
    *   `pipe_t.png` (chữ T): Phải chạm đúng **biên trên, biên phải và biên dưới** ($y=0$, $x=255$, $y=255$).
    *   `pipe_x.png` (chữ thập): Phải chạm đúng cả **4 cạnh biên** ($y=0$, $x=255$, $y=255$, $x=0$).
    *   `pipe_cap.png` (nút bịt): Cổng mở phải chạm đúng **biên trên** ($y=0$).
    *   `source.png` (vòi phun): Miệng vòi phun ra (hướng Bắc) phải chạm đúng **biên trên** ($y=0$).
    *   `target.png` (bể nhận): Miệng phễu đón nước (hướng Bắc) phải chạm đúng **biên trên** ($y=0$).

### 5.2 Chỉ Hướng Cho Nguồn & Đích (UX Directional Clues)
*   **Source Node (`source.png`):** CẤM thiết kế đối xứng tâm. Bắt buộc phải là hình ảnh vòi nước/cổng phát chỉ rõ hướng nước phun ra chĩa về phía bên **Phải (Đông)** ở góc 0.
*   **Target Node (`target.png`):** Bắt buộc phải có phễu đón/cổng nhận nước mở hướng về phía bên **Trái (Tây)** ở góc 0 để hứng dòng nước chảy.
*   **Chỉ thị dòng chảy:** Water Flow Overlay vẽ bằng vector đè lên phải có màu tương phản mạnh với màu nền của ống (ví dụ: ống đồng thau thì nước chảy màu vàng sáng óng ánh).


