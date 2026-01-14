//
//  HomeReelsView.swift
//  TheHotelMedia
//
//  Created by Auto on 26/02/25.
//

import SwiftUI
import SwiftfulRouting
import AVFoundation

struct HomeReelsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    let reels: [Reel]
    let initialReelID: String?
    let isMuted: Bool
    let onLoadMore: () -> Void
    let onVideoChanged: ((Int) -> Void)?
    let onLike: ((String, Bool) -> Void)?
    let onComment: ((String) -> Void)?
    let onShare: ((String) -> Void)?
    let onBookmark: ((String, Bool) -> Void)?
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
                    onProfileTapped: onProfileTapped
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
            
            Text("videos".localized(localizationManager.language).capitalized)
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
}
