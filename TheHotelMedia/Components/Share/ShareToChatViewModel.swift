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
}

