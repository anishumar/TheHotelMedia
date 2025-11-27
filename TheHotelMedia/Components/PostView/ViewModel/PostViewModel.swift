//
//  PostViewModel.swift
//  HotelMedia
//
//  Created by MAC on 28/08/24.
//

import SwiftUI
import Combine
import SwiftfulRouting

class PostViewModel: ObservableObject {
    
    var cancellables = Set<AnyCancellable>()
    let dataManager = PostDataManager()
    var hasSubscribed: Bool = false
    var router: AnyRouter? = nil
    @Published var postArray: [PostData] = []
    @Published var showSheet: Bool = false
    @Published var commentSectionPostID: String = ""
    @Published var totalComments: Int = 0
    @Published var shareURL: URL = URL(string: "https://thehotelmedia.com/post")!
    @Published var visiblePostIndex: Int? = nil {
        didSet {
            if let oldValue {
                prevoiusPostIndex = oldValue
            }
        }
    }
    @Published var prevoiusPostIndex: Int? = nil
//    @Published var isPausedArray: [Bool] = [true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true]
    @Published var isPausedArray: [Bool] = []
//    @Published var yOffsetArray: [CGFloat?] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var yOffsetArray: [CGFloat?] = []
    @Published var yOffset: CGFloat = 0
    @Published var yOffsetContinuous: CGFloat = 0
    @Published var resetArray: [Bool] = []
    @Published var showPostArray: [Bool] = []
    @Published var showPostArrayCount: Int = 0
    @Published var isSharePresented: Bool = false
    @Published var sharePostData: PostData? = nil
    @Published var showOptionView: Bool = false
    @Published var visibleOptionPostIndex: Int = 0
    @Published var postSizeArray: [CGSize] = []
    @Published var postCount: Int = 0
    
    @Published var deletedPostID: String = ""
    
    // Properties which are used when we tap on a post media.
    @Published var currentPostIndex: Int? = nil
    @Published var currentPostId: String = ""
    @Published var currentMediaIndex: Int? = nil
    @Published var currentMedia: MediaType = .image(urlString: "")
    @Published var currentMediaId: String = ""
    @Published var currentLikedByMe: Bool = false
    @Published var showMediaPreview: Bool = false
    @Published var currentSavedByMe: Bool = false
    @Published var currentLikesCount: Int = 0
    @Published var currentSharesCount: Int = 0
    @Published var currentCommentsCount: Int = 0
    @Published var showProfileScreen: Bool = false
    @Published var selectedProfileID: String = ""
    @Published var selectedSinglePostID: String = ""
    @Published var showSinglePostScreen: Bool = false
    @Published var selectedEventID: String = ""
    @Published var showEventDetailScreen: Bool = false
    @Published var showAllSuggestionScreen: Bool = false
    
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    
    init(router: AnyRouter? = nil) {
//        addSubscribers()
        self.router = router
    }
    
    
    func addSubscribers() {
        
        guard !hasSubscribed else { return }
        
        $visiblePostIndex
            .sink { [weak self] (current) in
                guard let self else { return }
                var array = isPausedArray
                guard let current, !array.isEmpty else { return }
                
                
                array.remove(at: current)
                array.insert(false, at: current)
                
                if prevoiusPostIndex != nil {
                    
                    if current > 0 {
                        array.remove(at: current - 1)
                        array.insert(true, at: current - 1)
                    }
                    
                    if current < array.count - 1 {
                        array.remove(at: current + 1)
                        array.insert(true, at: current + 1)
                    }
                    
                }
                
                isPausedArray = array
            }
            .store(in: &cancellables)
        
        $isPausedArray
            .sink { [weak self] array in
                guard let self else { return }
                var anotherArray: [Bool] = []
                for _ in 0..<array.count {
                    anotherArray.append(true)
                }
                resetArray = anotherArray
            }
            .store(in: &cancellables)
        
        hasSubscribed = true
    }
    
    func updateIsPausedArray(count: Int) {
        var array: [Bool] = []
        for _ in 0..<count {
            array.append(true)
        }
        isPausedArray.append(contentsOf: array)
    }
    
    
    func updatePosts(with newPosts: [PostData]) {
        
        postArray.append(contentsOf: newPosts)
    }
    
    
    func updateToShowPosts(posts: [PostData]) {
        
        var showPostArray: [Bool] = []
        
        if posts.count <= 10 {
            for _ in posts {
                showPostArray.append(true)
            }
        } else {
            for _ in posts {
                showPostArray.append(false)
            }
        }
        
        
        if let visiblePostIndex, showPostArray.count - 1 >= visiblePostIndex {
            showPostArray[visiblePostIndex] = true
            
            if visiblePostIndex != 0 {
                showPostArray[visiblePostIndex - 1] = true
            }
            
            if visiblePostIndex < postCount - 1 {
                showPostArray[visiblePostIndex + 1] = true
            }
        } else {
            if !showPostArray.isEmpty {
                showPostArray[0] = true
            }
            
            if showPostArray.count > 1 {
                showPostArray[1] = true
            }
        }
        
//        let count = posts.count
//        
//        if count <= 10 {
//            for _ in posts {
//                showPostArray.append(true)
//            }
//        } else {
//            showPostArray = self.showPostArray
//            
//            for _ in 0..<count - self.showPostArrayCount {
//                showPostArray.append(true)
//            }
//        }
//        
        
        self.showPostArray = showPostArray
        self.showPostArrayCount = showPostArray.count
    }
    
    
    func updateVisiblePosts(index: Int) {
        
        guard showPostArrayCount - 1 >= index else { return }
        
        showPostArray[index] = true
        
//        if index != 0 {
//            showPostArray[index - 1] = true
//        }
//        
//        if index < postCount - 1 {
//            showPostArray[index + 1] = true
//        }
        
        if let prevoiusPostIndex {
            
            if prevoiusPostIndex < index {
                
                if index < postCount - 2 {
                    showPostArray[index + 1] = true
                    showPostArray[index + 2] = true
                }
                
                if index > 2 {
                    showPostArray[index - 3] = false
                }
            } else {
                if index > 1 {
                    showPostArray[index - 1] = true
                    showPostArray[index - 2] = true
                }
                
                if postCount - 3 > index {
                    showPostArray[index + 3] = false
                }
            }
        }
        
        
//        guard let prevoiusPostIndex else { return }
//        
//        // Checking if index is divisible of 8
//        if index % 8 == 0 && index != 0 {
//            
//            if prevoiusPostIndex < index {
//                
//                if showPostArrayCount - 12 >= index {
//                    var array = showPostArray
//                    
//                    for i in 2..<12 {
//                        array[index + i] = true
//                    }
//                    
//                    showPostArray = array
//                    
//                } else {
//                    let counter = showPostArrayCount - index - 2
//                    
//                    var array = showPostArray
//                    
//                    for i in 0..<counter {
//                        array[index + i + 2] = true
//                    }
//                    
//                    showPostArray = array
//                }
//            } else if prevoiusPostIndex > index {
//                
//                if showPostArrayCount - 12 >= index {
//                    var array = showPostArray
//                    
//                    for i in 2..<12 {
//                        array[index + i] = false
//                    }
//                    
//                    showPostArray = array
//                    
//                } else {
//                    let counter = showPostArrayCount - index - 2
//                    
//                    var array = showPostArray
//                    
//                    for i in 0..<counter {
//                        array[index + i + 2] = false
//                    }
//                    
//                    showPostArray = array
//                }
//            }
//        } else if index % 11 == 0 && index != 0 {
//            
//            if prevoiusPostIndex < index {
//                
//                if index - 11 >= 0 {
//                    var array = showPostArray
//                    var counter = 2
//                    
//                    for i in 0..<9 {
//                        array[index - counter] = false
//                        counter += 1
//                    }
//                    
//                    showPostArray = array
//                }
//            } else if prevoiusPostIndex > index {
//                
//                if index - 11 >= 0 {
//                    var array = showPostArray
//                    var counter = 2
//                    
//                    for i in 0..<9 {
//                        array[index - counter] = true
//                        counter += 1
//                    }
//                    
//                    showPostArray = array
//                }
//            }
//        }
    }
    
    
    
    func resetPost(with newPosts: [PostData]) {
//        isPausedArray = []
        postArray = newPosts
    }
    
    
    func cancelSubscriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
        hasSubscribed = false
    }
    
    
    func showShareView(id: String, isEventPost: Bool = false, postData: PostData? = nil) {
        sharePostData = postData ?? postArray.first(where: { $0.id == id })
        var baseURLString = "\(Constants.baseShareUrl)/share/posts"
        
        if isEventPost {
            baseURLString = "\(Constants.baseShareUrl)/share/events"
        }
        
        if !id.isEmpty && !ownUserID.isEmpty {
            
            if let encryptedID = EncryptionHelper.encrypt(id),
               let encryptedUserID = EncryptionHelper.encrypt(ownUserID) {
                
                shareURL = URL(string: "\(baseURLString)?postID=\(encryptedID)&userID=\(encryptedUserID)")!
                isSharePresented = true
            }
        }
    }
    
    
    func cancelSubscribers() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    func showSharedProfile(sharedID: String, sharedByID: String) {
        if let router {
            router.showScreen(.push) { router in
                UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: sharedID, sharedByProfileID: sharedByID))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        }
        
    }
    
    
    func showAllSuggestionsList() {
        if let router {
            router.showScreen(.push) { router in
                SuggestionListScreen(viewModel: SuggestionScreenViewModel(router: router))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        }
    }
    
    
    func showSharePostView(postID: String, sharedByID: String) {
        if let router {
            router.showScreen(.push) { router in
                SinglePostView(viewModel: SinglePostViewModel(router: router, postID: postID, sharedByID: sharedByID), isPaused: .constant(false))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        }
        
    }
    
    
    func showShareEventView(postID: String, sharedByID: String) {
        if let router {
            router.showScreen(.push) { router in
                EventDetailView(viewModel: EventDetailViewModel(router: router, postID: postID, sharedByID: sharedByID))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        }
    }
    
    
    func showCreateReviewScreen(id: String? = nil, placeID: String? = nil) {
        if let router {
            router.showScreen(.push) { router in
                CreateReviewView(viewModel: CreateReviewViewModel(router: router, businessProfileID: id, placeID: placeID, onReviewCreated: { [weak self] in
                    guard let self else { return }
    //                refreshHomeData = true
                }))
                .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
                
            }
        }
    }
    
    
    func showSinglePostView(id: String) {
        if let router {
            router.showScreen(.push) { newRouter in
                SinglePostView(viewModel: SinglePostViewModel(router: newRouter, postID: id), isPaused: .constant(false))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        }
    }
    
    func showUserProfileScreen(id: String) {
        if let router {
            router.showScreen(.push) { router in
                UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: id))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        }
    }
}


// MARK: - Networking
extension PostViewModel {
    func likeAPost(id: String) {
        Task { 
            do {
                let _ = try await dataManager.likeAPost(postID: id)
            } catch {
                print(error)
            }
        }
    }
    
    
    func saveAPost(id: String) {
        Task {
            do {
                let _ = try await dataManager.saveAPost(postID: id)
            } catch {
                print(error)
            }
        }
    }
    
    func joinEvent(id: String) {
        Task {
            do {
                let _ = try await dataManager.joinEvent(postID: id)
            } catch {
                print(error)
            }
        }
    }
    
    
    func deletePost(id: String) {
        Task {
            do {
                let result = try await dataManager.deletePost(postID: id)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        deletedPostID = id
                    } else {
                        if let router {
                            ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        }
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func increasePostViews(array: [String], completion: (() -> Void)?) {
        Task {
            do {
                let result = try await dataManager.increasePostViews(array: array)
                
                await MainActor.run {
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        completion?()
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}
