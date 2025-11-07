//
//  GenericPostViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 05/03/25.
//

import SwiftUI
import AVKit
import Combine

class GenericPostViewModel: ObservableObject {
    
    @Published var postData: PostData? = nil
    @Published var accountType: String? = nil
    @Published var profilePic: String? = nil
    @Published var firstImage: String? = nil
    @Published var businessAddress: String? = ""
    @Published var coverImage: String = ""
    @Published var dateAndTimeString: String = ""
    @Published var isPausePost: Bool = true
    var isPausePost2: CurrentValueSubject<Bool, Never> = .init(true)
    @Published var isPausedArray: [Bool] = []
    @Published var location: String = ""
    @Published var feeling: String = ""
    @Published var name: String? = nil
    @Published var showTagList: Bool = false
    @Published var isPlayingVideo: Bool = false
    @Published var mediaContent: [MediaType] = []
    @Published var taggedRef: [TaggedRef] = []
    @Published var fullDescription: AttributedString = AttributedString()
    @Published var previousPage: Int = 0
    @Published var heartScale: CGFloat = 1.0
    @Published var avplayers: [AVPlayer?] = []
    @Published var currentPage: Int = 0 {
        didSet {
            previousPage = oldValue
        }
    }
    @Published var isJoining: Bool = false
    @Published var likedByMe: Bool = false
    @Published var savedByMe: Bool = false
    @Published var isValidEvent: Bool = true
    @Published var likes: Int? = 1
    @Published var shares: Int? = nil
    
    var avplayers2: CurrentValueSubject<[AVPlayer?], Never> = .init([])
    var isPauseArray2: CurrentValueSubject<[Bool], Never> = .init([])
    var coverImage2: CurrentValueSubject<String, Never> = .init("")
    var firstImage2: CurrentValueSubject<String, Never> = .init("")
    
//    @Published var isBufferingVideo: Bool = false
    var cancellables = Set<AnyCancellable>()
    var mediaFrames: [Int: CGRect] = [:]
    var videoHidden: Bool = false
    var lastMediaIndex: Int = 0
    var mediaTabFrame: CGRect = .zero
    var rate: Float = 0
    
    
    init(postData: PostData? = nil) {
        currentPage = postData?.currentPage ?? 0
        if let postData = postData {
            self.postData = postData
            configureInitialData(postData: postData)
        }
        addOtherSubscribers()
    }
    
    
    func addPostDataSubscriber() {
        $postData
            .sink { [weak self] data in
                guard let self else { return }
                if let data {
                    configureInitialData(postData: data)
                }
            }
            .store(in: &cancellables)
    }
    
    
    func addOtherSubscribers() {
        
        $currentPage
            .combineLatest(isPausePost2)
            .sink { [weak self] (currentPage, isPausePost) in
                guard let self else { return }
                var array: [Bool] = []
                
                guard !isPausedArray.isEmpty else { return }
                
                for _ in 0..<isPausedArray.count {
                    array.append(true)
                }
                if !isPausePost {
                    array[currentPage] = false
                }
                
                self.isPausedArray = array
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
    }
    
    
    
    func configureInitialData(postData: PostData?) {
        
        accountType = postData?.postedBy?.accountType
        likedByMe = postData?.likedByMe ?? false
        savedByMe = postData?.savedByMe ?? false
        likes = postData?.likes
        shares = postData?.shared
        feeling = postData?.feelings ?? ""
        configureUserData(postData: postData)
        taggedRef = postData?.taggedRef ?? []
        
        if let postType = postData?.postType {
            if postType == "post" {
                configureMediaArray(postData: postData)
                fullDescription = getAttributedDescriptionForPost(content: postData?.content ?? "")
            } else if postType == "review" {
                if let address = postData?.reviewedBusinessProfileRef?.address {
                    businessAddress = "\(address.street?.capitalized ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                }
                
                coverImage = postData?.reviewedBusinessProfileRef?.coverImage ?? ""
//                coverImage2.send(postData?.reviewedBusinessProfileRef?.coverImage ?? "")
                fullDescription = getReviewDescription(content: postData?.content ?? "")
            } else if postType == "event" {
                configureMediaArray(postData: postData)
                if let timeString = formatTimeString(string: postData?.startTime ?? ""),
                   let dateString = formatDateString(string: postData?.startDate ?? ""){
                        dateAndTimeString = "\(dateString) at \(timeString)"
                }
                
                isValidEvent = DateManager.isFutureDate(dateString: postData?.startDate ?? "", timeString: postData?.startTime ?? "")
                
                isJoining = postData?.imJoining ?? false
            }
        }
    }
    
    
    func configureUserData(postData: PostData?) {
        if accountType == "individual" {
            profilePic = postData?.postedBy?.profilePic?.small
            name = postData?.postedBy?.name
            
        } else {
            profilePic = postData?.postedBy?.businessProfileRef?.profilePic?.small
            name = postData?.postedBy?.businessProfileRef?.name
            
            if let address = postData?.postedBy?.businessProfileRef?.address {
                    if let state = address.state,
                   let country = address.country {
                        location = "\(state), \(country)"
                }
            }
        }
    }
    
    
    func configureMediaArray(postData: PostData?) {
        if let mediaRef = postData?.mediaRef, !mediaRef.isEmpty {
            var array: [MediaType] = []
            var boolArray: [Bool] = []
            var playerArray: [AVPlayer?] = []
            
            for (index, media) in mediaRef.enumerated() {
                if index == 0 && media.mediaType == "video" {
                    firstImage = media.thumbnailURL
//                    firstImage2.send(media.thumbnailURL ?? "")
                    break
                }
                if media.mediaType == "image" {
                    firstImage = media.thumbnailURL
//                    firstImage2.send(media.sourceURL ?? "")
                    break
                }
            }
            
            for media in mediaRef {
                if media.mediaType == "image" {
                    array.append(.image(urlString: media.sourceURL ?? ""))
                    playerArray.append(nil)
                } else {
                    array.append(.video(urlString: media.sourceURL ?? ""))
                    let playerItem = AVPlayerItem(url: URL(string: media.sourceURL ?? "")!)
                    playerItem.preferredForwardBufferDuration = 3.0
                    playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
                    let player = AVPlayer(playerItem: playerItem)
                    player.automaticallyWaitsToMinimizeStalling = false
                    playerArray.append(player)
                }
                boolArray.append(true)
            }
            avplayers = playerArray
//            avplayers2.send(playerArray)
            
            mediaContent = array
            
            isPausedArray = boolArray
//            isPauseArray2.send(boolArray)
        }
    }
    
    
    func getReviewDescription(content: String) -> AttributedString {
        
        // Determine if content needs truncation
        let isContentLong = content.count > 160
        let truncatedContent = isContentLong ? String(content.prefix(160)) : content
        var attributedString = AttributedString(postData?.isExpandedDescription ?? false ? content : truncatedContent)
        
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
        
        
        
        // Append Read More/Read Less
        if isContentLong {
            let readMoreOrLessText = postData?.isExpandedDescription ?? false ? "...Read less" : "...Read more"
            appendTappableText(&attributedString, text: readMoreOrLessText, link: "readmore://\(postData?.id ?? "")")
        }
        
        return attributedString
    }
    
    
    
    func getAttributedDescriptionForPost(content: String) -> AttributedString {
        // Determine if content needs truncation
        let length = mediaContent.isEmpty ? 400 : 160
        let isContentLong = content.count > length
        let truncatedContent = isContentLong ? String(content.prefix(length)) : content
        var attributedString = AttributedString(postData?.isExpandedDescription ?? false ? content : truncatedContent)
        
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
            appendTappableText(&attributedString, text: " - \(feeling)", link: "feeling://\(postData?.id ?? "")")
        }
        
        // Append tags
        if !taggedRef.isEmpty {
            let tagText = taggedRef.count == 1
            ? "\(taggedRef[0].name ?? "")"
            : "\(taggedRef[0].name ?? "") and \(taggedRef.count - 1) others"
            appendTappableText(&attributedString, text: " - with \(tagText)", link: "tags://\(postData?.id ?? "")")
        }
        
        // Append location
        if let location = postData?.location {
            appendTappableText(&attributedString, text: " - at \(location.placeName ?? "")", link: "loc://\(postData?.id ?? "")?lat=\(location.lat ?? 0.0)&lng=\(location.lng ?? 0.0)")
        }
        
        // Append Read More/Read Less
        if isContentLong {
            let readMoreOrLessText = postData?.isExpandedDescription ?? false ? "...Read less" : "...Read more"
            appendTappableText(&attributedString, text: readMoreOrLessText, link: "readmore://\(postData?.id ?? "")")
        }
        
        return attributedString
    }
    
    
    func appendTappableText(_ attributedString: inout AttributedString, text: String, link: String) {
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
    
    
    func formatTimeString(string: String) -> String? {
        let timeString = string

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm" // Input format: 24-hour time

        if let date = inputFormatter.date(from: timeString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "h:mm a" // Output format: 12-hour time with AM/PM
            let convertedTimeString = outputFormatter.string(from: date)
            
            return convertedTimeString
        } else {
            return nil
        }
    }
    
    
    func formatDateString(string: String) -> String? {
        let dateString = string

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd" // Input format: 2024-10-16

        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "E, d MMM" // Output format: Wed, 16 Oct
            let formattedDate = outputFormatter.string(from: date)
            return formattedDate
        } else {
            return nil
        }
    }
}
