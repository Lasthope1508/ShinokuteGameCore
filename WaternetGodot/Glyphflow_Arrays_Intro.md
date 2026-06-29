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
