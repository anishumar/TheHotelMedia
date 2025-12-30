# Changelog

## Recent Changes

### 1. Removed Keyboard Toolbar from All Screens
**Issue:** Keyboard toolbar with "Done" button and "4H" text was blocking the view when keyboard appeared.

**Changes:**
- Removed `.toolbar { ToolbarItemGroup(placement: .keyboard) }` from 13 screens:
  - `CreatePostScreen.swift`
  - `CreateReviewView.swift`
  - `EditPostScreen.swift`
  - `BookingCheckoutView.swift`
  - `RoomDetailView.swift` (2 instances)
  - `EditContactView.swift` (2 instances)
  - `CreateEventScreen.swift`
  - `CreateJobPostView.swift`
  - `OtpView.swift`
  - `BusinessDetailView.swift`
  - `IndividualSignupView.swift`
  - `ManagerDetailView.swift`
  - `HelpAndSupportView.swift`

**Impact:** 
- Keyboard still functions normally
- Users can dismiss keyboard by tapping outside or using system gestures
- No blocking toolbar above keyboard
- Cleaner UI experience

---

### 2. Added Back Button to Signup Screen
**Issue:** Users couldn't navigate back from the account type selection screen.

**Changes:**
- Added `dismissScreen()` method to `SignupAccountTypeViewModel.swift`
- Added back button UI component to `SignupAccountTypeView.swift`
- Button positioned at top-left corner with consistent styling

**Files Modified:**
- `TheHotelMedia/Screens/Authorization/SignupScreen/ViewModel/SignupAccountTypeViewModel.swift`
- `TheHotelMedia/Screens/Authorization/SignupScreen/Views/SignupAccountTypeView.swift`

---

### 3. Custom Camera Implementation
**Feature:** Custom camera view with tap-for-photo and hold-for-video functionality.

**New File Created:**
- `TheHotelMedia/Components/CustomImagePicker/CustomCameraView.swift`

**Features:**
- **Single Tap:** Captures photo
- **Hold Shutter:** Records video (maximum 3 minutes)
- **Auto-stop:** Video recording automatically stops at 3-minute limit
- **Timer Display:** Shows recording duration (MM:SS format)
- **Recording Indicator:** Red dot indicator when recording
- **Flip Camera:** Switch between front and back camera
- **Close Button:** Cancel and return to previous screen
- **Audio Support:** Includes microphone input for video recording

**Camera Flow:**
1. User taps camera button → Opens `CustomCameraView`
2. **Photo Mode:** Single tap on shutter → Captures photo → Goes to `EditStoryImageView` → Edit with all options → Post
3. **Video Mode:** Hold shutter button → Records video (max 3 min) → Goes to `EditStoryVideoView` → Edit with all options → Post

**Files Modified:**
- `TheHotelMedia/Screens/MainTabBar/TabBar/ViewModel/MainTabBarViewModel.swift`
  - Added `capturedPhoto: UIImage?` property
  - Added `capturedVideo: URL?` property
  - Added subscribers to handle photo and video capture
- `TheHotelMedia/Screens/MainTabBar/TabBar/View/MainTabBarView.swift`
  - Replaced `SUImagePickerView` with `CustomCameraView` for story creation

**Permissions Added:**
- `NSCameraUsageDescription` in `Info.plist`
- `NSMicrophoneUsageDescription` in `Info.plist`

---

### 4. Enhanced Video Edit View
**Change:** Added Filter button to video edit screen to match photo edit screen.

**Files Modified:**
- `TheHotelMedia/Screens/Others/EditStoryImage/View/EditStoryImageView.swift`
  - Added Filter button to `editStoryVideoBottomButtonSection`
  - Added filter overlay support (placeholder for future video filter implementation)

**Edit View Options (Both Photo & Video):**
1. **Filter** - Apply filters to media
2. **Emoji** - Add emoji overlays
3. **Text** - Add text overlays
4. **Tag People** - Tag users in the story
5. **Tag Location** - Add location tags

---

### 5. Project File Updates
**Change:** Added new camera view file to Xcode project.

**Files Modified:**
- `TheHotelMedia.xcodeproj/project.pbxproj`
  - Added `CustomCameraView.swift` to PBXBuildFile section
  - Added file reference
  - Added to CustomImagePicker group
  - Added to Sources build phase

---

## Technical Details

### Camera Implementation
- Uses `AVFoundation` framework
- `AVCaptureSession` for camera management
- `AVCapturePhotoOutput` for photo capture
- `AVCaptureMovieFileOutput` for video recording
- Maximum video duration: 180 seconds (3 minutes)
- Video format: MOV
- Photo format: HEVC when available, otherwise default

### Code Structure
```
CustomCameraView.swift
├── CustomCameraView (UIViewControllerRepresentable)
│   └── Coordinator (handles callbacks)
└── CameraViewController (UIViewController)
    ├── Camera setup (AVCaptureSession)
    ├── UI components (shutter, flip, close buttons)
    ├── Photo capture logic
    └── Video recording logic
```

### Integration Points
- **Entry Point:** `MainTabBarView.swift` - Camera button opens `CustomCameraView`
- **Photo Handler:** `MainTabBarViewModel.capturedPhoto` → `EditStoryImageView`
- **Video Handler:** `MainTabBarViewModel.capturedVideo` → `EditStoryVideoView`
- **Posting:** Both flows end with story posting via `postStory()` method

---

## Testing Checklist
- [ ] Camera opens when camera button is tapped
- [ ] Single tap captures photo
- [ ] Hold button records video
- [ ] Video stops automatically at 3 minutes
- [ ] Timer displays correctly during recording
- [ ] Flip camera button works
- [ ] Close button dismisses camera
- [ ] Photo goes to edit screen with all 5 options
- [ ] Video goes to edit screen with all 5 options
- [ ] Story posts successfully after editing
- [ ] Permissions are requested correctly
- [ ] No keyboard toolbar appears on any screen

---

## Notes
- Video filtering is currently a placeholder (shows "coming soon" message)
- Camera permissions are requested when camera is opened
- Microphone permissions are requested for video recording
- The custom camera replaces the old `SUImagePickerView` for story creation only
- Other parts of the app still use `SUImagePickerView` for profile pictures, etc.

---

## Commit Information
- **Commit Hash:** `2384e4d`
- **Branch:** `deployment`
- **Files Changed:** 16 files
- **Insertions:** 26 lines
- **Deletions:** 76 lines

