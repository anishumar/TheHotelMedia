//
//  ProfilePhotoDetailViewModel.swift
//  TheHotelMedia
//
//  Created by GPT-5 Codex on 10/11/24.
//

import Foundation
import SwiftUI
import SwiftfulRouting

final class ProfilePhotoDetailViewModel: ObservableObject {
    
    @Published var posts: [PostData] = []
    @Published var isLoading: Bool = false
    @Published var currentPage: Int = 1
    @Published var hasMorePages: Bool = true
    @Published var targetPostID: String?
    @Published var shouldAutoScroll: Bool = false
    @Published var showCommentSection: Bool = false
    @Published var commentSectionPostID: String = ""
    @Published var isSharePresented: Bool = false
    @Published var shareURL: URL = URL(string: "https://thehotelmedia.com/post")!
    @Published var sharePostData: PostData? = nil
    @Published var showPostOptionView: Bool = false
    @Published var showReportScreen: Bool = false
    @Published var reportID: String = ""
    @Published var reportType: String = "post"
    
    let profileData: ProfileData?
    @Published var selectedPostID: String = ""
    @Published var currentTab: ProfileTab = .photos // For compatibility with EditPostViewModel
    @Published var selectedProfileID: String = ""
    @Published var showProfileScreen: Bool = false
    

    let userProfileID: String
    let initialMediaID: String?
    
    private let dataManager = ProfileDataManager()
    private let postDataManager = PostDataManager()
    private let singlePostDataManager = SinglePostDataManager()

    // Used to enrich MediaRef (from images endpoint) with parent post metadata (createdAt, likes, etc.)
    @MainActor private var didBuildPostLookup: Bool = false
    @MainActor private var isBuildingPostLookup: Bool = false
    @MainActor private var postLookupByMediaID: [String: PostData] = [:]
    
    @AppStorage("ownUserID") var ownUserID: String = ""
    var router: AnyRouter?
    private var preloadedPhotos: [MediaRef]?
    
    var onPostDeleted: ((String) -> Void)?
    
    init(userProfileID: String, initialMediaID: String?, profileData: ProfileData? = nil, preloadedPhotos: [MediaRef]? = nil, onPostDeleted: ((String) -> Void)? = nil, onPostUpdated: ((PostData) -> Void)? = nil) {
        self.userProfileID = userProfileID
        self.initialMediaID = initialMediaID
        self.profileData = profileData
        self.preloadedPhotos = preloadedPhotos
        self.onPostDeleted = onPostDeleted
        self.onPostUpdated = onPostUpdated
        
        print("📸 [PhotoDetail] Initialized for user: \(userProfileID), starting media: \(initialMediaID ?? "nil"), preloaded: \(preloadedPhotos?.count ?? 0)")
    }
    
    var onPostUpdated: ((PostData) -> Void)?
    

    
    func loadPosts() {
        print("🔍 [PhotoDetail] loadPosts called. isLoading: \(isLoading), hasMorePages: \(hasMorePages), userID: \(userProfileID)")
        Task { @MainActor in
            guard !isLoading else { return }
            guard hasMorePages else { return }
            guard !userProfileID.isEmpty else { return }
            
            isLoading = true
            
            // Use preloaded photos for the first page if available
            if currentPage == 1, let preloaded = preloadedPhotos, !preloaded.isEmpty {
                 print("📸 [PhotoDetail] Using \(preloaded.count) preloaded photos.")
                 let mediaToUse: [MediaRef]
                 if preloaded.allSatisfy({ !($0.createdAt ?? "").isEmpty }) {
                     mediaToUse = preloaded
                 } else {
                     mediaToUse = await enrichMediaWithParentPostMetadata(preloaded)
                 }
                 let newPosts = mediaToUse.map { createDummyPost(from: $0) }
                 posts = newPosts
                 
                 isLoading = false
                 preloadedPhotos = nil // Clear so we don't reuse
                 
                 // Increment currentPage so we don't re-fetch page 1 immediately
                 // Since we don't know exactly how many pages preloaded represents, we increment by one.
                 // This ensures the NEXT fetch is for Page 2.
                 currentPage += 1
                 
                 // Logic to find target post
                 if let initialMediaID, targetPostID == nil {
                     if let targetPost = posts.first(where: { post in
                         post.mediaRef?.contains(where: { $0.id == initialMediaID }) ?? false
                     }) {
                         targetPostID = targetPost.id ?? targetPost.mediaRef?.first?.id
                         shouldAutoScroll = targetPostID != nil
                         print("🔍 [PhotoDetail] Match found for \(initialMediaID) -> \(targetPostID ?? "nil")")
                     }
                 }
                 return
            }
            
            do {
                print("🔍 [PhotoDetail] Fetching posts for user: \(userProfileID), page: \(currentPage)")
                let result = try await dataManager.getProfilePostImages(id: userProfileID, pageNo: currentPage)
                
                var shouldFetchNextPage = false
                
                isLoading = false
                
                if result.status && (200...204).contains(result.statusCode) {
                    if let newImages = result.data {
                        print("🔍 [PhotoDetail] Fetched \(newImages.count) images.")
                        
                        // Map MediaRef to PostData
                        let enrichedImages = await enrichMediaWithParentPostMetadata(newImages)
                        let newPosts = enrichedImages.map { createDummyPost(from: $0) }
                        
                        print("📸 [PhotoDetail] Loaded page \(currentPage): \(newPosts.count) posts mapped from images")
                        
                        // Deduplicate before appending
                        let existingIDs = Set(posts.compactMap { $0.id })
                        let uniqueNewPosts = newPosts.filter { post in
                            guard let id = post.id else { return true }
                            return !existingIDs.contains(id)
                        }
                        
                        posts += uniqueNewPosts
                        currentPage = (result.pageNo ?? currentPage) + 1
                        hasMorePages = currentPage <= (result.totalPages ?? 1)
                        print("🔍 [PhotoDetail] Next Page: \(currentPage), Total Pages: \(result.totalPages ?? 0), Has More: \(hasMorePages)")
                        
                        if let initialMediaID, targetPostID == nil {
                            if let targetPost = posts.first(where: { post in
                                post.mediaRef?.contains(where: { $0.id == initialMediaID }) ?? false
                            }) {
                                targetPostID = targetPost.id ?? targetPost.mediaRef?.first?.id
                                shouldAutoScroll = targetPostID != nil
                                print("🔍 [PhotoDetail] Found target post for media \(initialMediaID): \(targetPostID ?? "nil")")
                            } else if hasMorePages {
                                print("🔍 [PhotoDetail] Target media \(initialMediaID) not found in this batch. Fetching next page...")
                                shouldFetchNextPage = true
                            }
                        }
                    } else {
                        print("🔍 [PhotoDetail] result.data is nil")
                    }
                } else {
                    print("❌ [PhotoDetail] Failed to load posts: \(result.message). Status: \(result.status), Code: \(result.statusCode)")
                }
                
                if shouldFetchNextPage {
                    loadPosts()
                }
                
            } catch {
                isLoading = false
                print("❌ [PhotoDetail] Error loading posts: \(error)")
            }
        }
    }

    @MainActor
    private func enrichMediaWithParentPostMetadata(_ media: [MediaRef]) async -> [MediaRef] {
        await buildPostLookupIfNeeded()
        guard !postLookupByMediaID.isEmpty else { return media }

        var enriched = media
        for index in enriched.indices {
            guard let mediaID = enriched[index].id else { continue }
            guard let post = postLookupByMediaID[mediaID] else { continue }
            enriched[index].postID = post.id
            enriched[index].likes = post.likes
            enriched[index].comments = post.comments
            enriched[index].likedByMe = post.likedByMe
            enriched[index].savedByMe = post.savedByMe
            enriched[index].views = post.views
            enriched[index].createdAt = post.createdAt
        }
        return enriched
    }

    /// Loads a small set of profile posts and builds a mapping from `mediaID -> PostData`,
    /// so we can show correct timestamps for items coming from the images endpoint.
    @MainActor
    private func buildPostLookupIfNeeded() async {
        if didBuildPostLookup || isBuildingPostLookup { return }
        isBuildingPostLookup = true
        defer {
            isBuildingPostLookup = false
            didBuildPostLookup = true
        }

        var allPosts: [PostData] = []
        var maxPage = 1
        var totalPages = 1

        // Load a few pages; enough to cover most profiles and keeps this lightweight.
        for page in 1...3 {
            do {
                let postsResult = try await dataManager.getProfilePosts(id: userProfileID, pageNo: page)
                if postsResult.status && (200...204).contains(postsResult.statusCode) {
                    if let postsData = postsResult.data, !postsData.isEmpty {
                        allPosts += postsData
                        maxPage = postsResult.pageNo ?? page
                        totalPages = postsResult.totalPages ?? 1
                    }
                }
            } catch {
                break
            }

            if maxPage >= totalPages { break }
        }

        // Deduplicate posts by ID
        var uniquePosts: [PostData] = []
        var seenIDs: Set<String> = []
        for post in allPosts {
            if let postID = post.id, !seenIDs.contains(postID) {
                seenIDs.insert(postID)
                uniquePosts.append(post)
            }
        }

        // Build mediaID -> post lookup
        var lookup: [String: PostData] = [:]
        for post in uniquePosts {
            for media in post.mediaRef ?? [] {
                if let mediaID = media.id {
                    lookup[mediaID] = post
                }
            }
        }

        postLookupByMediaID = lookup
        print("🧩 [PhotoDetail] Built post lookup: \(postLookupByMediaID.count) mediaIDs mapped")
    }

    private func createDummyPost(from media: MediaRef) -> PostData {
        var name = profileData?.name
        var profilePic = profileData?.profilePic
        var businessRef: Ref? = nil
        
        if profileData?.accountType == "business", let bizProfile = profileData?.businessProfileRef {
            name = bizProfile.name ?? profileData?.name
            profilePic = bizProfile.profilePic ?? profileData?.profilePic
            
            // Map BusinessProfileRef to Ref as expected by PostedBy
            // Note: Ref struct has many optional fields, we map what we have
            businessRef = Ref(
                id: bizProfile.id,
                icon: nil, // BusinessProfileRef doesn't have icon usually
                name: bizProfile.name,
                order: nil,
                profilePic: bizProfile.profilePic,
                businessTypeRef: bizProfile.businessTypeRef.map { ref in
                    BusinessTypeRef(id: ref.id, icon: ref.icon, name: ref.name)
                },
                businessSubtypeRef: bizProfile.businessSubtypeRef,
                rating: bizProfile.rating,
                address: bizProfile.address.map { addr in
                    Address(
                        street: addr.street,
                        city: addr.city,
                        state: addr.state,
                        zipCode: addr.zipCode,
                        country: addr.country,
                        lat: addr.lat ?? 0.0,
                        lng: addr.lng ?? 0.0
                    )
                }
            )
        }
        
        let postedBy = PostedBy(
            id: profileData?.id,
            accountType: profileData?.accountType,
            businessProfileID: profileData?.businessProfileID,
            name: name,
            username: profileData?.username,
            businessProfileRef: businessRef,
            profilePic: profilePic
        )
        
        return PostData(
            id: media.postID ?? media.id, // Prefer Enriched PostID, fallback to MediaID
            data: nil,
            isPublished: true,
            feelings: nil,
            googleReviewedBusiness: nil,
            publicUserID: nil,
            reviews: nil,
            businessProfileID: profileData?.businessProfileID,
            postType: "image",
            userID: profileData?.id,
            content: "", // Caption not available in MediaRef
            location: nil,
            createdAt: media.createdAt,
            mediaRef: [media],
            taggedRef: nil,
            postedBy: postedBy,
            likes: media.likes ?? 0,
            comments: media.comments ?? 0,
            likedByMe: media.likedByMe ?? false,
            savedByMe: media.savedByMe ?? false,
            reviewedBusinessProfileID: nil,
            placeID: nil,
            rating: nil,
            reviewedBusinessProfileRef: nil,
            name: nil,
            startTime: nil,
            startDate: nil,
            venue: nil,
            type: nil,
            refreshPost: nil,
            endDate: nil,
            endTime: nil,
            streamingLink: nil,
            shared: nil,
            views: media.views,
            imJoining: nil,
            placeName: nil,
            commentsCount: 0,
            interestedPeople: nil,
            eventJoinsRef: nil,
            collaboratorRef: nil
        )
    }
    
    // MARK: - Actions
    func likePost(postID: String, isLiked: Bool) {
        Task {
            do {
                let _ = try await postDataManager.likeAPost(postID: postID)
                await MainActor.run {
                    // Update post data optimistically
                    // Update ALL occurrences of this post (since multiple photos might share the same postID)
                    for index in posts.indices {
                        if posts[index].id == postID {
                            var updatedPost = posts[index]
                            updatedPost.likedByMe = !isLiked
                            if let currentLikes = updatedPost.likes {
                                updatedPost.likes = isLiked ? max(0, currentLikes - 1) : currentLikes + 1
                            } else {
                                updatedPost.likes = isLiked ? 0 : 1
                            }
                            posts[index] = updatedPost
                            onPostUpdated?(updatedPost)
                        }
                    }
                }
            } catch {
                print("❌ [PhotoDetail] Error liking post: \(error)")
            }
        }
    }
    
    func bookmarkPost(postID: String, isSaved: Bool) {
        Task {
            do {
                let _ = try await postDataManager.saveAPost(postID: postID)
                await MainActor.run {
                    // Update post data optimistically
                    // Update ALL occurrences of this post
                    for index in posts.indices {
                        if posts[index].id == postID {
                            var updatedPost = posts[index]
                            updatedPost.savedByMe = !isSaved
                            posts[index] = updatedPost
                            onPostUpdated?(updatedPost)
                        }
                    }
                }
            } catch {
                print("❌ [PhotoDetail] Error bookmarking post: \(error)")
            }
        }
    }
    
    @MainActor
    func showCommentSection(postID: String) {
        commentSectionPostID = postID
        showCommentSection = true
    }
    
    @MainActor
    func handleEllipsis(postID: String) {
        reportID = postID
        selectedPostID = postID
        reportType = "post"
        showPostOptionView = true
    }
    
    @MainActor
    func showShareView(postID: String) {
        sharePostData = posts.first(where: { $0.id == postID })
        let baseURLString = "https://thehotelmedia.com/share/posts"
        
        if !postID.isEmpty && !ownUserID.isEmpty {
            if let encryptedID = EncryptionHelper.encrypt(postID),
               let encryptedUserID = EncryptionHelper.encrypt(ownUserID) {
                shareURL = URL(string: "\(baseURLString)?postID=\(encryptedID)&userID=\(encryptedUserID)")!
                isSharePresented = true
            }
        }
    }

    func showEditPostScreen() {
        guard let postData = posts.first(where: { $0.id == selectedPostID }) else {
            return
        }
        
        // Check if I am the owner of the post
        if let authorID = postData.postedBy?.id, authorID != ownUserID, let router {
             ErrorModalManager.showErrorModal(router: router, errorText: "Cant update post as it is a collaborative project and you are not the owner")
             return
        }
        
        router?.showScreen(.push) { router in
            EditPostScreen(viewModel: EditPostViewModel(router: router, postData: postData, onPostUpdated: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    // Reload posts to reflect changes
                    self.posts = []
                    self.currentPage = 1
                    self.hasMorePages = true
                    self.loadPosts()
                }
            }))
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    func showDeletePostModal() {
        guard let router else { return }
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "do_you_really_want_to_delete_this_post".localized(LocalizationManager.shared.language),
            rightButtonTitle: "no".localized(LocalizationManager.shared.language),
            leftButtonTitle: "yes".localized(LocalizationManager.shared.language)) {
                self.deletePost(id: self.selectedPostID) {
                    if let index = self.posts.firstIndex(where: {$0.id == self.selectedPostID}) {
                        self.posts.remove(at: index)
                        self.onPostDeleted?(self.selectedPostID)
                    }
                }
                
            } onRightButtonPressed: {
                
            } onDismiss: {
                
            }
    }
    
    func deletePost(id: String, completionHandler: (() -> Void)?) {
        guard let router else { return }
        isLoading = true
        Task {
            do {
                let result = try await postDataManager.deletePost(postID: id)
                
                await MainActor.run {
                    isLoading = false
                    
                    if result.status && (200...204).contains(result.statusCode) {
                        completionHandler?()
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    print(error)
                }
            }
        }
    }
}

