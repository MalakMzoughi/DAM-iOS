# AI Avatar Implementation for iOS

## Overview
This document describes the implementation of AI-powered avatar generation using Gemini AI, matching the Android implementation.

## Files Created/Modified

### New Files
1. **AIAvatarPromptDialog.swift** - Dialog for entering AI prompt to generate avatar
2. **AIAvatarPreviewDialog.swift** - Dialog for previewing and saving generated avatar

### Modified Files
1. **AvatarNameInputView.swift** - Integrated AI avatar dialogs into avatar creation flow
2. **AvatarModels.swift** - Already had AI generation models (no changes needed)
3. **AvatarService.swift** - Already had AI API methods (no changes needed)
4. **AvatarViewModel.swift** - Already had AI generation logic (no changes needed)

## Architecture

### Data Flow
```
User Input → AIAvatarPromptDialog 
          → AvatarViewModel.generateAvatarFromPrompt()
          → AvatarService.generateAvatarFromPrompt()
          → Backend API (/api/avatars/generate-from-prompt)
          → Gemini AI
          → AvatarGenerationResponse
          → AIAvatarPreviewDialog
          → User approves → saveAIAvatar()
          → Backend API (/api/avatars/save-ai-avatar)
          → Avatar saved
```

### Key Components

#### 1. AIAvatarPromptDialog
- **Purpose**: Collect user's description of desired avatar
- **Features**:
  - Text input for AI prompt
  - Example prompts to inspire users
  - Loading state during generation
  - Error handling
  - Back and Generate buttons
- **Properties**:
  - `avatarName`: Name for the avatar
  - `onGenerateAvatar`: Callback with (prompt, style)
  - `onBack`: Go back to selection
  - `onDismiss`: Cancel dialog
  - `isLoading`: Show loading indicator
  - `error`: Display error messages

#### 2. AIAvatarPreviewDialog
- **Purpose**: Display generated avatar and allow save/regenerate
- **Features**:
  - Large image display (400pt height)
  - Async image loading with progress indicator
  - Avatar name and AI description
  - Three action buttons: Cancel, Regenerate, Save
  - Loading state during save
- **Properties**:
  - `avatarName`: Avatar name
  - `generationResponse`: Full AI response with image URL
  - `onSave`: Save the avatar
  - `onRegenerate`: Generate again with new prompt
  - `onDismiss`: Cancel and go back
  - `isSaving`: Show saving indicator

#### 3. AvatarViewModel (Existing)
Already implemented with these AI methods:
- `generateAvatarFromPrompt(prompt:name:style:)`
- `saveAIGeneratedAvatar(previewData:)`
- `clearGeneratedPreview()`
- Published properties: `isGeneratingAI`, `generationError`, `generatedAvatarPreview`, `isSavingAI`

#### 4. AvatarService (Existing)
Already implemented with these API methods:
- `generateAvatarFromPrompt(dto:)` → POST /api/avatars/generate-from-prompt
- `saveAIAvatar(previewData:)` → POST /api/avatars/save-ai-avatar

## API Integration

### Backend Endpoints

#### 1. Generate Avatar from Prompt
```http
POST /api/avatars/generate-from-prompt
Headers:
  X-Auth-Token: <token>
  X-Provider-ID: <providerId>
  Content-Type: application/json

Body:
{
  "prompt": "Naruto with orange clothes",
  "name": "MyAvatar",
  "style": "cartoon"
}

Response: AvatarGenerationResponse
{
  "name": "MyAvatar",
  "description": "...",
  "aiGeneratedDescription": "...",
  "suggestedAttributes": {...},
  "avatarImageUrl": "https://...",
  "generationSource": "gemini-ai",
  "previewData": {...}
}
```

#### 2. Save AI Avatar
```http
POST /api/avatars/save-ai-avatar
Headers:
  X-Auth-Token: <token>
  X-Provider-ID: <providerId>
  Content-Type: application/json

Body:
{
  "previewData": {...}
}

Response: SaveAIAvatarResponse
{
  "avatarId": "...",
  "name": "...",
  "avatarImageUrl": "...",
  "aiGeneratedDescription": "...",
  "generationSource": "gemini-ai",
  "avatar": {...}
}
```

## User Flow

### 1. Avatar Creation Selection
User navigates to avatar creation and sees two options:
- **AI Generated** (🤖) - Uses Gemini AI
- **3D Customizable** (🎨) - Uses Ready Player Me

### 2. AI Avatar Generation Flow
1. User taps "AI Generated"
2. `AIAvatarPromptDialog` appears
3. User enters name (if not already entered)
4. User describes their desired avatar (e.g., "Naruto with orange clothes")
5. User taps "Generate"
6. Loading indicator shows "🎨 Creating your avatar with AI magic..."
7. Backend calls Gemini AI to generate image
8. `AIAvatarPreviewDialog` appears with generated image
9. User can:
   - **Save**: Accept and save avatar
   - **Regenerate**: Go back and try a different prompt
   - **Cancel**: Discard and return to selection

### 3. Success
- Avatar is saved to backend
- User returns to avatar list
- New avatar appears in their collection

## Styling & Design

### Colors
- Primary gradient: `#667EEA` → `#764BA2` (Purple/Blue)
- Success button: `#4CAF50` (Green)
- Warning button: `#FFA726` (Orange)
- Error: `Color.red`

### Layout
- Dialog max width: 500pt
- Avatar image height: 400pt
- Button height: 56pt
- Corner radius: 12-24pt
- Padding: 20-24pt

### Animations
- Fade in/out transitions for dialogs
- Pulse animation for preview image
- Loading spinners during API calls

## Example Prompts
To help users get started, these example prompts are provided:
- "Naruto with orange clothes"
- "Mickey Mouse style character"
- "Pikachu inspired character"
- "Superhero with blue cape"
- "Princess with pink hair"
- "Ninja with black outfit"
- "Wizard with purple robe"

## Error Handling

### Common Errors
1. **Empty prompt**: "Please describe your avatar"
2. **Generation failed**: Backend error message displayed
3. **Image load failed**: Error icon with message
4. **Network error**: "Check your internet connection"
5. **Auth error**: "Not authenticated"

### Recovery
- All errors show in red with dismiss button
- User can retry generation
- Cancel button always available (when not loading)

## Testing Checklist

- [ ] AI prompt dialog appears when "AI Generated" is tapped
- [ ] Example prompts work when clicked
- [ ] Generate button validates empty prompt
- [ ] Loading indicator shows during generation
- [ ] Preview dialog appears with generated image
- [ ] Image loads correctly (or shows error)
- [ ] Regenerate returns to prompt dialog
- [ ] Save button creates avatar successfully
- [ ] Cancel dismisses dialog at any stage
- [ ] Backend errors are displayed correctly
- [ ] Auth headers are sent correctly
- [ ] Avatar appears in avatar list after save

## Future Enhancements

1. **Style selection**: Allow users to pick art style (cartoon, realistic, anime, etc.)
2. **Prompt suggestions**: AI-powered prompt refinement
3. **Multiple generations**: Generate 3-4 options at once
4. **Avatar editing**: Modify generated avatar
5. **Prompt history**: Save and reuse prompts
6. **Share avatars**: Share with friends
7. **Avatar animations**: Animated expressions
8. **Voice customization**: Match avatar personality

## Notes

- Backend must have Gemini AI API key configured
- Image generation can take 5-15 seconds
- Images are cached by AsyncImage
- PreviewData is opaque - backend manages it
- Kid-friendly content filtering is handled by backend
