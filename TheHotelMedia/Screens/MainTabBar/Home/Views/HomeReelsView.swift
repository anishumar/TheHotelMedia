//
//  HomeReelsView.swift
//  TheHotelMedia
//
//  Created by Auto on 26/02/25.
//

import SwiftUI
import SwiftfulRouting
import AVFoundation

// Helper struct to make String Identifiable for fullScreenCover(item:)
struct ProfileIDItem: Identifiable {
    let id: String
}

struct HomeReelsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    // Local navigation state for pushing profile directly from reels
    @State private var selectedProfileID: ProfileIDItem? = nil
    
    let reels: [Reel]
    let initialReelID: String?
    let isMuted: Bool
    let onLoadMore: () -> Void
    let onVideoChanged: ((Int) -> Void)?
    let onLike: ((String, Bool) -> Void)?
    let onComment: ((String) -> Void)?
    let onShare: ((String) -> Void)?
    let onBookmark: ((String, Bool) -> Void)?
    /// Optional external hook if parent also wants the callback.
    let onProfileTapped: ((String) -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            if reels.isEmpty {
                VStack {
                    Spacer()
                    EmptyScreenView(image: "VideosIcon", title: "no_video_uploaded_yet".localized(localizationManager.language))
                    Spacer()
                }
            } else {
                ReelsViewRepresentable(
                    reels: reels,
                    initialReelID: initialReelID,
                    isMuted: isMuted,
                    showBackButton: false,
                    onLoadMore: onLoadMore,
                    onVideoChanged: onVideoChanged,
                    onLike: onLike,
                    onComment: onComment,
                    onShare: onShare,
                    onBookmark: onBookmark,
                    onProfileTapped: { profileID in
                        guard !profileID.isEmpty else { 
                            print("⚠️ [HomeReelsView] Empty profileID received")
                            return 
                        }
                        print("✅ [HomeReelsView] Navigating to profile: \(profileID)")
                        // Pause reels when navigating to profile
                        NotificationCenter.default.post(name: NSNotification.Name("PauseReelsVideos"), object: nil)
                        // Set profile ID - this will trigger the fullScreenCover
                        selectedProfileID = ProfileIDItem(id: profileID)
                        // Forward to external handler if needed
                        onProfileTapped?(profileID)
                    }
                )
                .frame(height: UIScreen.main.bounds.height - UIApplication.topSafeAreaHeightTHM - UIApplication.bottomSafeAreaHeightTHM - 60)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            // Set up audio session for video playback with sound
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
            } catch {
                print("Failed to set audio session category: \(error)")
            }
        }
        // Present profile directly over reels when username is tapped
        .fullScreenCover(item: $selectedProfileID) { profileItem in
            VStack {
                RouterView { router in
                    UserProfileView2(
                        viewModel: UserProfileViewModel(
                            router: router,
                            publicProfileID: profileItem.id
                        )
                    )
                    .environmentObject(themeManager)
                    .environmentObject(localizationManager)
                    .navigationBarBackButtonHidden()
                    .background(BackgroundClearView())
                }
                .background(BackgroundClearView())
            }
            .background(BackgroundClearView())
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                onDismiss()
            }, label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .frame(width: 32, height: 32)
            })
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
}
