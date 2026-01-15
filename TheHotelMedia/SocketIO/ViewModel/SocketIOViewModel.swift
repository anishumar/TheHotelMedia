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
    
    /// Enable to print raw socket payloads for debugging chat message formats.
    /// - Debug: ON by default (so we can inspect backend payloads without extra steps)
    /// - Release: OFF by default (can be enabled via UserDefaults key "debugSocketPayloads")
    private var debugSocketPayloads: Bool {
#if DEBUG
        return true
#else
        return UserDefaults.standard.bool(forKey: "debugSocketPayloads")
#endif
    }
    
    private var socketManager: SocketManager?
    private var handlersRegistered: Bool = false
    private var configuredUsername: String? = nil
    
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
    
    // Message mutations (edit/delete) – emitted by backend, consumed by chat UI.
    @Published var editedMessageUpdate: SocketMessageEditUpdate? = nil
    @Published var deletedMessageUpdate: SocketMessageDeleteUpdate? = nil
    
    @AppStorage("username") var username: String = ""
    @AppStorage("lastConnectedUser") var lastConnectedUser: String = ""
    @AppStorage("appIsActive") var appIsActive: Bool = true
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    func configureSocket(onConnected: (() -> Void)? = nil) {
        
        guard appIsActive else { return }
        
        let currentConnectUser = username
        var payload: [String: Any] = ["username": currentConnectUser]
        
        // Add userID to the socket handshake (Option 1: Recommended)
        // This will be available in socket.handshake.auth.userID on the backend
        if !ownUserID.isEmpty {
            payload["userID"] = ownUserID
        }
        
        // If the logged-in username changed, tear down the previous socket completely.
        if configuredUsername != currentConnectUser, let existing = socketManager?.defaultSocket {
            existing.removeAllHandlers()
            existing.disconnect()
            socketManager = nil
            handlersRegistered = false
        }
        configuredUsername = currentConnectUser
        
        if socketManager == nil {
            // Build connectParams with userID as query parameter (Option 2: Fallback)
            // This will be available in socket.handshake.query.userID on the backend
            var connectParams: [String: String] = [:]
            if !ownUserID.isEmpty {
                connectParams["userID"] = ownUserID
            }
            
            // Build configuration options
            if !connectParams.isEmpty {
                let config = SocketIOClientConfiguration(
                    arrayLiteral:
                        .log(false),
                        .compress,
                        .reconnects(true),
                        .reconnectAttempts(-1),
                        .reconnectWait(1),
                        .reconnectWaitMax(5),
                        .forceWebsockets(true),
                        .connectParams(connectParams)
                )
                socketManager = SocketManager(socketURL: URL.baseURL, config: config)
            } else {
                let config = SocketIOClientConfiguration(
                    arrayLiteral:
                        .log(false),
                        .compress,
                        .reconnects(true),
                        .reconnectAttempts(-1),
                        .reconnectWait(1),
                        .reconnectWaitMax(5),
                        .forceWebsockets(true)
                )
                socketManager = SocketManager(socketURL: URL.baseURL, config: config)
            }
        }
        
        guard let socket = socketManager?.defaultSocket else { return }
        
        // Register handlers only once per socket lifecycle.
        if !handlersRegistered {
            handlersRegistered = true
            
            socket.on(clientEvent: .connect) { [weak self] data, ack in
                guard let self else { return }
                print("Socket Connected!!!")
                DispatchQueue.main.async {
                    self.isConnected = true
                    onConnected?()
                    self.lastConnectedUser = currentConnectUser
                }
            }
        
        
            socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            guard let self else { return }
            print("Socket Disconnected!!!")
            DispatchQueue.main.async {
                self.isConnected = false
            }
            }
        
        
            socket.on(clientEvent: .error) { [weak self] data, ack in
                print("Socket Error:", data)
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
            }
        
        
            socket.on("private message") { [weak self] data, ack in
            guard let self else { return }
            if debugSocketPayloads {
                print("🧩 [Socket] private message raw payload:", String(describing: data))
            }
            if let message = JSONSerializationManager.getSingleMessage(data: data) {
                if debugSocketPayloads {
                    print("🧩 [Socket] parsed PrivateMessage:", message)
                }
                DispatchQueue.main.async {
                    self.newMessage = message
                }
            }
            self.chatScreenEmit(query: "", pageNo: 1)
            }

            socket.on("edit message") { [weak self] data, ack in
            guard let self else { return }
            if let update = JSONSerializationManager.getEditMessageUpdate(data: data) {
                DispatchQueue.main.async {
                    self.editedMessageUpdate = update
                    self.applyEditUpdateToCachedMessages(update)
                }
            }
            }
        
            socket.on("delete message") { [weak self] data, ack in
            guard let self else { return }
            if let update = JSONSerializationManager.getDeleteMessageUpdate(data: data) {
                DispatchQueue.main.async {
                    self.deletedMessageUpdate = update
                    self.applyDeleteUpdateToCachedMessages(update)
                }
            }
            }
        
        
            socket.on("users") { [weak self] data, ack in
            guard let self else { return }
            if let array = JSONSerializationManager.getUserList(data: data) {
                DispatchQueue.main.async {
                    self.userList = array
                }
            }
            }
        
            socket.on("chat screen") { [weak self] data, ack in
            guard let self else { return }
            let (array, pageNumber, totalPages) = JSONSerializationManager.getRecentChatList(data: data)
            
            if let array = array,
               let pageNo = pageNumber,
               let totalPages = totalPages {
                
                DispatchQueue.main.async {
                    self.recentChatPageNo = pageNo
                    self.recentChatTotalPages = totalPages
                    self.refreshRecent = pageNo == 1
                    self.recentChat = array
                }
            }
            }
        
            socket.on("fetch conversations") { [weak self] data, ack in
            guard let self else { return }
            if debugSocketPayloads {
                print("🧩 [Socket] fetch conversations raw payload:", String(describing: data))
            }
            let (array, pageNumber, totalPages) = JSONSerializationManager.getPrivateMessagesList(data: data)
            
            if let array = array,
               let pageNo = pageNumber,
               let totalPages = totalPages {
                
                DispatchQueue.main.async {
                    self.privateChatPageNo = pageNo
                    self.privateChatTotalPages = totalPages
                    self.refreshMessages = pageNo == 1
                    self.privateMessagesList = array
                }
            }
            }
        
            socket.on("user connected") { [weak self] data, ack in
            guard let self else { return }
            DispatchQueue.main.async {
                self.userConnectedOrDisconnected = true
            }
            }
        
            socket.on("user disconnected") { [weak self] data, ack in
            guard let self else { return }
            DispatchQueue.main.async {
                self.userConnectedOrDisconnected = false
            }
            }
        }
        
        // Avoid spawning multiple concurrent connection attempts.
        if socket.status != .connected && socket.status != .connecting {
            socket.connect(withPayload: payload)
        } else if socket.status == .connected {
            DispatchQueue.main.async {
                self.isConnected = true
                onConnected?()
            }
        }
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
    
    func editMessage(messageID: String, message: String) {
        socketManager?.defaultSocket.emit("edit message", ["messageID": messageID, "message": message])
    }
    
    func deleteMessage(messageID: String) {
        socketManager?.defaultSocket.emit("delete message", ["messageID": messageID])
    }
    
    // Keep local cache (`privateMessagesList`) in sync so navigating away/back doesn't "revert"
    // even if the next fetch races or returns slightly stale data.
    private func applyEditUpdateToCachedMessages(_ update: SocketMessageEditUpdate) {
        guard let index = findIndexInCachedMessages(messageID: update.messageID, clientMessageID: update.clientMessageID) else { return }
        
        let old = privateMessagesList[index]
        privateMessagesList[index] = PrivateMessage(
            id: old.id,
            createdAt: old.createdAt,
            isSeen: old.isSeen,
            content: update.message ?? old.content,
            sentByMe: old.sentByMe,
            type: old.type,
            messageID: update.messageID ?? old.messageID,
            clientMessageID: update.clientMessageID ?? old.clientMessageID,
            isEdited: update.isEdited ?? true,
            editedAt: update.editedAt ?? old.editedAt,
            isDeleted: old.isDeleted,
            deletedAt: old.deletedAt,
            mediaUrl: old.mediaUrl,
            thumbnailUrl: old.thumbnailUrl,
            mediaID: old.mediaID,
            postID: old.postID,
            postOwnerID: old.postOwnerID,
            isSharedPost: old.isSharedPost,
            from: update.from ?? old.from,
            to: update.to ?? old.to,
            thumbnail: old.thumbnail,
            hasUploaded: old.hasUploaded,
            isUploading: old.isUploading,
            isRemotePDF: old.isRemotePDF,
            isURL: old.isURL,
            showDate: old.showDate,
            pdfData: old.pdfData
        )
    }
    
    private func applyDeleteUpdateToCachedMessages(_ update: SocketMessageDeleteUpdate) {
        guard let index = findIndexInCachedMessages(messageID: update.messageID, clientMessageID: update.clientMessageID) else { return }
        
        let old = privateMessagesList[index]
        privateMessagesList[index] = PrivateMessage(
            id: old.id,
            createdAt: old.createdAt,
            isSeen: old.isSeen,
            content: "The message was deleted",
            sentByMe: old.sentByMe,
            type: old.type,
            messageID: update.messageID ?? old.messageID,
            clientMessageID: update.clientMessageID ?? old.clientMessageID,
            isEdited: old.isEdited,
            editedAt: old.editedAt,
            isDeleted: update.isDeleted ?? true,
            deletedAt: old.deletedAt ?? DateManager.dateIntoIsoFormat(date: Date()),
            mediaUrl: old.mediaUrl,
            thumbnailUrl: old.thumbnailUrl,
            mediaID: old.mediaID,
            postID: old.postID,
            postOwnerID: old.postOwnerID,
            isSharedPost: old.isSharedPost,
            from: update.from ?? old.from,
            to: update.to ?? old.to,
            thumbnail: old.thumbnail,
            hasUploaded: old.hasUploaded,
            isUploading: old.isUploading,
            isRemotePDF: old.isRemotePDF,
            isURL: old.isURL,
            showDate: old.showDate,
            pdfData: old.pdfData
        )
    }
    
    private func findIndexInCachedMessages(messageID: String?, clientMessageID: String?) -> Int? {
        if let messageID, !messageID.isEmpty {
            if let index = privateMessagesList.firstIndex(where: { $0.messageID == messageID || $0.id == messageID }) {
                return index
            }
        }
        if let clientMessageID, !clientMessageID.isEmpty {
            if let index = privateMessagesList.firstIndex(where: { $0.clientMessageID == clientMessageID || $0.id == clientMessageID }) {
                return index
            }
        }
        return nil
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
