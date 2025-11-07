//
//  CommentViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 10/10/24.
//

import Foundation
import Combine


class CommentViewModel: ObservableObject {
    
    var cancellables = Set<AnyCancellable>()
    @Published var comment: Comment
    @Published var name: String = ""
    @Published var profilePic: String = ""
    @Published var commentText: String = ""
    @Published var likedMyBe: Bool = false
    @Published var likesCount: Int = 0
    @Published var likes: String = "0"
    @Published var postedAgo: String = ""
    @Published var showReplies: Bool = false
    @Published var replyCommentYOffsets: [CGFloat] = []
    
    let localizationManager = LocalizationManager.shared
    
    init(comment: Comment) {
        self.comment = comment
        addSubscribers()
    }
    
    
    func addSubscribers() {
        $comment
            .sink { [weak self] comment in
                guard let self else { return }
                
                if let repliesRef = comment.repliesRef {
                    var offsetArray: [CGFloat] = []
                    for _ in repliesRef {
                        offsetArray.append(0)
                    }
                    
                    replyCommentYOffsets = offsetArray
                }
                
                commentText = comment.message ?? ""
                likesCount = comment.likes ?? 0
                likedMyBe = comment.likedByMe ?? false
                postedAgo = DateManager.getPostedAgoTime(date: comment.createdAt ?? "", language: localizationManager.language)
                
                if let commentedBy = comment.commentedBy,
                   let accountType = commentedBy.accountType {
                    
                    if accountType == "individual" {
                        name = commentedBy.name ?? ""
                        profilePic = commentedBy.profilePic?.small ?? ""
                    } else {
                        if let businessProfileRef = commentedBy.businessProfileRef {
                            name = businessProfileRef.name ?? ""
                            profilePic = businessProfileRef.profilePic?.small ?? ""
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        $likesCount
            .sink { [weak self] count in
                guard let self else { return }
                likes = formatNumber(Double(count))
            }
            .store(in: &cancellables)
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
