//
//  PostCardViewModel.swift
//  HotelMedia
//
//  Created by MAC on 27/08/24.
//

import SwiftUI
import Combine
import AVKit
import SDWebImage


final class PostCardViewModel: ObservableObject {
    
    var cancellables = Set<AnyCancellable>()
    @Published var data: PostData
    @Published var isPausedArray: [Bool] = []
    @Published var isPausePost: Bool = true
    @Published var previousPage: Int = 0
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
    @Published var fullDescription: AttributedString = AttributedString()
    @Published var showMediaPreview: Bool = false
    @Published var isPlayingVideo: Bool = false
    @Published var firstImageSize: CGSize = .zero
    @Published var currentPage: Int = 0 {
        didSet {
            previousPage = oldValue
        }
    }
    @Published var mediaContent: [MediaType] = []
    
    let collaborationDataManager = NotificationDataManager()
    
    @AppStorage("isMute") var isMute: Bool = false
    
    
    init(data: PostData) {
        self.data = data
        addSubscribers()
        fetchCollaboratorsIfNeeded()
        print("PostCardViewModel init")
    }
    
    deinit {
        print("PostCardViewModel deinit")
    }
    
    func fetchCollaboratorsIfNeeded() {
        guard let postID = data.id, data.collaboratorRef == nil || data.collaboratorRef?.isEmpty == true else {
            return
        }
        
        Task {
            do {
                let result = try await collaborationDataManager.getCollaboratorsForPost(postID: postID)
                
                await MainActor.run {
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let collaborators = result.data, !collaborators.isEmpty {
                            let taggedRefs = collaborators.compactMap { collaborator -> TaggedRef? in
                                guard let id = collaborator.id else { return nil }
                                return TaggedRef(
                                    id: id,
                                    profilePic: collaborator.profilePic,
                                    accountType: nil,
                                    name: collaborator.name,
                                    role: nil,
                                    username: nil,
                                    businessProfileRef: nil
                                )
                            }
                            
                            var updatedData = data
                            updatedData.collaboratorRef = taggedRefs
                            data = updatedData
                        }
                    }
                }
            } catch {
                print("Failed to fetch collaborators: \(error)")
            }
        }
    }
    
    func addSubscribers() {
        $currentPage
            .combineLatest($isPausePost)
            .sink { [weak self] (currentPage, isPausePost) in
                guard let self else { return }
                var array: [Bool] = []
                
                guard !isPausedArray.isEmpty else { return }
                
                for _ in 0..<isPausedArray.count {
                    array.append(true)
                }
                if !isPausePost {
//                    array.remove(at: currentPage)
//                    array.insert(false, at: currentPage)
                    array[currentPage] = false
                }
                
                self.isPausedArray = array
            }
            .store(in: &cancellables)
        
        $data
            .sink { [weak self] data in
                guard let self else { return }
                accountType = data.postedBy?.accountType
//                location = data.location?.placeName ?? ""
                
                if let mediaRef = data.mediaRef, !mediaRef.isEmpty {
                    var array: [MediaType] = []
                    var playerArray: [AVPlayer?] = []
                    
                    for (index, media) in mediaRef.enumerated() {
                        if index == 0 && media.mediaType == "video" {
                            firstImage = media.thumbnailURL
                            break
                        }
                        if media.mediaType == "image" {
                            firstImage = media.thumbnailURL
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
                
                if let address = data.postedBy?.businessProfileRef?.address {
//                        if let street = address.street,
//                           let city = address.city,
                        if let state = address.state,
//                           let zipCode = address.zipCode,
                       let country = address.country {
                            location = "\(state), \(country)"
                    }
                }
                
                if let content = data.content {
                    self.content = content
                }
            }
            .store(in: &cancellables)
        
        $content
            .sink { [weak self] content in
                guard let self else { return }
                
                let fullDescription = getAttributedDescription(content: content)
                self.fullDescription = fullDescription
            }
            .store(in: &cancellables)
        
        $accountType
            .sink { [weak self] type in
                guard let self else { return }
                if type == "individual" {
                    profilePic = data.postedBy?.profilePic?.small
                    name = data.postedBy?.name
                } else {
                    profilePic = data.postedBy?.businessProfileRef?.profilePic?.small
                    name = data.postedBy?.businessProfileRef?.name
                    
                    if let address = data.postedBy?.businessProfileRef?.address {
                            if let state = address.state,
                           let country = address.country {
                                location = "\(state), \(country)"
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
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
    }
    
    
    func configureProperties(data: PostData) {
        accountType = data.postedBy?.accountType
        location = data.location?.placeName ?? ""
        
        if let mediaRef = data.mediaRef, !mediaRef.isEmpty {
            var array: [MediaType] = []
            var playerArray: [AVPlayer?] = []
            
            for (index, media) in mediaRef.enumerated() {
                if index == 0 && media.mediaType == "video" {
                    firstImage = ""
                    break
                }
                if media.mediaType == "image" {
                    firstImage = media.thumbnailURL
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
        
        likedByMe = data.likedByMe ?? false
        savedByMe = data.savedByMe ?? false
        
        if let feelings = data.feelings {
            feeling = feelings
        }
        
        if let content = data.content {
            self.content = content
        }
        
        if let taggedRef = data.taggedRef {
            self.taggedRef = taggedRef
        }
    }
    
    func resetData() {
        for index in 0..<avplayers.count {
            avplayers[index] = nil
        }
    }
    
    func getAttributedDescription(content: String) -> AttributedString {
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
        
        // Add underline style for URLs
        if link.hasPrefix("http://") || link.hasPrefix("https://") || link.hasPrefix("link://") {
            tappableText.underlineStyle = Text.LineStyle.single
        }
        
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
}

extension Double {
    func formatNumber() -> String {
        if self >= 1_000_000_000 {
            
            let remainder = self.truncatingRemainder(dividingBy: 1000_000_000)
            
            if remainder == 0 {
                return String(format: "%.0fB", self / 1_000_000_000) // Billion
            } else {
                return String(format: "%.1fB", self / 1_000_000_000) // Billion
            }
            
        } else if self >= 1_000_000 {
            
            let remainder = self.truncatingRemainder(dividingBy: 1_000_000)
            
            if remainder == 0 {
                return String(format: "%.0fM", self / 1_000_000) // Million
            } else {
                return String(format: "%.1fM", self / 1_000_000) // Million
            }
            
        } else if self >= 1_000 {
            let remainder = self.truncatingRemainder(dividingBy: 1000)
            
            if remainder == 0 {
                return String(format: "%.0fK", self / 1_000) // Thousand
            } else {
                return String(format: "%.1fK", self / 1_000) // Thousand
            }
        } else {
            return String(format: "%.0f", self) // Less than 1,000
        }
    }
}


extension Int {
    func formatNumber() -> String {
        if self >= 1_000_000_000 {
            return String(format: "%.1fB", self / 1_000_000_000) // Billion
        } else if self >= 1_000_000 {
            return String(format: "%.1fM", self / 1_000_000) // Million
        } else if self >= 1_000 {
            return String(format: "%.1fK", self / 1_000) // Thousand
        } else {
            return String(format: "%.0f", self) // Less than 1,000
        }
    }
}
