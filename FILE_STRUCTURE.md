# Quick Reference: File Locations

## 📂 Xcode Project Structure

```
DAM-iOS/
├── Core/
│   ├── Models/
│   │   ├── ✨ AvatarModels.swift              (NEW - Add to Xcode)
│   │   └── ✨ MusicRecognitionModels.swift    (NEW - Add to Xcode)
│   │
│   └── Services/
│       ├── ✨ AvatarService.swift             (NEW - Add to Xcode)
│       └── 🔧 MusicService.swift              (UPDATED - Already in Xcode)
│
├── Features/
│   ├── Avatar/
│   │   ├── ViewModels/
│   │   │   └── ✨ AvatarViewModel.swift       (NEW - Add to Xcode)
│   │   │
│   │   └── Views/
│   │       ├── ✨ AIAvatarPromptView.swift    (NEW - Add to Xcode)
│   │       ├── ✨ AIAvatarPreviewView.swift   (NEW - Add to Xcode)
│   │       └── ✨ AvatarComponents.swift      (NEW - Add to Xcode)
│   │
│   ├── Music/
│   │   ├── ViewModels/
│   │   │   └── ✨ MusicRecognitionViewModel.swift  (NEW - Add to Xcode)
│   │   │
│   │   └── Views/
│   │       └── ✨ MusicRecognitionView.swift       (NEW - Add to Xcode)
│   │
│   ├── Home/
│   │   └── Views/
│   │       ├── ✨ EnhancedHomeHeaderView.swift     (NEW - Add to Xcode)
│   │       └── 🔧 HomeView.swift                   (UPDATED - Already in Xcode)
│   │
│   └── Profile/
│       └── Views/
│           └── 🔧 ProfileView.swift                (UPDATED - Already in Xcode)
│
└── Info.plist                                      (NEEDS UPDATE for mic permission)
```

## 🎯 Files to Add in Xcode (11 NEW files)

### Step-by-Step in Xcode:

1. **Core/Models/** - Right-click, "Add Files to DAM-iOS..."
   - ✨ AvatarModels.swift
   - ✨ MusicRecognitionModels.swift

2. **Core/Services/** - Right-click, "Add Files to DAM-iOS..."
   - ✨ AvatarService.swift

3. **Features/Avatar/** - Create group if needed, then add:
   - **ViewModels/** (create group)
     - ✨ AvatarViewModel.swift
   - **Views/** (create group)
     - ✨ AIAvatarPromptView.swift
     - ✨ AIAvatarPreviewView.swift
     - ✨ AvatarComponents.swift

4. **Features/Music/** - Create group if needed, then add:
   - **ViewModels/** (create group)
     - ✨ MusicRecognitionViewModel.swift
   - **Views/** (create group)
     - ✨ MusicRecognitionView.swift

5. **Features/Home/Views/** - Right-click, "Add Files to DAM-iOS..."
   - ✨ EnhancedHomeHeaderView.swift

## ⚠️ Important Reminders

### When Adding Files:
- ✅ Check "Copy items if needed"
- ✅ Select "Create groups"
- ✅ Add to targets: ✅ DAM-iOS
- ✅ Uncheck test targets

### After Adding Files:
1. Update Info.plist with microphone permission:
   ```
   Key: NSMicrophoneUsageDescription
   Value: We need access to your microphone to recognize songs you play
   ```

2. Clean Build Folder (Cmd+Shift+K)
3. Build (Cmd+B)
4. Run (Cmd+R)

## 🎨 New UI Features

### Home Screen Header:
- 🎵 "Recognize" button - Music recognition
- ➕ "Avatar" button - Create AI avatar (logged in users)
- ⭐ Stars display

### Profile Screen Header:
- 🎵 Music note button - Music recognition
- ⚙️ Settings button
- 🚪 Logout button

## 🔗 Integration Points

### MusicRecognitionView accessible from:
- Home screen header (🎵 Recognize button)
- Profile screen header (🎵 button)

### Avatar Creation accessible from:
- Home screen header (➕ Avatar button)
- Profile screen (Create button in Avatars section)

## 🚀 Ready to Build!

All code is complete and ready. Just add the 11 new files to Xcode project and you're good to go!
