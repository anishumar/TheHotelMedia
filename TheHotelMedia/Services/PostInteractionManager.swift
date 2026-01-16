//
//  PostInteractionManager.swift
//  TheHotelMedia
//
//  Created by Auto on 31/01/25.
//

import SwiftUI
import Combine
import SwiftfulRouting

/// Unified manager for all post interactions (like, comment, share, bookmark)
/// Provides instant optimistic updates and centralized state management
class PostInteractionManager: ObservableObject {
    static let shared = PostInteractionManager()
    
    // Published state for all interactions
    @Published private var postStates: [String: PostInteractionState] = [:]
    
    // Notification center for broadcasting updates
    private let notificationCenter = NotificationCenter.default
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get current interaction state for a post
    func getState(for postID: String) -> PostInteractionState {
        return postStates[postID] ?? PostInteractionState()
    }
    
    /// Like/Unlike a post with optimistic update
    func toggleLike(postID: String, currentState: PostInteractionState, onUpdate: @escaping (PostInteractionState) -> Void) {
        let newLikedState = !currentState.isLiked
        let newLikesCount = newLikedState ? currentState.likesCount + 1 : max(0, currentState.likesCount - 1)
        
        // Optimistic update
        let updatedState = PostInteractionState(
            isLiked: newLikedState,
            likesCount: newLikesCount,
            isBookmarked: currentState.isBookmarked,
            commentsCount: currentState.commentsCount,
            sharesCount: currentState.sharesCount,
            viewsCount: currentState.viewsCount
        )
        
        postStates[postID] = updatedState
        onUpdate(updatedState)
        
        // Broadcast update
        broadcastUpdate(postID: postID, state: updatedState)
        
        // Perform network request
        Task {
            do {
                let dataManager = PostDataManager()
                let _ = try await dataManager.likeAPost(postID: postID)
                
                // Network success - state already updated optimistically
                await MainActor.run {
                    // Optionally refresh from server if needed
                }
            } catch {
                // Rollback on error
                await MainActor.run {
                    postStates[postID] = currentState
                    onUpdate(currentState)
                    broadcastUpdate(postID: postID, state: currentState)
                }
            }
        }
    }
    
    /// Bookmark/Unbookmark a post with optimistic update
    func toggleBookmark(postID: String, currentState: PostInteractionState, onUpdate: @escaping (PostInteractionState) -> Void) {
        let newBookmarkedState = !currentState.isBookmarked
        
        // Optimistic update
        let updatedState = PostInteractionState(
            isLiked: currentState.isLiked,
            likesCount: currentState.likesCount,
            isBookmarked: newBookmarkedState,
            commentsCount: currentState.commentsCount,
            sharesCount: currentState.sharesCount,
            viewsCount: currentState.viewsCount
        )
        
        postStates[postID] = updatedState
        onUpdate(updatedState)
        
        // Broadcast update
        broadcastUpdate(postID: postID, state: updatedState)
        
        // Perform network request
        Task {
            do {
                let dataManager = PostDataManager()
                let _ = try await dataManager.saveAPost(postID: postID)
                
                // Network success - state already updated optimistically
            } catch {
                // Rollback on error
                await MainActor.run {
                    postStates[postID] = currentState
                    onUpdate(currentState)
                    broadcastUpdate(postID: postID, state: currentState)
                }
            }
        }
    }
    
    /// Update comment count (called after posting a comment)
    func incrementCommentCount(postID: String) {
        let currentState = getState(for: postID)
        let updatedState = PostInteractionState(
            isLiked: currentState.isLiked,
            likesCount: currentState.likesCount,
            isBookmarked: currentState.isBookmarked,
            commentsCount: currentState.commentsCount + 1,
            sharesCount: currentState.sharesCount,
            viewsCount: currentState.viewsCount
        )
        
        postStates[postID] = updatedState
        broadcastUpdate(postID: postID, state: updatedState)
    }
    
    /// Update share count (called after sharing)
    func incrementShareCount(postID: String) {
        let currentState = getState(for: postID)
        let updatedState = PostInteractionState(
            isLiked: currentState.isLiked,
            likesCount: currentState.likesCount,
            isBookmarked: currentState.isBookmarked,
            commentsCount: currentState.commentsCount,
            sharesCount: currentState.sharesCount + 1,
            viewsCount: currentState.viewsCount
        )
        
        postStates[postID] = updatedState
        broadcastUpdate(postID: postID, state: updatedState)
    }
    
    /// Initialize state from PostData
    func initializeState(from postData: PostData) {
        guard let postID = postData.id else { return }
        
        let state = PostInteractionState(
            isLiked: postData.likedByMe ?? false,
            likesCount: postData.likes ?? 0,
            isBookmarked: postData.savedByMe ?? false,
            commentsCount: postData.comments ?? 0,
            sharesCount: postData.shared ?? 0,
            viewsCount: postData.views ?? 0
        )
        
        postStates[postID] = state
    }
    
    /// Update state from PostData (for refresh scenarios)
    func updateState(from postData: PostData) {
        guard let postID = postData.id else { return }
        
        let newState = PostInteractionState(
            isLiked: postData.likedByMe ?? false,
            likesCount: postData.likes ?? 0,
            isBookmarked: postData.savedByMe ?? false,
            commentsCount: postData.comments ?? 0,
            sharesCount: postData.shared ?? 0,
            viewsCount: postData.views ?? 0
        )
        
        // Only update if different to avoid unnecessary broadcasts
        if let currentState = postStates[postID], currentState != newState {
            postStates[postID] = newState
            broadcastUpdate(postID: postID, state: newState)
        } else if postStates[postID] == nil {
            postStates[postID] = newState
        }
    }
    
    // MARK: - Private Helpers
    
    private func broadcastUpdate(postID: String, state: PostInteractionState) {
        notificationCenter.post(
            name: .postInteractionUpdated,
            object: nil,
            userInfo: [
                "postID": postID,
                "state": state
            ]
        )
    }
}

// MARK: - Post Interaction State

struct PostInteractionState: Equatable {
    var isLiked: Bool = false
    var likesCount: Int = 0
    var isBookmarked: Bool = false
    var commentsCount: Int = 0
    var sharesCount: Int = 0
    var viewsCount: Int = 0
}

// MARK: - Notification Names

extension Notification.Name {
    static let postInteractionUpdated = Notification.Name("postInteractionUpdated")
}
