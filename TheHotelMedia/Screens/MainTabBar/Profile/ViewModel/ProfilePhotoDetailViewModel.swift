//
//  ProfilePhotoDetailViewModel.swift
//  TheHotelMedia
//
//  Created by GPT-5 Codex on 10/11/24.
//

import Foundation

final class ProfilePhotoDetailViewModel: ObservableObject {
    
    @Published var posts: [PostData] = []
    @Published var isLoading: Bool = false
    @Published var currentPage: Int = 1
    @Published var hasMorePages: Bool = true
    @Published var targetPostID: String?
    @Published var shouldAutoScroll: Bool = false
    
    let profileData: ProfileData?
    let userProfileID: String
    let initialMediaID: String?
    
    private let dataManager = ProfileDataManager()
    
    init(userProfileID: String, initialMediaID: String?, profileData: ProfileData? = nil) {
        self.userProfileID = userProfileID
        self.initialMediaID = initialMediaID
        self.profileData = profileData
        
        print("📸 [PhotoDetail] Initialized for user: \(userProfileID), starting media: \(initialMediaID ?? "nil")")
    }
    
    func loadPosts() {
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
                            // Filter posts that have images
                            let postsWithImages = newPosts.filter { post in
                                post.mediaRef?.contains(where: { $0.mediaType == "image" }) ?? false
                            }
                            
                            print("📸 [PhotoDetail] Loaded page \(currentPage): \(newPosts.count) posts, \(postsWithImages.count) with images")
                            
                            posts += postsWithImages
                            currentPage = (result.pageNo ?? currentPage) + 1
                            hasMorePages = currentPage <= (result.totalPages ?? 1)
                            
                            if let initialMediaID, targetPostID == nil {
                                if let targetPost = posts.first(where: { post in
                                    post.mediaRef?.contains(where: { $0.id == initialMediaID }) ?? false
                                }) {
                                    targetPostID = targetPost.id ?? targetPost.mediaRef?.first?.id
                                    shouldAutoScroll = targetPostID != nil
                                } else if hasMorePages {
                                    shouldFetchNextPage = true
                                }
                            }
                        }
                    } else {
                        print("❌ [PhotoDetail] Failed to load posts: \(result.message)")
                    }
                }
                
                if shouldFetchNextPage {
                    loadPosts()
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ [PhotoDetail] Error loading posts: \(error)")
                }
            }
        }
    }
    
}

