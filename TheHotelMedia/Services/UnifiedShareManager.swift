//
//  UnifiedShareManager.swift
//  TheHotelMedia
//
//  Created by Auto on 31/01/25.
//

import SwiftUI
import SwiftfulRouting

/// Unified manager for share functionality across the app
/// Ensures consistent behavior and single source of truth for sharing
class UnifiedShareManager: ObservableObject {
    static let shared = UnifiedShareManager()
    
    @Published var isShareSheetPresented: Bool = false
    @Published var sharePostData: PostData?
    @Published var shareURL: URL?
    
    var currentRouter: AnyRouter? // Internal access for sheet presentation
    private var onDismiss: (() -> Void)?
    private var onStoryShared: (() -> Void)?
    
    private init() {}
    
    /// Present share sheet for a post
    func presentShareSheet(
        postData: PostData,
        router: AnyRouter,
        onDismiss: (() -> Void)? = nil,
        onStoryShared: (() -> Void)? = nil
    ) {
        guard let postID = postData.id else { return }
        
        self.sharePostData = postData
        self.currentRouter = router
        self.onDismiss = onDismiss
        self.onStoryShared = onStoryShared
        
        // Generate share URL
        let baseURLString = "https://thehotelmedia.com/share/posts"
        if let encryptedID = EncryptionHelper.encrypt(postID),
           let encryptedUserID = EncryptionHelper.encrypt(UserDefaults.standard.string(forKey: "ownUserID") ?? "") {
            shareURL = URL(string: "\(baseURLString)?postID=\(encryptedID)&userID=\(encryptedUserID)")
        } else {
            shareURL = URL(string: "\(baseURLString)?postID=\(postID)")
        }
        
        isShareSheetPresented = true
    }
    
    /// Dismiss share sheet
    func dismissShareSheet() {
        isShareSheetPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.sharePostData = nil
            self.shareURL = nil
            self.currentRouter = nil
            self.onDismiss?()
            self.onDismiss = nil
            self.onStoryShared = nil
        }
    }
    
    /// Handle story shared callback
    func handleStoryShared() {
        onStoryShared?()
    }
}
