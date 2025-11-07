//
//  SocketIOViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 26/11/24.
//

import SwiftUI
import SocketIO


class SocketIOViewModel: ObservableObject {
    
    
    static var shared = SocketIOViewModel()
    
    private var socketManager: SocketManager?
    
    @Published var isConnected: Bool = false
    
    // Properties for All Chat List Screen
    var recentChatTotalPages: Int = 1
    @Published var recentChatPageNo: Int = 1
    @Published var refreshRecent: Bool = true
    @Published var userList: [ChatUser] = []
    @Published var recentChat: [RecentChat] = []
    
    // Properties for private conversation screen
    var privateChatTotalPages: Int = 1
    @Published var privateChatPageNo: Int = 1
    @Published var refreshMessages: Bool = true
    @Published var privateMessagesList: [PrivateMessage] = []
    @Published var newMessage: PrivateMessage? = nil
    @Published var userConnectedOrDisconnected: Bool = false
    
    @AppStorage("username") var username: String = ""
    @AppStorage("lastConnectedUser") var lastConnectedUser: String = ""
    @AppStorage("appIsActive") var appIsActive: Bool = true
    
    func configureSocket(onConnected: (() -> Void)? = nil) {
        
        guard appIsActive else { return }
        
        let config = SocketIOClientConfiguration(
            arrayLiteral: .log(false), .compress
        )
        
        let parameters: [String: Any] = [
            "username" : username
        ]
        
        socketManager = SocketManager(socketURL: URL.baseURL, config: config)
        let currentConnectUser = username
        socketManager?.defaultSocket.on(clientEvent: .connect) { [weak self] data, ack in
            guard let self else { return }
            print("Socket Connected!!!")
            isConnected = true
            onConnected?()
            lastConnectedUser = currentConnectUser
        }
        
        
        socketManager?.defaultSocket.on(clientEvent: .disconnect) { [weak self] data, ack in
            guard let self else { return }
            print("Socket Disconnected!!!")
            isConnected = false
        }
        
        
        socketManager?.defaultSocket.on(clientEvent: .error) { data, ack in
            print("Error Connecting to Socket!!!")
        }
        
        
        socketManager?.defaultSocket.on("private message") { [weak self] data, ack in
            guard let self else { return }
            if let message = JSONSerializationManager.getSingleMessage(data: data) {
                newMessage = message
            }
            chatScreenEmit(query: "", pageNo: 1)
        }
        
        
        socketManager?.defaultSocket.on("users") { [weak self] data, ack in
            guard let self else { return }
            if let array = JSONSerializationManager.getUserList(data: data) {
                userList = array
            }
        }
        
        socketManager?.defaultSocket.on("chat screen") { [weak self] data, ack in
            guard let self else { return }
            let (array, pageNumber, totalPages) = JSONSerializationManager.getRecentChatList(data: data)
            
            if let array = array,
               let pageNo = pageNumber,
               let totalPages = totalPages {
                
                recentChatPageNo = pageNo
                recentChatTotalPages = totalPages
                refreshRecent = pageNo == 1
                recentChat = array
            }
        }
        
        socketManager?.defaultSocket.on("fetch conversations") { [weak self] data, ack in
            guard let self else { return }
            let (array, pageNumber, totalPages) = JSONSerializationManager.getPrivateMessagesList(data: data)
            
            if let array = array,
               let pageNo = pageNumber,
               let totalPages = totalPages {
                
                privateChatPageNo = pageNo
                privateChatTotalPages = totalPages
                refreshMessages = pageNo == 1
                privateMessagesList = array
            }
        }
        
        socketManager?.defaultSocket.on("user connected") { [weak self] data, ack in
            guard let self else { return }
            userConnectedOrDisconnected = true
        }
        
        socketManager?.defaultSocket.on("user disconnected") { [weak self] data, ack in
            guard let self else { return }
            userConnectedOrDisconnected = false
        }
        
        print(username)
        socketManager?.defaultSocket.connect(withPayload: parameters)
    }
    
    
    func usersListEmit() {
        self.socketManager?.defaultSocket.emit("users", [:])
    }
    
    func insideRecentChatEmit() {
        self.socketManager?.defaultSocket.emit("in chat", [:])
    }
    
    func leaveRecentChatEmit() {
        self.socketManager?.defaultSocket.emit("leave chat", [:])
    }
    
    func insidePrivateChat(user: String) {
        self.socketManager?.defaultSocket.emit("in private chat", user)
    }
    
    func leavePrivateChatEmit(user: String) {
        self.socketManager?.defaultSocket.emit("leave private chat", user)
    }
    
    
    func messageSeenEmit(user: String) {
        self.socketManager?.defaultSocket.emit("message seen", user)
    }
    
    
    func sendMessage(parameters: [String: Any]) {
        socketManager?.defaultSocket.emit("private message", parameters)
    }
    
    
    func chatScreenEmit(query: String, pageNo: Int) {
        guard pageNo <= recentChatTotalPages else { return }
        socketManager?.defaultSocket.emit("chat screen", ["query": query, "pageNumber": "\(pageNo)"])
    }
    
    
    func fetchPrivateConversation(username: String, pageNumber: Int) {
        guard pageNumber <= privateChatTotalPages else { return }
        socketManager?.defaultSocket.emit("fetch conversations", ["username": username, "pageNumber": pageNumber])
    }
    
    
    func disconnectSocket() {
        socketManager?.defaultSocket.disconnect()
    }
    
    
    
}
