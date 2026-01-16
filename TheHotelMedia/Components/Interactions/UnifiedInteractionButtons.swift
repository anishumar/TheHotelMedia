//
//  UnifiedInteractionButtons.swift
//  TheHotelMedia
//
//  Created by Auto on 31/01/25.
//

import SwiftUI
import SwiftfulRouting

/// Unified interaction buttons component that works consistently everywhere
/// Handles like, comment, share, bookmark, and views
struct UnifiedInteractionButtons: View {
    let postID: String
    let postData: PostData
    let router: AnyRouter?
    
    @StateObject private var interactionManager = PostInteractionManager.shared
    @StateObject private var shareManager = UnifiedShareManager.shared
    @StateObject private var commentManager = UnifiedCommentManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var interactionState: PostInteractionState
    @State private var heartScale: CGFloat = 1.0
    
    init(postID: String, postData: PostData, router: AnyRouter?) {
        self.postID = postID
        self.postData = postData
        self.router = router
        
        // Initialize state from post data
        _interactionState = State(initialValue: PostInteractionState(
            isLiked: postData.likedByMe ?? false,
            likesCount: postData.likes ?? 0,
            isBookmarked: postData.savedByMe ?? false,
            commentsCount: postData.comments ?? 0,
            sharesCount: postData.shared ?? 0,
            viewsCount: postData.views ?? 0
        ))
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Like button
            likeButton
            
            // Comment button
            commentButton
            
            // Share button
            shareButton
            
            // Views (read-only)
            if interactionState.viewsCount > 0 {
                viewsButton
            }
            
            Spacer()
            
            // Bookmark button
            bookmarkButton
        }
        .padding(.horizontal, 12)
        .onAppear {
            // Initialize manager state
            interactionManager.initializeState(from: postData)
            updateStateFromManager()
        }
        .onReceive(NotificationCenter.default.publisher(for: .postInteractionUpdated)) { notification in
            guard let updatedPostID = notification.userInfo?["postID"] as? String,
                  updatedPostID == postID,
                  let state = notification.userInfo?["state"] as? PostInteractionState else {
                return
            }
            
            interactionState = state
            updateHeartScale()
        }
        .sheet(isPresented: $shareManager.isShareSheetPresented) {
            if let postData = shareManager.sharePostData,
               let shareURL = shareManager.shareURL,
               let router = shareManager.currentRouter {
                UnifiedShareSheet(
                    shareURL: shareURL.absoluteString,
                    postData: postData,
                    router: router,
                    onChatSelected: { username, userID, profilePic, name in
                        // Handle chat selection
                    },
                    onDismiss: {
                        shareManager.dismissShareSheet()
                    },
                    onStoryShared: {
                        shareManager.handleStoryShared()
                        PostInteractionManager.shared.incrementShareCount(postID: postID)
                    }
                )
                .environmentObject(ThemeManager.shared)
                .environmentObject(LocalizationManager.shared)
                .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $commentManager.isCommentSheetPresented) {
            if let router = router {
                CommentSectionView(
                    showScreen: .constant(true),
                    newComment: .constant(""),
                    replyComment: .constant(nil),
                    viewModel: CommentSectionViewModel(
                        postID: commentManager.commentPostID,
                        totalComments: commentManager.commentCount,
                        onAddingComment: { _ in
                            let newCount = commentManager.commentCount + 1
                            commentManager.handleCommentAdded(newCount: newCount)
                        }
                    )
                )
                .environmentObject(ThemeManager.shared)
                .environmentObject(LocalizationManager.shared)
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    // MARK: - Button Components
    
    private var likeButton: some View {
        HStack(spacing: 6) {
            Image(interactionState.isLiked ? "heartfill" : themeManager.currentTheme.heart)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .scaleEffect(heartScale)
            
            Text(formatNumber(Double(interactionState.likesCount)))
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundStyle(themeManager.currentTheme.label)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .stroke(lineWidth: 1)
                .fill(.hmIndigo.opacity(0.6))
        )
        .onTapGesture {
            haptics(.medium)
            
            // Animate heart
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                heartScale = interactionState.isLiked ? 1.0 : 1.2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    heartScale = 1.0
                }
            }
            
            // Update state
            interactionManager.toggleLike(
                postID: postID,
                currentState: interactionState
            ) { updatedState in
                interactionState = updatedState
            }
        }
    }
    
    private var commentButton: some View {
        HMCustomButton2(
            icon: themeManager.currentTheme.comment,
            count: formatNumber(Double(interactionState.commentsCount))
        )
        .onTapGesture {
            haptics(.light)
            guard let router = router else { return }
            commentManager.presentCommentSheet(
                postID: postID,
                currentCommentCount: interactionState.commentsCount
            ) { newCount in
                interactionState.commentsCount = newCount
            }
        }
    }
    
    private var shareButton: some View {
        HMCustomButton2(
            icon: themeManager.currentTheme.share,
            count: formatNumber(Double(interactionState.sharesCount))
        )
        .onTapGesture {
            haptics(.light)
            guard let router = router else { return }
            shareManager.presentShareSheet(
                postData: postData,
                router: router
            ) {
                // Share completed
            } onStoryShared: {
                // Story shared
            }
        }
    }
    
    private var viewsButton: some View {
        HMCustomButton2(
            icon: themeManager.currentTheme.eye3,
            count: formatNumber(Double(interactionState.viewsCount))
        )
    }
    
    private var bookmarkButton: some View {
        Button(action: {
            haptics(.light)
            interactionManager.toggleBookmark(
                postID: postID,
                currentState: interactionState
            ) { updatedState in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    interactionState = updatedState
                }
            }
        }) {
            Image(interactionState.isBookmarked ? "bookmarkfill" : themeManager.currentTheme.bookmark)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .scaleEffect(interactionState.isBookmarked ? 1.2 : 1.0)
                .animation(.none, value: interactionState.isBookmarked)
        }
    }
    
    // MARK: - Helpers
    
    private func updateStateFromManager() {
        let managerState = interactionManager.getState(for: postID)
        if managerState.likesCount > 0 || managerState.commentsCount > 0 {
            interactionState = managerState
        }
    }
    
    private func updateHeartScale() {
        if interactionState.isLiked {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                heartScale = 1.1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    heartScale = 1.0
                }
            }
        }
    }
    
    private func formatNumber(_ number: Double) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", number / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", number / 1_000)
        } else {
            return String(format: "%.0f", number)
        }
    }
}
