//
//  PostViewModel2.swift
//  TheHotelMedia
//
//  Created by MAC on 29/01/25.
//

import SwiftUI
import SwiftfulRouting
import Combine
import AVKit


class PostViewModel2: ObservableObject {
    
    var cancellables = Set<AnyCancellable>()
    let dataManager = PostDataManager()
    var hasSubscribed: Bool = false
    var router: AnyRouter? = nil
    @Published var postArray: [PostData] = []
    @Published var showSheet: Bool = false
    @Published var commentSectionPostID: String = ""
    @Published var totalComments: Int = 0
    @Published var shareURL: URL = URL(string: "https://thehotelmedia.com/post")!
    var visiblePostIndex: Int? = nil {
        didSet {
            if let oldValue {
                prevoiusPostIndex = oldValue
            }
        }
    }
    var prevoiusPostIndex: Int? = nil
    @Published var isPausedArray: [Bool] = [true, true, true, true, true, true, true, true, true, true, true]
//    @Published var isPausedArray: [Bool] = []
    var yOffsetArray: [CGFloat?] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    @Published var postSizeArray: [CGSize] = [.zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero]
//    @Published var yOffsetArray: [CGFloat?] = []
    @Published var yOffset: CGFloat = 0
    @Published var yOffsetContinuous: CGFloat = 0
    @Published var resetArray: [Bool] = []
    @Published var showPostArray: [Bool] = []
    @Published var showPostArrayCount: Int = 0
    @Published var isSharePresented: Bool = false
    @Published var showShareAsStory: Bool = false
    var currentSharedPostID: String = ""
    @Published var showOptionView: Bool = false
    @Published var visibleOptionPostIndex: Int = 0
//    @Published var postSizeArray: [CGSize] = []
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
    @Published var showTagList: Bool = false
    @Published var dragOffset: CGFloat = .zero
    @Published var currentTaggedRef: [TaggedRef] = []
    
    var visiblePostIndex2: CurrentValueSubject<Int?, Never> = .init(nil)
    var isScrolling: CurrentValueSubject<Bool, Never> = .init(false)
    var currentMediaFrame: CurrentValueSubject<CGRect?, Never> = .init(.zero)
    var currentPlayerItemID: CurrentValueSubject<String, Never> = .init("")
    var visibleVideoUrl: CurrentValueSubject<URL?, Never> = .init(nil)
    var currentPlayer: CurrentValueSubject<AVPlayer?, Never> = .init(nil)
    var notificationObserver: CurrentValueSubject<Any?, Never> = .init(nil)
    var videoHidden: CurrentValueSubject<Bool, Never> = .init(false)
    var refreshVideoView: CurrentValueSubject<Bool, Never> = .init(false)
    var isMute: CurrentValueSubject<Bool, Never> = .init(false)
    
    var avPlayerItemDic: [String: AVPlayerItem] = [:]
    var avPlayerItemKeys: [String] = []
    var avPlayerDic: [String: AVPlayer] = [:]
    var savedFrameOnNavigate: CGRect? = .zero
    var savedMediaUrl: URL? = nil
    var currentMediaIsVideo: Bool = false
    
    @Published var viewModels: [GenericPostViewModel] = []
    
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    
    init(router: AnyRouter? = nil) {
        addSubscribers()
        self.router = router
    }
    
    
    func addSubscribers() {
        
        guard !hasSubscribed else { return }
        
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
    
    
    func ensureArrayCapacity(for count: Int) {
        let safeCount = max(count, 0)
        
        if safeCount == 0 {
            isPausedArray = []
            yOffsetArray = []
            postSizeArray = []
            return
        }
        
        if isPausedArray.count < safeCount {
            let additional = safeCount - isPausedArray.count
            isPausedArray.append(contentsOf: Array(repeating: true, count: additional))
        } else if isPausedArray.count > safeCount {
            isPausedArray = Array(isPausedArray.prefix(safeCount))
        }
        
        if yOffsetArray.count < safeCount {
            let additional = safeCount - yOffsetArray.count
            yOffsetArray.append(contentsOf: Array(repeating: 0 as CGFloat?, count: additional))
        } else if yOffsetArray.count > safeCount {
            yOffsetArray = Array(yOffsetArray.prefix(safeCount))
        }
        
        if postSizeArray.count < safeCount {
            let additional = safeCount - postSizeArray.count
            postSizeArray.append(contentsOf: Array(repeating: .zero, count: additional))
        } else if postSizeArray.count > safeCount {
            postSizeArray = Array(postSizeArray.prefix(safeCount))
        }
    }
    
    
    func addPlayerItem(forKey key: String, item: AVPlayerItem) {
        if avPlayerItemDic.count >= 10 {
            // Remove the oldest entry (first key in the array)
            if let oldestKey = avPlayerItemKeys.first {
                avPlayerItemDic.removeValue(forKey: oldestKey)
                avPlayerItemKeys.removeFirst()
            }
        }
        
        // Add new item
        avPlayerItemDic[key] = item
        avPlayerItemKeys.append(key)
    }
    
    
    func configureViewModelArray(add: Bool = false, count: Int = 11) {
        var array: [GenericPostViewModel] = []
        for _ in 0..<count {
            array.append(GenericPostViewModel())
        }
        
        if add {
            viewModels.append(contentsOf: array)
        } else {
            viewModels = array
        }
    }
    
    
    func pauseVideoOnNavigate() {
        visiblePostIndex2.send(nil)
    }
    
    
    func playVideoOnNavigateDismiss() {
        visiblePostIndex2.send(visiblePostIndex)
    }
    
    
    func resetPost(with newPosts: [PostData]) {
        postArray = newPosts
    }
    
    
    func cancelSubscriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
        hasSubscribed = false
    }
    
    
    func showShareView(id: String, isEventPost: Bool = false) {
        
        var baseURLString = "\(Constants.baseShareUrl)/share/posts"
        
        if isEventPost {
            baseURLString = "\(Constants.baseShareUrl)/share/events"
        }
        
        if !id.isEmpty && !ownUserID.isEmpty {
            
            if let encryptedID = EncryptionHelper.encrypt(id),
               let encryptedUserID = EncryptionHelper.encrypt(ownUserID) {
                
                currentSharedPostID = id
                shareURL = URL(string: "\(baseURLString)?postID=\(encryptedID)&userID=\(encryptedUserID)")!
                isSharePresented.toggle()
            }
        }
    }
    
    func shareAsStory() {
        shareAsStory(postID: currentSharedPostID)
    }
    
    private func shareAsStory(postID: String) {
        guard let post = postArray.first(where: { $0.id == postID }),
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
    
    
    func cancelSubscribers() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    func showSharedProfile(sharedID: String, sharedByID: String) {
        if let router {
            router.showScreen(.push) { router in
                UserProfileView(createPostOn: .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: sharedID, sharedByProfileID: sharedByID))
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
    
    
    func updateVisiblePosts(index: Int) {
        
        showPostArray[index] = true
        
        if index != 0 {
            showPostArray[index - 1] = true
        }

        if index < postCount - 1 {
            showPostArray[index + 1] = true
        }
    }
    
    
    func startVideo() {
        if let visiblePostIndex, visiblePostIndex < isPausedArray.count {
            isPausedArray[visiblePostIndex] = false
        }
    }
    
    
    func stopVideo() {
        if let visiblePostIndex, visiblePostIndex < isPausedArray.count {
            isPausedArray[visiblePostIndex] = true
//            
//            if visiblePostIndex > 0 {
//                isPausedArray[visiblePostIndex - 1] = true
//            }
//            
//            if visiblePostIndex < isPausedArray.count - 1 {
//                isPausedArray[visiblePostIndex + 1] = true
//            }
        }
    }
}


// MARK: - Networking
extension PostViewModel2 {
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

