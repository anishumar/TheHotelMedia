//
//  ShareToChatViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 31/01/25.
//

import SwiftUI
import SwiftfulRouting
import Combine

class ShareToChatViewModel: ObservableObject {
    
    var router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    var socketViewModel = SocketIOViewModel.shared
    var connectionsDataManager = UserConnectionsDataManager()
    
    @Published var searchText: String = ""
    @Published var userList: [ChatUser] = []
    @Published var recentChat: [RecentChat] = []
    @Published var followersList: [SearchProfileData] = []
    @Published var followingList: [SearchProfileData] = []
    @Published var filteredOnlineUsers: [ChatUser] = []
    @Published var filteredRecentChats: [RecentChat] = []
    @Published var filteredFollowersFollowing: [SearchProfileData] = []
    @Published var showLoadingIndicator: Bool = false
    @Published var gotInitialData: Bool = false
    
    // Multi-selection state
    @Published var selectedUserIDs: Set<String> = []
    @Published var isSharing: Bool = false
    @Published var shareProgress: (sent: Int, total: Int) = (0, 0)
    
    var dismissView: (() -> Void)?
    var sharePostData: PostData? = nil
    
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    init(router: AnyRouter) {
        self.router = router
        addSubscribers()
    }
    
    func addSubscribers() {
        // Online users list
        socketViewModel.$userList
            .sink { [weak self] list in
                guard let self else { return }
                self.userList = list
                self.filterChats()
            }
            .store(in: &cancellables)
        
        // Recent chats list
        socketViewModel.$recentChat
            .sink { [weak self] chats in
                guard let self else { return }
                self.recentChat = chats
                self.gotInitialData = true
                self.showLoadingIndicator = false
                self.filterChats()
            }
            .store(in: &cancellables)
    }
    
    func loadChats() {
        showLoadingIndicator = true
        gotInitialData = false
        
        // Ensure socket is connected
        if !socketViewModel.isConnected {
            socketViewModel.configureSocket { [weak self] in
                guard let self else { return }
                self.socketViewModel.usersListEmit()
                self.socketViewModel.chatScreenEmit(query: "", pageNo: 1)
            }
        } else {
            socketViewModel.usersListEmit()
            socketViewModel.chatScreenEmit(query: "", pageNo: 1)
        }
        
        // Load followers and following
        loadFollowers()
        loadFollowing()
    }
    
    func loadFollowers() {
        guard !ownUserID.isEmpty else { return }
        
        Task {
            do {
                let result = try await connectionsDataManager.getfollowers(id: ownUserID, pageNo: 1)
                
                await MainActor.run {
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            followersList = data
                            DispatchQueue.main.async {
                                self.filterChats()
                            }
                        }
                    }
                }
            } catch {
                print("Error loading followers: \(error)")
            }
        }
    }
    
    func loadFollowing() {
        guard !ownUserID.isEmpty else { return }
        
        Task {
            do {
                let result = try await connectionsDataManager.getfollowing(id: ownUserID, pageNo: 1)
                
                await MainActor.run {
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            followingList = data
                            DispatchQueue.main.async {
                                self.filterChats()
                            }
                        }
                    }
                }
            } catch {
                print("Error loading following: \(error)")
            }
        }
    }
    
    func filterChats() {
        if searchText.isEmpty {
            filteredOnlineUsers = userList
            filteredRecentChats = recentChat
            // Combine followers and following, removing duplicates
            let combined = Array(Set(followersList + followingList))
            filteredFollowersFollowing = combined
        } else {
            let searchLower = searchText.lowercased()
            filteredOnlineUsers = userList.filter { user in
                (user.name?.lowercased().contains(searchLower) ?? false) ||
                (user.username?.lowercased().contains(searchLower) ?? false)
            }
            filteredRecentChats = recentChat.filter { chat in
                (chat.name?.lowercased().contains(searchLower) ?? false) ||
                (chat.username?.lowercased().contains(searchLower) ?? false)
            }
            // Filter followers and following by search text
            let allFollowersFollowing = followersList + followingList
            filteredFollowersFollowing = allFollowersFollowing.filter { profile in
                (profile.name?.lowercased().contains(searchLower) ?? false) ||
                (profile.username?.lowercased().contains(searchLower) ?? false)
            }
            // Remove duplicates
            filteredFollowersFollowing = Array(Set(filteredFollowersFollowing))
        }
    }
    
    func cancelPublishers() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()
    }
    
    deinit {
        cancelPublishers()
    }
    
    // MARK: - Multi-Selection Helpers
    
    func toggleUserSelection(userID: String) {
        if selectedUserIDs.contains(userID) {
            selectedUserIDs.remove(userID)
        } else {
            selectedUserIDs.insert(userID)
        }
    }
    
    func isUserSelected(userID: String) -> Bool {
        return selectedUserIDs.contains(userID)
    }
    
    func clearSelection() {
        selectedUserIDs.removeAll()
    }
    
    // MARK: - Batch Share Function
    
    func sharePostToMultipleUsers(
        postData: PostData,
        users: [(username: String, userID: String, profilePic: String, name: String)],
        onProgress: @escaping (Int, Int) -> Void,
        onComplete: @escaping (Int, Int) -> Void // (successCount, totalCount)
    ) {
        guard !isSharing else { return }
        guard socketViewModel.isConnected else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Connection lost. Please try again.")
            return
        }
        
        guard let mediaRefs = postData.mediaRef, !mediaRefs.isEmpty else {
            return
        }
        
        isSharing = true
        shareProgress = (0, users.count)
        
        // For video posts, find the video media. Otherwise use the first media.
        let targetMedia = mediaRefs.first(where: { media in
            if let mimeType = media.mimeType, mimeType.contains("video") {
                return true
            }
            return false
        }) ?? mediaRefs.first
        
        guard let firstMedia = targetMedia,
              let mediaID = firstMedia.id,
              let mediaUrl = firstMedia.sourceURL else {
            isSharing = false
            return
        }
        
        let messageType: String
        if let mimeType = firstMedia.mimeType, mimeType.contains("video") {
            messageType = "video"
        } else {
            messageType = "image"
        }
        
        let thumbnailUrl = firstMedia.thumbnailURL ?? (messageType == "image" ? mediaUrl : nil)
        let messageText = postData.content ?? "Check this out!"
        
        var successCount = 0
        var sentCount = 0
        let totalCount = users.count
        
        // Send to all users with a small delay between each to avoid overwhelming the socket
        for (index, user) in users.enumerated() {
            let clientMessageID = UUID().uuidString
            
            var messageModel: [String: Any] = [
                "type": messageType,
                "message": messageText,
                "clientMessageID": clientMessageID,
                "mediaID": mediaID,
                "mediaUrl": mediaUrl,
                "postID": postData.id ?? "",
                "postOwnerID": (postData.userID ?? postData.postedBy?.id ?? ""),
                "isSharedPost": true
            ]
            
            if let thumbnailUrl {
                messageModel.updateValue(thumbnailUrl, forKey: "thumbnailUrl")
            }
            
            let parameters: [String: Any] = [
                "message": messageModel,
                "to": user.username,
                "clientMessageID": clientMessageID
            ]
            
            // Add delay between sends to avoid overwhelming the socket
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                self.socketViewModel.sendMessage(parameters: parameters)
                sentCount += 1
                self.shareProgress = (sentCount, totalCount)
                onProgress(sentCount, totalCount)
                
                // Mark as success after a short delay (server will confirm via socket)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    successCount += 1
                    
                    // If all messages sent, complete
                    if sentCount == totalCount {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isSharing = false
                            self.shareProgress = (0, 0)
                            onComplete(successCount, totalCount)
                        }
                    }
                }
            }
        }
    }
}

