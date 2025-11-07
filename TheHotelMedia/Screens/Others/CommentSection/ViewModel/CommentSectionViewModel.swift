//
//  CommentSectionViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 03/10/24.
//

import SwiftUI
import Combine
import SwiftfulRouting


class CommentSectionViewModel: ObservableObject {
    
    
    var postID: String
    @Published var totalComments: Int
    var onAddingComment: ((String) -> Void)?
    let dataManager = CommentDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var comments: [Comment] = []
    @Published var pageNo = 1
    @Published var totalPages = 1
    @Published var totalResources: Int = 0
    @Published var commentFieldText: String = ""
    @Published var showLoadingIndicator: Bool = false
    @Published var replyingComment: Comment? = nil
    @Published var keyboardHeight: CGFloat = 0
    @Published var replyingProfilePic: String? = nil
    @Published var replyingName: String? = nil
    @Published var refreshData: Bool = false
    @Published var dismiss: Bool = false
    var commentsYOffset: [CGFloat] = []
    @Published var selectedYOffset: CGFloat = 0
    @Published var selectedCommentID: String = ""
    @Published var reportMessage: String = ""
    @Published var showCommentOptions: Bool = false
    @Published var showReportScreen: Bool = false
    @Published var showReportMessage: Bool = false
    
    init(postID: String, totalComments: Int, isEmbedded: Bool = false, onAddingComment:((String) -> Void)? = nil){
        self.postID = postID
        self.totalComments = totalComments
        self.onAddingComment = onAddingComment
        addSubscribers()
        if totalComments != 0 {
            getComments(showLoadingIndicator: !isEmbedded)
        }
    }
    
    
    func addSubscribers() {
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
    
}


// MARK: -  Networking
extension CommentSectionViewModel {
    
    func getComments(refreshData: Bool = false, showLoadingIndicator: Bool = true) {
        
        guard pageNo <= totalPages else { return }
        
        self.showLoadingIndicator = showLoadingIndicator
        
        Task {
            do {
                let result = try await dataManager.getComments(postID: postID, pageNo: refreshData ? 1 : pageNo)
                
                await MainActor.run {
                    self.showLoadingIndicator = false
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            handleData(data: data, refreshData: refreshData)
                        }
                        
                        pageNo = result.pageNo ?? 1
                        totalPages = result.totalPages ?? 1
                        totalResources = result.totalResources ?? 0
                    } else {
                        
                    }
                }
            } catch {
                await MainActor.run {
                    self.showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
    
    
    func handleData(data: [Comment], refreshData: Bool = false) {
        if refreshData {
            var offsetArray: [CGFloat] = []
            for _ in data {
                offsetArray.append(0)
            }
            commentsYOffset = offsetArray
            comments = data
            self.refreshData.toggle()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
//                guard let self else { return }
//                comments = data
//                self.refreshData.toggle()
//            }
            
        } else {
            var offsetArray: [CGFloat] = []
            for _ in data {
                offsetArray.append(0)
            }
            commentsYOffset.append(contentsOf: offsetArray)
            comments.append(contentsOf: data)
        }
    }
    
    
    
    func postComment(comment: String = "", oncompletion: (() -> Void)? = nil) {
        
        if comment.isEmpty {
            guard !commentFieldText.isEmpty else { return }
        }
        
        if comment.isEmpty {
            showLoadingIndicator = true
        }
        
        Task {
            var parameters: [String: Any] = [
                "postID" : postID,
                "message" : comment.isEmpty ? commentFieldText : comment
            ]
            
            if let replyingComment {
                parameters.updateValue(replyingComment.id ?? "", forKey: "parentID")
            }
            
            do {
                let result = try await dataManager.postComment(parameters: parameters)
                let range = 200...204
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
//                        getComments(refreshData: true)
                        oncompletion?()
                        if comment.isEmpty {
                            commentFieldText = ""
                            totalComments += 1
//                            dismiss = true
                            onAddingComment?(postID)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                                guard let self else { return }
                                pageNo = 1
                                getComments(refreshData: true)
                            }
                        } else {
                            totalComments += 1
                            onAddingComment?(postID)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                                guard let self else { return }
                                pageNo = 1
                                getComments(refreshData: true)
                            }
                        }
                        replyingComment = nil
                    } else {
                    }
                }
            } catch {
                print(error)
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
        }
    }
    
    
    func likeAComment(commentID: String) {
        Task {
            do {
                let _ = try await dataManager.likeAComment(commentID: commentID)
            } catch {
                print(error)
            }
        }
    }
}
