//
//  ProfileVideoDetailViewModel.swift
//  TheHotelMedia
//
//  Created by Auto on 26/02/25.
//

import Foundation
import SwiftUI

final class ProfileVideoDetailViewModel: ObservableObject {
    
    @Published var videoPosts: [PostData] = [] // Posts that contain videos
    @Published var isLoading: Bool = false
    @Published var currentPage: Int = 1
    @Published var hasMorePages: Bool = true
    @Published var targetVideoID: String?
    @Published var shouldAutoScroll: Bool = false
    @Published var showCommentSection: Bool = false
    @Published var commentSectionPostID: String = ""
    @Published var isSharePresented: Bool = false
    @Published var showShareAsStory: Bool = false
    var currentSharedPostID: String = ""
    @Published var shareURL: URL = URL(string: "https://thehotelmedia.com/post")!
    
    let profileData: ProfileData?
    let userProfileID: String
    let initialMediaID: String?
    
    private let dataManager = ProfileDataManager()
    private let postDataManager = PostDataManager()
    private let singlePostDataManager = SinglePostDataManager()
    
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    // Computed property to get videos from posts
    var videos: [MediaRef] {
        videoPosts.compactMap { post in
            post.mediaRef?.first(where: { $0.mediaType == "video" })
        }
    }
    
    init(userProfileID: String, initialMediaID: String?, profileData: ProfileData? = nil) {
        self.userProfileID = userProfileID
        self.initialMediaID = initialMediaID
        self.profileData = profileData
        
        print("🎥 [VideoDetail] Initialized for user: \(userProfileID), starting media: \(initialMediaID ?? "nil")")
    }
    
    func loadVideos() {
        guard !isLoading else { return }
        guard hasMorePages else { return }
        guard !userProfileID.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let result = try await dataManager.getProfilePosts(id: userProfileID, pageNo: currentPage)
                
                var shouldFetchNextPage = false
                
                await MainActor.run {
                    isLoading = false
                    
                    if result.status && (200...204).contains(result.statusCode) {
                        if let newPosts = result.data {
                            // Filter posts that have videos
                            let postsWithVideos = newPosts.filter { post in
                                post.mediaRef?.contains(where: { $0.mediaType == "video" }) ?? false
                            }
                            
                            print("🎥 [VideoDetail] Loaded page \(currentPage): \(newPosts.count) posts, \(postsWithVideos.count) with videos")
                            
                            videoPosts += postsWithVideos
                            currentPage = (result.pageNo ?? currentPage) + 1
                            hasMorePages = currentPage <= (result.totalPages ?? 1)
                            
                            if let initialMediaID, targetVideoID == nil {
                                if let targetPost = videoPosts.first(where: { post in
                                    post.mediaRef?.contains(where: { $0.id == initialMediaID && $0.mediaType == "video" }) ?? false
                                }) {
                                    if let video = targetPost.mediaRef?.first(where: { $0.id == initialMediaID }) {
                                        targetVideoID = video.id
                                        shouldAutoScroll = targetVideoID != nil
                                    }
                                } else if hasMorePages {
                                    shouldFetchNextPage = true
                                }
                            }
                        }
                    } else {
                        print("❌ [VideoDetail] Failed to load posts: \(result.message)")
                    }
                }
                
                if shouldFetchNextPage {
                    loadVideos()
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ [VideoDetail] Error loading posts: \(error)")
                }
            }
        }
    }
    
    // Get post for a specific video
    func getPost(for videoID: String) -> PostData? {
        return videoPosts.first { post in
            post.mediaRef?.contains(where: { $0.id == videoID && $0.mediaType == "video" }) ?? false
        }
    }
    
    // MARK: - Actions
    func likePost(postID: String, isLiked: Bool) {
        Task {
            do {
                let _ = try await postDataManager.likeAPost(postID: postID)
                await MainActor.run {
                    // Update post data optimistically
                    if let index = videoPosts.firstIndex(where: { $0.id == postID }) {
                        var updatedPost = videoPosts[index]
                        updatedPost.likedByMe = !isLiked
                        if let currentLikes = updatedPost.likes {
                            updatedPost.likes = isLiked ? max(0, currentLikes - 1) : currentLikes + 1
                        } else {
                            updatedPost.likes = isLiked ? 0 : 1
                        }
                        videoPosts[index] = updatedPost
                    }
                }
            } catch {
                print("❌ [VideoDetail] Error liking post: \(error)")
            }
        }
    }
    
    func bookmarkPost(postID: String, isSaved: Bool) {
        Task {
            do {
                let _ = try await postDataManager.saveAPost(postID: postID)
                await MainActor.run {
                    // Update post data optimistically
                    if let index = videoPosts.firstIndex(where: { $0.id == postID }) {
                        var updatedPost = videoPosts[index]
                        updatedPost.savedByMe = !isSaved
                        videoPosts[index] = updatedPost
                    }
                }
            } catch {
                print("❌ [VideoDetail] Error bookmarking post: \(error)")
            }
        }
    }
    
    func showCommentSection(postID: String) {
        commentSectionPostID = postID
        showCommentSection = true
    }
    
    func showShareView(postID: String) {
        let baseURLString = "https://thehotelmedia.com/share/posts"
        
        if !postID.isEmpty && !ownUserID.isEmpty {
            if let encryptedID = EncryptionHelper.encrypt(postID),
               let encryptedUserID = EncryptionHelper.encrypt(ownUserID) {
                currentSharedPostID = postID
                shareURL = URL(string: "\(baseURLString)?postID=\(encryptedID)&userID=\(encryptedUserID)")!
                isSharePresented = true
            }
        }
    }
    
    func shareAsStory() {
        shareAsStory(postID: currentSharedPostID)
    }
    
    private func shareAsStory(postID: String) {
        guard let post = videoPosts.first(where: { $0.id == postID }) ?? getPost(for: postID),
              let mediaRef = post.mediaRef, !mediaRef.isEmpty else {
            return
        }
        
        // Check if it's own post
        guard let postUserID = post.userID, postUserID != ownUserID else {
            return
        }
        
        let firstMedia = mediaRef[0]
        showShareAsStory = true
        
        if firstMedia.mediaType == "image", let imageURLString = firstMedia.sourceURL, let imageURL = URL(string: imageURLString) {
            downloadImageForStory(from: imageURL)
        } else if firstMedia.mediaType == "video", let videoURLString = firstMedia.sourceURL, let videoURL = URL(string: videoURLString) {
            downloadVideoForStory(from: videoURL)
        } else {
            showShareAsStory = false
        }
    }
    
    private func downloadImageForStory(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    await MainActor.run {
                        showShareAsStory = false
                    }
                    return
                }
                
                await MainActor.run {
                    showShareAsStory = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(name: .shareAsStory, object: nil, userInfo: ["image": image])
                    }
                }
            } catch {
                await MainActor.run {
                    showShareAsStory = false
                }
            }
        }
    }
    
    private func downloadVideoForStory(from url: URL) {
        Task {
            do {
                let (tempURL, _) = try await URLSession.shared.download(from: url)
                let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let destinationURL = cacheDirectory.appendingPathComponent("story_\(UUID().uuidString).mp4")
                
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try? FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                
                await MainActor.run {
                    showShareAsStory = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(name: .shareAsStory, object: nil, userInfo: ["videoURL": destinationURL])
                    }
                }
            } catch {
                await MainActor.run {
                    showShareAsStory = false
                }
            }
        }
    }
    
    func sharePost(postID: String, sharedByID: String) {
        Task {
            do {
                let result = try await singlePostDataManager.postShared(postID: postID, sharedByID: sharedByID)
                await MainActor.run {
                    if result.status && (200...204).contains(result.statusCode) {
                        // Update post data
                        if let index = videoPosts.firstIndex(where: { $0.id == postID }),
                           let updatedPost = result.data {
                            videoPosts[index] = updatedPost
                        }
                    }
                }
            } catch {
                print("❌ [VideoDetail] Error sharing post: \(error)")
            }
        }
    }
    
}

