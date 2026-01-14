//
//  ReelsViewRepresentable.swift
//  TheHotelMedia
//
//  Created by Auto on 26/02/25.
//

import SwiftUI

struct ReelsViewRepresentable: UIViewControllerRepresentable {
    let reels: [Reel]
    let initialReelID: String?
    let isMuted: Bool
    let showBackButton: Bool
    let onLoadMore: () -> Void
    let onVideoChanged: ((Int) -> Void)?
    let onLike: ((String, Bool) -> Void)?
    let onComment: ((String) -> Void)?
    let onShare: ((String) -> Void)?
    let onBookmark: ((String, Bool) -> Void)?
    let onProfileTapped: ((String) -> Void)?
    
    init(
        reels: [Reel],
        initialReelID: String?,
        isMuted: Bool,
        showBackButton: Bool = true,
        onLoadMore: @escaping () -> Void,
        onVideoChanged: ((Int) -> Void)? = nil,
        onLike: ((String, Bool) -> Void)? = nil,
        onComment: ((String) -> Void)? = nil,
        onShare: ((String) -> Void)? = nil,
        onBookmark: ((String, Bool) -> Void)? = nil,
        onProfileTapped: ((String) -> Void)? = nil
    ) {
        self.reels = reels
        self.initialReelID = initialReelID
        self.isMuted = isMuted
        self.showBackButton = showBackButton
        self.onLoadMore = onLoadMore
        self.onVideoChanged = onVideoChanged
        self.onLike = onLike
        self.onComment = onComment
        self.onShare = onShare
        self.onBookmark = onBookmark
        self.onProfileTapped = onProfileTapped
    }
    
    func makeUIViewController(context: Context) -> ReelsViewController {
        let controller = ReelsViewController()
        controller.setReels(reels, initialID: initialReelID)
        controller.setMuted(isMuted)
        controller.showBackButton = showBackButton
        controller.onLoadMore = onLoadMore
        controller.onVideoChanged = onVideoChanged
        controller.onLike = onLike
        controller.onComment = onComment
        controller.onShare = onShare
        controller.onBookmark = onBookmark
        controller.onProfileTapped = onProfileTapped
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ReelsViewController, context: Context) {
        // Don't pass initialID on updates - only on first load
        // The view controller tracks if it has already scrolled to initial
        uiViewController.setReels(reels, initialID: nil)
        uiViewController.setMuted(isMuted)
        uiViewController.showBackButton = showBackButton
        uiViewController.onLoadMore = onLoadMore
        uiViewController.onVideoChanged = onVideoChanged
        uiViewController.onLike = onLike
        uiViewController.onComment = onComment
        uiViewController.onShare = onShare
        uiViewController.onBookmark = onBookmark
        uiViewController.onProfileTapped = onProfileTapped
    }
}

