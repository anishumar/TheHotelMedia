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
    let onLoadMore: () -> Void
    let onVideoChanged: ((Int) -> Void)?
    let onLike: ((String, Bool) -> Void)?
    let onComment: ((String) -> Void)?
    let onShare: ((String) -> Void)?
    let onBookmark: ((String, Bool) -> Void)?
    let onProfileTapped: ((String) -> Void)?
    
    func makeUIViewController(context: Context) -> ReelsViewController {
        let controller = ReelsViewController()
        controller.setReels(reels, initialID: initialReelID)
        controller.setMuted(isMuted)
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
        uiViewController.onLoadMore = onLoadMore
        uiViewController.onVideoChanged = onVideoChanged
        uiViewController.onLike = onLike
        uiViewController.onComment = onComment
        uiViewController.onShare = onShare
        uiViewController.onBookmark = onBookmark
        uiViewController.onProfileTapped = onProfileTapped
    }
}

