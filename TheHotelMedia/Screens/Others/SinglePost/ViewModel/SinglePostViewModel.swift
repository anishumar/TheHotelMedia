//
//  SinglePostViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 05/12/24.
//

import SwiftUI
import SwiftfulRouting
import AVKit
import Combine


class SinglePostViewModel: ObservableObject {
    
    let router: AnyRouter
    let sharedPostID: String
    let sharedByID: String
    var cancellables = Set<AnyCancellable>()
    let dataManager = SinglePostDataManager()
    let postDataManager = PostDataManager()
    @Published var data: PostData? = nil
    var postID: String? = nil
    @Published var postType: String = ""
    @Published var isPausedArray: [Bool] = []
    @Published var isPausePost: Bool = true
    @Published var previousPage: Int? = nil
    @Published var isLoading: Bool = false
    @Published var accountType: String? = nil
    @Published var profilePic: String? = nil
    @Published var firstImage: String? = nil
    @Published var location: String = ""
    @Published var name: String? = nil
    @Published var likesCount: Int = 0
    @Published var commentsCount: Int = 0
    @Published var shareCount: Int = 0
    @Published var likes: String = ""
    @Published var likedByMe: Bool = false
    @Published var savedByMe: Bool = false
    @Published var avplayers: [AVPlayer?] = []
    @Published var heartScale: CGFloat = 1.0
    @Published var comments: String = ""
    @Published var feeling: String = ""
    @Published var content: String = ""
    @Published var taggedRef: [TaggedRef] = []
    @Published var showTagList: Bool = false
    @Published var shares: String = "0"
    @Published var selectedMedia: MediaType = .image(urlString: "")
    @Published var showPreview: Bool = false
    @Published var showMediaPreview: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var showCommentSection: Bool = false
    @Published var commentSectionPostID: String = ""
    @Published var isSharePresented: Bool = false
    @Published var showPostOptionView: Bool = false
    @Published var coverImage: String = ""
    @Published var businessAddress: String? = ""
    @Published var shareURL: URL = URL(string: "https://thehotelmedia.com/post")!
    @Published var fullDescription: AttributedString = AttributedString()
    @Published var currentPage: Int = 0 {
        didSet {
            previousPage = oldValue
        }
    }
    @Published var mediaContent: [MediaType] = []
    
    @Published var reportType: String = "post"
    @Published var reportID: String = ""
    @Published var showReportScreen: Bool = false
    
    @Published var replyingComment: Comment? = nil
    @Published var replyingProfilePic: String? = nil
    @Published var replyingName: String? = nil
    @Published var commentFieldText: String = ""
    @Published var newComment: String = ""
    
    @AppStorage("isMute") var isMute: Bool = false
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    let localizationManager = LocalizationManager.shared
    
    init(router: AnyRouter, postID: String, sharedByID: String = "") {
        self.router = router
        self.sharedPostID = postID
        self.sharedByID = sharedByID
    }
    
    
    func addSubscribers() {
        $currentPage
            .combineLatest($isPausePost)
            .sink { [weak self] (currentPage, isPausePost) in
                guard let self else { return }
                var array: [Bool] = []
                
                guard !isPausedArray.isEmpty else { return }
                
                for _ in 0..<isPausedArray.count{
                    array.append(true)
                }
                if !isPausePost {
                    array.remove(at: currentPage)
                    array.insert(false, at: currentPage)
                }
                
                self.isPausedArray = array
                avplayers[currentPage]?.play()
                
            }
            .store(in: &cancellables)
        
        $data
            .sink { [weak self] data in
                guard let self else { return }
                guard let data else { return }
                accountType = data.postedBy?.accountType
                location = data.location?.placeName ?? ""
                
                if let id = data.id {
                    postID = id
                }
                
                if let address = data.reviewedBusinessProfileRef?.address {
                    businessAddress = "\(address.street?.capitalized ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                }
                
                if let type = data.postedBy?.accountType {
                    if type == "individual" {
                        profilePic = data.postedBy?.profilePic?.small
                        name = data.postedBy?.name
                    } else {
                        profilePic = data.postedBy?.businessProfileRef?.profilePic?.small
                        name = data.postedBy?.businessProfileRef?.name
                    }
                }
                
                if let mediaRef = data.mediaRef, !mediaRef.isEmpty {
                    var array: [MediaType] = []
                    var playerArray: [AVPlayer?] = []
                    
                    for (index, media) in mediaRef.enumerated() {
                        if let thumbnailURL = media.thumbnailURL {
                            firstImage = thumbnailURL
                            break
                        }
                    }
                    
                    
                    for media in mediaRef {
                        if let url = URL(string: media.sourceURL ?? ""), media.mediaType == "video" {
                            let playerItem = AVPlayerItem(url: url)
                            let player = AVPlayer(playerItem: playerItem)
                            player.isMuted = isMute
                            player.automaticallyWaitsToMinimizeStalling = false
                            playerArray.append(player)
                        } else {
                            playerArray.append(nil)
                        }
//                        playerArray.append(nil)
                    }
                    
                    avplayers = playerArray
                    
                    
                    for media in mediaRef {
                        if media.mediaType == "image" {
                            array.append(.image(urlString: media.sourceURL ?? ""))
                        } else {
                            array.append(.video(urlString: media.sourceURL ?? ""))
                        }
                    }
                    
                    mediaContent = array
                }
                
                likesCount = data.likes ?? 0
                commentsCount = data.comments ?? 0
                commentSectionPostID = data.id ?? ""
                
                likedByMe = data.likedByMe ?? false
                savedByMe = data.savedByMe ?? false
                
                if let shared = data.shared {
                    shares = "\(shared)"
                }
                
                if let feelings = data.feelings {
                    feeling = feelings
                }
                
                if let taggedRef = data.taggedRef {
                    self.taggedRef = taggedRef
                }
                
                if let postType = data.postType {
                    self.postType = postType
                }
                
                coverImage = data.reviewedBusinessProfileRef?.coverImage ?? ""
                
                if let content = data.content {
                    self.content = content
                    let fullDescription = getAttributedDescription(content: content, data: data)
                    self.fullDescription = fullDescription
                }
            }
            .store(in: &cancellables)
        
//        $content
//            .sink { [weak self] content in
//                guard let self else { return }
//                
//                
//            }
//            .store(in: &cancellables)
        
        $mediaContent
            .sink { [weak self] array in
                guard let self else { return }
                
                var pauseArray: [Bool] = []
                for _ in 0..<array.count {
                    pauseArray.append(true)
                }
                isPausedArray = pauseArray
            }
            .store(in: &cancellables)
        
        $likedByMe
            .sink { [weak self] isLiked in
                guard let self else { return }
                heartScale = isLiked ? 1.1 : 1.0
            }
            .store(in: &cancellables)
        
        $likesCount
            .sink { [weak self] count in
                guard let self else { return }
                self.likes = formatNumber(Double(count))
            }
            .store(in: &cancellables)
        
        $commentsCount
            .sink { [weak self] count in
                guard let self else { return }
                self.comments = formatNumber(Double(count))
            }
            .store(in: &cancellables)
        
        $isPausedArray
            .sink { [weak self] bools in
                guard let self else { return }
                for (index, bool) in bools.enumerated() {
                    if bool {
                        avplayers[index]?.pause()
                    } else {
                        avplayers[index]?.play()
                    }
                }
            }
            .store(in: &cancellables)
        
        $showMediaPreview
            .sink { [weak self] showingPreview in
                guard let self else { return }
                
                guard !isPausedArray.isEmpty else { return }
                
                if showingPreview {
                    isPausedArray[currentPage] = true
                } else {
                    isPausedArray[currentPage] = false
                }
            }
            .store(in: &cancellables)
        
        // For replying comment
        $replyingComment
            .sink { [weak self] comment in
                guard let self else { return }
                if let comment {
                    if let commentedBy = comment.commentedBy, let accountType = commentedBy.accountType {
                        if accountType == "individual" {
                            if let name = commentedBy.name, let profilePic = commentedBy.profilePic {
                                replyingProfilePic = profilePic.small ?? ""
                                replyingName = name
                            }
                        } else {
                            if let businessProfileRef = commentedBy.businessProfileRef,
                               let name = businessProfileRef.name,
                               let profilePic = businessProfileRef.profilePic {
                                replyingName = name
                                replyingProfilePic = profilePic.small ?? ""
                            }
                        }
                    }
                } else {
                    replyingName = nil
                    replyingProfilePic = nil
                }
            }
            .store(in: &cancellables)
    }
    
    
    func getAttributedDescription(content: String, data: PostData) -> AttributedString {
        
        // Determine if content needs truncation
        let length = mediaContent.isEmpty ? 400 : 160
        let isContentLong = content.count > length
        let truncatedContent = isContentLong ? String(content.prefix(length)) : content
        var attributedString = AttributedString(data.isExpandedDescription ? content : truncatedContent)
        
        // Regular expression for URLs
        let urlRegex = try! NSRegularExpression(pattern: "(https?://[a-zA-Z0-9._%+-]+\\.[a-zA-Z]{2,}(?:/[a-zA-Z0-9._%+-]*)*(?:\\?[a-zA-Z0-9&=_%+-]*)?)", options: [])
        let matches = urlRegex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
        
        // Add tappable links for URLs
        for match in matches {
            guard let rangeInString = Range(match.range, in: content),
                  let rangeInAttributedString = Range(match.range, in: attributedString) else {
                continue
            }
            let urlText = String(content[rangeInString])
//            let link = URL(string: "link://\(data.id ?? "")?url=\(urlText)")!
            let link = URL(string: "link://\("tabbar")?url=\(urlText)")!
            
            attributedString[rangeInAttributedString].link = link
            attributedString[rangeInAttributedString].foregroundColor = .hmIndigo
            attributedString[rangeInAttributedString].underlineStyle = .single
        }
        
        // Append feelings
        if !feeling.isEmpty {
            appendTappableText(&attributedString, text: " - \(feeling)", link: "feeling://\(data.id ?? "")")
        }
        
        // Append tags
        if !taggedRef.isEmpty {
            let tagText = taggedRef.count == 1
            ? "\(taggedRef[0].name ?? "")"
            : "\(taggedRef[0].name ?? "") and \(taggedRef.count - 1) others"
            appendTappableText(&attributedString, text: " - with \(tagText)", link: "tags://\(data.id ?? "")")
        }
        
        // Append location
        if let location = data.location {
            appendTappableText(&attributedString, text: " - at \(location.placeName ?? "")", link: "loc://\(data.id ?? "")?lat=\(location.lat ?? 0.0)&lng=\(location.lng ?? 0.0)")
        }
        
        // Append Read More/Read Less
        if isContentLong {
            let readMoreOrLessText = data.isExpandedDescription ? "...Read less" : "...Read more"
            appendTappableText(&attributedString, text: readMoreOrLessText, link: "readmore://\(data.id ?? "")")
        }
        
        return attributedString
    }
    
    
    private func appendTappableText(_ attributedString: inout AttributedString, text: String, link: String) {
        var tappableText = AttributedString(text)
        tappableText.link = URL(string: link)
        tappableText.foregroundColor = .hmIndigo
        tappableText.font = .custom(Constants.comicFont, size: 13.2)
        attributedString.append(tappableText)
    }
    
    
    func formatNumber(_ number: Double) -> String {
        if number >= 1_000_000_000 {
            
            let remainder = number.truncatingRemainder(dividingBy: 1000_000_000)
            
            if remainder == 0 {
                return String(format: "%.0fB", number / 1_000_000_000) // Billion
            } else {
                return String(format: "%.1fB", number / 1_000_000_000) // Billion
            }
            
        } else if number >= 1_000_000 {
            
            let remainder = number.truncatingRemainder(dividingBy: 1_000_000)
            
            if remainder == 0 {
                return String(format: "%.0fM", number / 1_000_000) // Million
            } else {
                return String(format: "%.1fM", number / 1_000_000) // Million
            }
            
        } else if number >= 1_000 {
            let remainder = number.truncatingRemainder(dividingBy: 1000)
            
            if remainder == 0 {
                return String(format: "%.0fK", number / 1_000) // Thousand
            } else {
                return String(format: "%.1fK", number / 1_000) // Thousand
            }
        } else {
            return String(format: "%.0f", number) // Less than 1,000
        }
    }
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showProfileScreen(userID: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: userID))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showShareView(id: String) {
        
        let baseURLString = "https://thehotelmedia.com/share/posts"
        
        if !id.isEmpty && !ownUserID.isEmpty {
            
            if let encryptedID = EncryptionHelper.encrypt(id),
               let encryptedUserID = EncryptionHelper.encrypt(ownUserID) {
                
                shareURL = URL(string: "\(baseURLString)?postID=\(encryptedID)&userID=\(encryptedUserID)")!
                isSharePresented.toggle()
            }
        }
    }
    
    func showSharedProfile(sharedID: String, sharedByID: String) {
        router.showScreen(.push) { router in
            UserProfileView(createPostOn:  .constant(false), viewModel: UserProfileViewModel(router: router, publicProfileID: sharedID, sharedByProfileID: sharedByID))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showSharePostView(postID: String, sharedByID: String) {
        router.showScreen(.push) { router in
            SinglePostView(viewModel: SinglePostViewModel(router: router, postID: postID, sharedByID: sharedByID), isPaused: .constant(false))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    func showShareEventView(postID: String, sharedByID: String) {
        router.showScreen(.push) { router in
            EventDetailView(viewModel: EventDetailViewModel(router: router, postID: postID, sharedByID: sharedByID))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    func showCreateReviewScreen(id: String? = nil, placeID: String? = nil) {
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


// MARK: - Networking
extension SinglePostViewModel {
    func postShared(postID: String, sharedByID: String) {
        
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.postShared(postID: postID, sharedByID: sharedByID)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            self.data = data
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                    showLoadingIndicator = false
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "an_error_occured_while_loading_the_post".localized(localizationManager.language))
                    print(error)
                }
            }
        }
    }
    
    
    func getPost(postID: String) {
        
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.getSinglePost(id: postID)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            self.data = data
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                    showLoadingIndicator = false
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "an_error_occured_while_loading_the_post".localized(localizationManager.language))
                    print(error)
                }
            }
        }
    }
    
    
    func likePost(id: String) {
        Task {
            do {
                let _ = try await postDataManager.likeAPost(postID: id)
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func savePost(id: String) {
        Task {
            do {
                let _ = try await postDataManager.saveAPost(postID: id)
                
            } catch {
                print(error)
            }
        }
    }
}
