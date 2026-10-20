# 3D Jigsaw Puzzle Adventure — Android Mobile Game

A premium, production-quality 3D-style jigsaw puzzle game for Android built using **Flutter and Dart**. Players assemble individual interlocking puzzle pieces to recreate complete works of art across multiple themed sections, progressive difficulty grids, customizable photo puzzles, and rewarding completion celebrations.

---

## 🌟 Key Highlights

- **Realistic 2.5D/3D Puzzle Rendering**:
  - Interlocking classic jigsaw shapes generated using deterministic cubic Bézier curves (tabs and blanks match adjacent neighbors with mathematical precision — 0 gaps, 0 overlaps).
  - Multi-layered 3D bevel lighting: directional top-left specular highlights and bottom-right shadow bevels.
  - Tactile drag-and-lift sensation: lifted pieces scale by 1.10x, tilt by 2–3°, and cast dynamic ambient soft drop shadows with blur.
  - Magnetic snapping: pieces within magnetic threshold automatically lock into place with satisfying haptic feedback and golden particle flashes.
- **50 Handcrafted Offline Levels Across 5 Sections**:
  - **Section 1: Beginner** (Levels 1–10) — Tranquil nature and scenic landscapes (3×3 up to 6×7 grids).
  - **Section 2: Explorer** (Levels 11–20) — Exotic wildlife, tropical oceans, and rainforests (4×4 up to 7×7 grids).
  - **Section 3: Adventure** (Levels 21–30) — Floating isles, mythic spires, and fantasy castles (5×5 up to 7×7 grids).
  - **Section 4: Expert** (Levels 31–40) — Cosmic stargates, glowing nebulae, and ringed celestial giants (6×6 up to 8×8 grids).
  - **Section 5: Master** (Levels 41–50) — Ancient wonders, gilded pyramids, and sacred monumental architecture (6×7 up to 8×8 grids).
- **Multiple Game Modes**:
  - **Adventure (Classic)**: Progressive campaign through all 50 levels with star ratings and section unlocks.
  - **Relax Mode**: Untimed, penalty-free, with unlimited hints for pure zen relaxation.
  - **Timed Challenge**: Beat the clock for bonus coins and speed achievements.
  - **Mystery Image**: Puzzle details are hidden in mystery silhouettes until pieces are correctly assembled.
  - **My Photo Mode**: Turn any personal photo from the Android gallery or camera into a playable puzzle with custom grid sizes (3×3, 4×4, 5×5, 6×6).
  - **Daily Challenge**: Featured daily puzzle with streak multiplier rewards.
- **Centralized Audio & Sound Effects Engine**:
  - Seamless background music loop with smooth transitions.
  - Satisfying sound effects: UI tap, piece pickup, drop, mechanical snap lock, hint chime, star fanfare, and victory celebration.
  - Independent volume controls for music, sound effects, master mute, and vibration haptics.
- **Full Offline State Persistence**:
  - Saves progress (coins, stars, best times, unlocks, settings) locally via `SharedPreferences`.
  - Automatically preserves active unfinished puzzles so players can resume anytime without losing progress.

---

## 🏗️ Architecture Overview

```
lib/
├── main.dart                      # System UI styling, orientation locks, engine initialization
├── app.dart                       # MaterialApp theme, transitions, dark luxury palette
├── models/
│   ├── puzzle_level.dart          # 50 defined levels, dimensions, categories, rewards
│   ├── puzzle_section.dart        # 5 themed sections with progression metadata
│   ├── puzzle_piece.dart          # Piece model with coordinates, edges, and snap state
│   ├── player_progress.dart       # State serialization, active game saves, star/time tracking
│   ├── game_mode.dart             # Enum & descriptions for all 6 gameplay modes
│   └── achievement.dart          # 12 unlockable achievements with coin rewards
├── services/
│   ├── audio_manager.dart         # BGM and SFX player with haptic feedback
│   ├── progress_service.dart      # ChangeNotifier handling local JSON persistence
│   ├── image_service.dart         # Image loading & caching pipeline
│   └── reward_service.dart        # Dynamic star and coin calculation engine
├── game/
│   ├── puzzle_edge_generator.dart # Deterministic interlocking jigsaw edge algorithm
│   ├── puzzle_piece_renderer.dart # CustomPainter with 3D bevels, shadows, specular sheen
│   └── puzzle_board.dart          # Board grid, magnetic snap detection, watermark guide
├── widgets/
│   ├── floating_pieces_background.dart # Ambient 3D floating puzzle pieces backdrop
│   ├── puzzle_tray.dart           # Piece bank with "Edges Only" filter and drag source
│   ├── level_card.dart            # Interactive level card with thumbnail preview and stars
│   ├── section_card.dart          # Section progress card with completion progress bar
│   ├── victory_dialog.dart        # Confetti celebration, star reveal, and reward rollup
│   └── pause_dialog.dart          # Pause menu with resume, restart, and sound toggles
└── screens/
    ├── home_screen.dart           # Logo, Play, Continue, Sections, Photo, Daily, Settings
    ├── section_selection_screen.dart # 5-section adventure map
    ├── level_selection_screen.dart   # 10-level grid with live stars and locks
    ├── puzzle_game_screen.dart    # Main interactive gameplay experience
    ├── photo_puzzle_screen.dart   # Custom photo gallery picker & difficulty selector
    ├── daily_challenge_screen.dart# Daily puzzle with calendar streak tracking
    ├── achievements_screen.dart   # Claimable rewards and milestone trophies
    └── settings_screen.dart       # Volume sliders, haptics, tutorial, and controls
```

---

## 🎮 How to Run Locally

### Prerequisites
- Flutter SDK 3.38+ / Dart 3.10+
- Java JDK 17
- Android SDK (API 34+)

### 1. Run Automated Tests
```powershell
flutter test
```
*All 7 unit and widget tests pass.*

### 2. Run on Android Device / Emulator
```powershell
flutter run -d android
```

### 3. Run on Chrome (Web Preview)
```powershell
flutter run -d chrome
```

---

## 📱 Release APK

The release APK has been built and verified:
- **File path**: `build\app\outputs\flutter-apk\app-release.apk`
- **Size**: ~58.5 MB (includes all 50 offline high-res 1024×1024 artwork assets and audio effects)

### Install on Connected Android Device
```powershell
flutter install --release
```
or via ADB:
```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```
