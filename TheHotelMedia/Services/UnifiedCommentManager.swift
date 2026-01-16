//
//  UnifiedCommentManager.swift
//  TheHotelMedia
//
//  Created by Auto on 31/01/25.
//

import SwiftUI
import SwiftfulRouting

/// Unified manager for comment functionality
/// Ensures consistent comment sheet presentation and state management
class UnifiedCommentManager: ObservableObject {
    static let shared = UnifiedCommentManager()
    
    @Published var isCommentSheetPresented: Bool = false
    @Published var commentPostID: String = ""
    @Published var commentCount: Int = 0
    
    private var onCommentAdded: ((Int) -> Void)?
    
    private init() {}
    
    /// Present comment sheet for a post
    func presentCommentSheet(
        postID: String,
        currentCommentCount: Int,
        onCommentAdded: ((Int) -> Void)? = nil
    ) {
        self.commentPostID = postID
        self.commentCount = currentCommentCount
        self.onCommentAdded = onCommentAdded
        self.isCommentSheetPresented = true
    }
    
    /// Dismiss comment sheet
    func dismissCommentSheet() {
        isCommentSheetPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.commentPostID = ""
            self.commentCount = 0
            self.onCommentAdded = nil
        }
    }
    
    /// Handle comment added
    func handleCommentAdded(newCount: Int) {
        commentCount = newCount
        onCommentAdded?(newCount)
        
        // Notify interaction manager
        PostInteractionManager.shared.incrementCommentCount(postID: commentPostID)
    }
}
