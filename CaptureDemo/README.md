# CaptureDemo - iOS Video Capture App

A clean iOS video capture application built with SwiftUI and AVFoundation, demonstrating modern iOS development practices.

## 🎬 Demo Video

[**Watch the App in Action** →](./video_demo.MP4)

See the complete recording workflow, text overlay customization, and error handling in action.

## 📱 What It Does

**Core Features:**
- Record videos up to 10 seconds with live camera preview
- Switch between front/back cameras
- Add timestamp text overlays (top/center/bottom positions)
- Save processed videos to photo library
- Professional UI with animated record button and progress ring

**Technical Highlights:**
- SwiftUI + MVVM architecture
- Async/await for video processing
- AVFoundation for camera operations
- Combine for reactive state management
- Comprehensive error handling for permissions and camera issues

## 🏗️ Project Structure

```
CaptureDemo/
├── Modules/
│   ├── Camera/                    # Camera capture & recording
│   └── PreviewVideo/             # Video processing & preview
├── UIComponents/                 # Reusable UI (RecordButton, CameraPreview)
├── Utilities/                    # Video processing logic
└── Resources/                    # Assets
```

## 🚀 Quick Setup

1. **Requirements**: Xcode 15+, iOS 16+
2. **Clone & Run**: `open CaptureDemo.xcodeproj`
3. **Permissions**: Camera, microphone, and photo library access (handled automatically)

## 📖 Usage Flow

1. **Launch** → Camera preview appears with permission prompts
2. **Record** → Tap red button, 10-second max with progress ring
3. **Process** → Auto-navigation to preview with timestamp overlay
4. **Customize** → Change text position (top/center/bottom)
5. **Save** → One tap to save to photo library

## 🎯 Current Implementation

### Strengths ✅
- **Clean Architecture**: MVVM with proper separation of concerns
- **Robust Error Handling**: Permission denied, camera unavailable, session errors
- **Professional UX**: Loading states, error states, smooth animations
- **Memory Efficient**: Proper cleanup and temporary file management
- **Native**: No external dependencies, pure Apple frameworks

### Error Handling 🛡️
- **Permission Management**: Automatic requests with settings deep-linking
- **Session Monitoring**: Runtime error recovery and interruption handling
- **User Feedback**: Clear error messages with actionable next steps
- **Graceful Degradation**: App continues functioning when possible

## 💡 Key Improvement Ideas

### 1. **Enhanced Recording**
- Quality settings (720p/1080p/4K)
- Pause/resume functionality
- Countdown timer

### 2. **Advanced Text Overlays**
- Custom text input
- Font selection & color picker
- Multiple text layers
- Animation effects (fade, slide, typewriter)

### 3. **Video Effects**
- Real-time filters (vintage, B&W, beauty)
- Speed control (slow-mo, time-lapse)
- Brightness/contrast adjustments
- Video stabilization

### 4. **Professional Features**
- Multi-camera support (dual recording)
- Manual camera controls (ISO, focus, exposure)
- External microphone support
- Background blur/replacement

### 5. **Enhanced UX**
- Settings screen
- Recording history
- Cloud backup & sync
- Social sharing integration

## 📊 Technical Specs

- **Language**: Swift 5.9+
- **UI**: SwiftUI with MVVM
- **Media**: AVFoundation, AVKit, Photos
- **Concurrency**: async/await + Combine
- **Architecture**: Clean separation, dependency injection ready
- **Minimum iOS**: 16.0+

