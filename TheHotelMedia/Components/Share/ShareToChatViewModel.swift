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
    
    @Published var searchText: String = ""
    @Published var userList: [ChatUser] = []
    @Published var recentChat: [RecentChat] = []
    @Published var filteredOnlineUsers: [ChatUser] = []
    @Published var filteredRecentChats: [RecentChat] = []
    @Published var showLoadingIndicator: Bool = false
    @Published var gotInitialData: Bool = false
    
    var dismissView: (() -> Void)?
    
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
    }
    
    func filterChats() {
        if searchText.isEmpty {
            filteredOnlineUsers = userList
            filteredRecentChats = recentChat
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

