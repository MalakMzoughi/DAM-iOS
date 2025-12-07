//
//  README_FallingNotes.md
//  Falling Notes System Implementation Guide
//
//  Created on 2025-12-06.
//

# 🎵 Vertical Falling Notes System

This implementation provides a complete **Piano Tiles / Magic Tiles** style falling notes system for your SwiftUI game.

---

## 📁 Files Generated

1. **FallingNote.swift** - Data models for notes and music representation
2. **FallingNoteView.swift** - Visual representation of a single falling note
3. **NoteLanesView.swift** - The 7-lane vertical scrolling area
4. **FallingNotesManager.swift** - Animation and gameplay logic manager
5. **GamePlayView.swift** - Complete game view with keyboard integration

---

## 🎯 Features Implemented

### ✅ 7 Vertical Lanes
- One lane per note (DO, RE, MI, FA, SOL, LA, SI)
- Transparent columns with subtle borders
- Full screen height

### ✅ Falling Animation
- Notes start at y = -200 (off-screen top)
- Linear fall to bottom (configurable duration)
- Smooth 60 FPS animation
- Automatic cleanup of passed notes

### ✅ Visual Design
- Rounded rectangles with bright colors
- White bold text labels
- Shadow effects for depth
- Android-style proportions (80pt tall)

### ✅ Piano Keyboard
- 7 keys at the bottom
- Color-coded to match notes
- Touch feedback with pressed state
- Clean modern design

### ✅ Gameplay Logic
- Hit detection in hit zone near keyboard
- Score tracking
- Note removal on successful hit
- Demo sequence loader

---

## 🚀 How to Use

### Option 1: Replace Your Current View

If you have an existing game view, replace your current notes display with:

```swift
import SwiftUI

struct YourGameView: View {
    @State private var notesManager = FallingNotesManager()
    @State private var score = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Your existing background, hero, boss, etc.
                
                VStack(spacing: 0) {
                    // Top UI (score, health, etc.)
                    YourTopBarView()
                    
                    // Falling notes area
                    NoteLanesView(
                        fallingNotes: $notesManager.fallingNotes,
                        screenHeight: geometry.size.height,
                        keyboardHeight: 120
                    )
                    
                    // Piano keyboard at bottom
                    PianoKeyboardView { note in
                        if notesManager.checkNoteHit(lane: note.lane) {
                            score += 10
                        }
                    }
                    .frame(height: 120)
                }
            }
            .onAppear {
                notesManager.screenHeight = geometry.size.height
                notesManager.startAnimating()
            }
        }
    }
}
```

### Option 2: Use GamePlayView Directly

Simply present `GamePlayView()` as your main game screen:

```swift
@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            GamePlayView()
        }
    }
}
```

---

## 🎮 Loading Your Song Data

Replace the demo sequence with your actual song:

```swift
// In GamePlayView or your view:
private func loadSongNotes() {
    // Example: Load from your data source
    let songNotes: [MusicNote] = [
        .DO, .RE, .MI, .FA, .SOL, .LA, .SI,
        .DO, .MI, .SOL, .DO
    ]
    
    notesManager.loadNoteSequence(songNotes, interval: 0.8)
}

// Or add notes individually with precise timing:
func addNoteAtTime(note: MusicNote, delay: TimeInterval) {
    Task {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        notesManager.addNote(note)
    }
}
```

---

## ⚙️ Customization

### Adjust Fall Speed

In `FallingNotesManager.swift`:

```swift
let fallDuration: TimeInterval = 3.0 // Change to 2.0 for faster, 4.0 for slower
```

### Change Note Appearance

In `FallingNoteView.swift`:

```swift
.frame(width: width * 0.85, height: 80) // Adjust width % and height
.cornerRadius(12) // Adjust roundness
```

### Modify Colors

In `FallingNote.swift`, edit the `color` property of `MusicNote`:

```swift
var color: Color {
    switch self {
    case .DO:
        return .red // Change to your preferred color
    // ... etc
    }
}
```

### Adjust Hit Zone

In `FallingNotesManager.swift`:

```swift
let hitZone: ClosedRange<CGFloat> = 
    (screenHeight - keyboardHeight - 100)...(screenHeight - keyboardHeight + 50)
    // Adjust the -100 and +50 values for a larger/smaller hit window
```

---

## 🎨 Visual Result

The final UI will look like:

```
┌─────────────────────────────┐
│      Score: 120             │ ← Top bar
├─────────────────────────────┤
│  │  │  │  │  │  │  │       │
│  │DO│  │MI│  │LA│  │       │ ← Falling notes
│  │  │RE│  │FA│  │SI│       │   in lanes
│  │  │  │  │SOL│  │  │      │
│  │  │  │  │  │  │  │       │
│ (notes fall vertically)     │
│  │  │  │  │  │  │  │       │
├─────────────────────────────┤
│[DO][RE][MI][FA][SOL][LA][SI]│ ← Piano keyboard
└─────────────────────────────┘
```

---

## 📝 Integration Checklist

- [ ] Add all 5 files to your Xcode project
- [ ] Replace old notes UI with `NoteLanesView`
- [ ] Add `PianoKeyboardView` at bottom
- [ ] Initialize `FallingNotesManager` 
- [ ] Call `startAnimating()` on appear
- [ ] Load your song data
- [ ] Test hit detection
- [ ] Adjust colors/sizing to your preference
- [ ] Keep your existing background, hero, boss UI

---

## 🐛 Troubleshooting

**Notes not moving?**
- Ensure `startAnimating()` is called
- Check that `screenHeight` is set correctly

**Hit detection not working?**
- Verify keyboard height matches `keyboardHeight` in manager
- Adjust hit zone range if needed

**Performance issues?**
- Reduce max concurrent notes
- Increase sleep interval in `scheduleUpdate()` (lower FPS)

---

## 🎯 Next Steps

1. **Sound Integration**: Add audio feedback when keys are pressed
2. **Combo System**: Track consecutive hits
3. **Miss Penalties**: Deduct score for missed notes
4. **Visual Effects**: Add particles when notes are hit
5. **Difficulty Levels**: Vary fall speed and note frequency

---

Enjoy your new vertical falling notes system! 🎹✨
