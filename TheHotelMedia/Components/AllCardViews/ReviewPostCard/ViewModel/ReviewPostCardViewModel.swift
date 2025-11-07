//
//  ReviewPostCardViewModel.swift
//  HotelMedia
//
//  Created by MAC on 29/08/24.
//

import Foundation
import Combine


final class ReviewPostCardViewModel: ObservableObject {
    
    var cancellables = Set<AnyCancellable>()
    @Published var data: PostData
    @Published var isPausePost: Bool = true
    @Published var accountType: String? = nil
    @Published var profilePic: String? = nil
    @Published var location: String? = nil
    @Published var name: String? = nil
    @Published var coverImage: String = ""
    @Published var businessAddress: String? = ""
    @Published var likes: String = "0"
    @Published var likedByMe: Bool = false
    @Published var savedByMe: Bool = false
    @Published var comments: String = "0"
    @Published var shares: String = "0"
    @Published var content: String = ""
    @Published var fullDescription: AttributedString = AttributedString()
    @Published var likesCount: Int = 0
    @Published var commentsCount: Int = 0
    @Published var shareCount: Int = 0
    @Published var heartScale: CGFloat = 1.0
    
    init(data: PostData) {
        self.data = data
        addSubscribers()
        print("ReviewCardViewModel init")
    }
    
    deinit {
        print("ReviewCardViewModel deinit")
    }
    
    
    func addSubscribers() {
        $data
            .sink { [weak self] data in
                guard let self else { return }
                accountType = data.postedBy?.accountType
                location = data.location?.placeName
                if let address = data.reviewedBusinessProfileRef?.address {
                    businessAddress = "\(address.street?.capitalized ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                }
                
                coverImage = data.reviewedBusinessProfileRef?.coverImage ?? ""
                likesCount = data.likes ?? 0
                commentsCount = data.comments ?? 0
                
                likedByMe = data.likedByMe ?? false
                savedByMe = data.savedByMe ?? false
                
                if let shared = data.shared {
                    shares = "\(shared)"
                }
                
                if let content = data.content {
                    self.content = content
                }
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
//                        if let street = address.street,
//                           let city = address.city,
                            if let state = address.state,
//                           let zipCode = address.zipCode,
                           let country = address.country {
                                location = "\(state), \(country)"
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        $content
            .sink { [weak self] content in
                guard let self else { return }
                let description = getSimpleDescription(content: content)
                fullDescription = description
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
    }
    
    func getSimpleDescription(content: String) -> AttributedString {
        
        // Determine if content needs truncation
        let isContentLong = content.count > 160
        let truncatedContent = isContentLong ? String(content.prefix(160)) : content
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
}
