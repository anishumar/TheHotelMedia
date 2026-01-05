//
//  JSONParsingManager.swift
//  TheHotelMedia
//
//  Created by MAC on 26/11/24.
//

import Foundation
import SwiftyJSON


class JSONSerializationManager {
    
    private static func boolValue(_ any: Any?) -> Bool? {
        if let b = any as? Bool { return b }
        if let i = any as? Int { return i != 0 }
        if let s = any as? String {
            if s == "1" { return true }
            if s == "0" { return false }
            if s.lowercased() == "true" { return true }
            if s.lowercased() == "false" { return false }
        }
        return nil
    }
    
    private static func normalizedURLString(_ raw: String?) -> String? {
        guard var raw, !raw.isEmpty else { return nil }
        // Some environments return `staging.thehotelmedia.com` URLs which currently fail TLS trust
        // (cert mismatch). We normalize to the API host used elsewhere in the app.
        raw = raw.replacingOccurrences(of: "https://staging.thehotelmedia.com", with: "https://api.thehotelmedia.com")
        raw = raw.replacingOccurrences(of: "http://staging.thehotelmedia.com", with: "https://api.thehotelmedia.com")
        return raw
    }
    
    
    static func getUserList(data: [Any]) -> [ChatUser]? {
        
        var array: [ChatUser] = []
        
        guard !data.isEmpty else { return nil }
        
        if let firstItem = data.first as? NSArray {
            
            for user in firstItem {
                if let user = user as? [String: Any] {
                    let id = user["_id"] as? String
                    let userID = user["userID"] as? String
                    let isOnline = user["isOnline"] as? Int
                    let name = user["name"] as? String
                    let username = user["username"] as? String
                    
                    if let profilePic = user["profilePic"] as? [String: Any] {
                        let profilePicLarge = normalizedURLString(profilePic["large"] as? String)
                        let profilePicMedium = normalizedURLString(profilePic["medium"] as? String)
                        let profilePicSmall = normalizedURLString(profilePic["small"] as? String)
                        
                        array.append(ChatUser(id: id, userID: userID, isOnline: isOnline, name: name, profilePic: ProfilePic(small: profilePicSmall, medium: profilePicMedium, large: profilePicLarge), username: username))
                    } else {
                        array.append(ChatUser(id: id, userID: userID, isOnline: isOnline, name: name, profilePic: nil, username: username))
                    }
                } else {
                    return nil
                }
            }
            
            return array
            
        } else {
            return nil
        }
    }
    
    
    static func getRecentChatList(data: [Any]) -> ([RecentChat]?, Int?, Int?) {
        
        var array: [RecentChat] = []
        var pageNumber = 1
        var totalPages = 1
        
        guard !data.isEmpty else { return (nil, nil, nil) }
        
        if let firstItem = data.first as? [String: Any] {
            
            if let messages = firstItem["messages"] as? NSArray {
                
                for message in messages {
                    if let message = message as? [String: Any] {
                        let createdAt = message["createdAt"] as? String
                        let isSeen = message["isSeen"] as? Int
                        let unseenCount = message["unseenCount"] as? Int
                        let lookupID = message["lookupID"] as? String
                        let newMessage = message["message"] as? String
                        let name = message["name"] as? String
                        let type = message["type"] as? String
                        let username = message["username"] as? String
                        
                        if let profilePic = message["profilePic"] as? [String: Any] {
                            let profilePicLarge = normalizedURLString(profilePic["large"] as? String)
                            let profilePicMedium = normalizedURLString(profilePic["medium"] as? String)
                            let profilePicSmall = normalizedURLString(profilePic["small"] as? String)
                            
                            array.append(RecentChat(id: lookupID, createdAt: createdAt, isSeen: isSeen, message: newMessage, name: name, profilePic: ProfilePic(small: profilePicSmall, medium: profilePicMedium, large: profilePicLarge), type: type, unseenCount: unseenCount, username: username))
                        } else {
                            array.append(RecentChat(id: lookupID, createdAt: createdAt, isSeen: isSeen, message: newMessage, name: name, profilePic: nil, type: type, unseenCount: unseenCount, username: username))
                        }
                    }
                }
                
                if let pageNo = firstItem["pageNo"] as? Int {
                    pageNumber = pageNo
                }
                
                if let totalPagesNo = firstItem["totalPages"] as? Int {
                    totalPages = totalPagesNo
                }
                
                return (array, pageNumber, totalPages)
            } else {
                return (nil, nil, nil)
            }
        } else {
            return (nil, nil, nil)
        }
    }
    
    
    static func getPrivateMessagesList(data: [Any]) -> ([PrivateMessage]?, Int?, Int?) {
        
        var array: [PrivateMessage] = []
        var pageNumber = 1
        var totalPages = 1
        
        guard !data.isEmpty else { return (nil, nil, nil) }
        
        if let firstItem = data.first as? [String: Any] {
            
            if let messages = firstItem["messages"] as? NSArray {
                
                for message in messages {
                    if let message = message as? [String: Any] {
                        let id = message["_id"] as? String
                        let createdAt = message["createdAt"] as? String
                        let isSeen = message["isSeen"] as? Int
                        let sentByMe = message["sentByMe"] as? Int
                        
                        // Backend variants:
                        // - message: "text", type: "text"
                        // - message: { message: "text", type: "text", ... }
                        var newMessage: String? = nil
                        var type: String? = nil
                        var mediaUrl: String? = normalizedURLString(message["mediaUrl"] as? String)
                        var thumbnailUrl: String? = normalizedURLString(message["thumbnailUrl"] as? String)
                        var mediaID: String? = message["mediaID"] as? String
                        var postID: String? = message["postID"] as? String
                        var postOwnerID: String? = message["postOwnerID"] as? String
                        let topLevelIsSharedPost = boolValue(message["isSharedPost"])
                        var nestedClientMessageID: String? = nil
                        var nestedMessageID: String? = nil
                        var nestedIsSharedPost: Bool? = nil
                        
                        if let nested = message["message"] as? [String: Any] {
                            newMessage = nested["message"] as? String
                            type = nested["type"] as? String ?? message["type"] as? String
                            mediaUrl = normalizedURLString(nested["mediaUrl"] as? String) ?? mediaUrl
                            thumbnailUrl = normalizedURLString(nested["thumbnailUrl"] as? String) ?? thumbnailUrl
                            mediaID = (nested["mediaID"] as? String) ?? mediaID
                            postID = (nested["postID"] as? String) ?? postID
                            postOwnerID = (nested["postOwnerID"] as? String) ?? postOwnerID
                            nestedIsSharedPost = boolValue(nested["isSharedPost"])
                            nestedClientMessageID = nested["clientMessageID"] as? String
                            nestedMessageID = nested["_id"] as? String ?? nested["messageID"] as? String
                        } else {
                            newMessage = message["message"] as? String
                            type = message["type"] as? String ?? message["messageType"] as? String
                        }
                        
                        let clientMessageID = (message["clientMessageID"] as? String) ?? nestedClientMessageID
                        let isEdited = boolValue(message["isEdited"])
                        let editedAt = message["editedAt"] as? String
                        let isDeleted = boolValue(message["isDeleted"])
                        let deletedAt = message["deletedAt"] as? String
                        
                        array.append(
                            PrivateMessage(
                                id: id,
                                createdAt: createdAt,
                                isSeen: isSeen,
                                content: newMessage,
                                sentByMe: sentByMe,
                                type: type,
                                messageID: id ?? nestedMessageID,
                                clientMessageID: clientMessageID,
                                isEdited: isEdited,
                                editedAt: editedAt,
                                isDeleted: isDeleted,
                                deletedAt: deletedAt,
                                mediaUrl: mediaUrl,
                                thumbnailUrl: thumbnailUrl,
                                mediaID: mediaID,
                                postID: postID,
                                postOwnerID: postOwnerID,
                                isSharedPost: nestedIsSharedPost ?? topLevelIsSharedPost
                            )
                        )
                    }
                }
                
                if let pageNo = firstItem["pageNo"] as? Int {
                    pageNumber = pageNo
                }
                
                if let totalPagesNo = firstItem["totalPages"] as? Int {
                    totalPages = totalPagesNo
                }
                
                return (array, pageNumber, totalPages)
            } else {
                return (nil, nil, nil)
            }
        } else {
            return (nil, nil, nil)
        }
    }
    
    
    static func getSingleMessage(data: [Any]) -> PrivateMessage? {
        
        guard !data.isEmpty else { return nil }
        
        guard let singleMessage = data.first as? [String: Any] else { return nil }
        
        let from = singleMessage["from"] as? String
        let to = singleMessage["to"] as? String
        let time = singleMessage["time"] as? String
        let isSeen = singleMessage["isSeen"] as? Int
        
        // Backend variants we support:
        // - { message: { message, type, ... }, messageID, clientMessageID, isEdited, editedAt, isDeleted }
        // - { message: "text", type: "text", ... } (flat)
        let topLevelMessageID = singleMessage["messageID"] as? String ?? singleMessage["_id"] as? String
        let topLevelClientMessageID = singleMessage["clientMessageID"] as? String
        let topLevelIsEdited = boolValue(singleMessage["isEdited"])
        let topLevelEditedAt = singleMessage["editedAt"] as? String
        let topLevelIsDeleted = boolValue(singleMessage["isDeleted"])
        let topLevelDeletedAt = singleMessage["deletedAt"] as? String
        
        var content: String? = nil
        var type: String? = nil
        var mediaUrl: String? = nil
        var thumbnailUrl: String? = nil
        var nestedClientMessageID: String? = nil
        var mediaID: String? = singleMessage["mediaID"] as? String
        var postID: String? = singleMessage["postID"] as? String
        var postOwnerID: String? = singleMessage["postOwnerID"] as? String
        let topLevelIsSharedPost = boolValue(singleMessage["isSharedPost"])
        var nestedIsSharedPost: Bool? = nil
        
        if let message = singleMessage["message"] as? [String: Any] {
            content = message["message"] as? String
            type = message["type"] as? String
            mediaUrl = normalizedURLString(message["mediaUrl"] as? String)
            thumbnailUrl = normalizedURLString(message["thumbnailUrl"] as? String)
            mediaID = (message["mediaID"] as? String) ?? mediaID
            postID = (message["postID"] as? String) ?? postID
            postOwnerID = (message["postOwnerID"] as? String) ?? postOwnerID
            nestedIsSharedPost = boolValue(message["isSharedPost"])
            // Backend sometimes uses `tempMessageID` instead of `clientMessageID`
            nestedClientMessageID = (message["clientMessageID"] as? String) ?? (message["tempMessageID"] as? String)
            // Some backends embed the Mongo `_id` inside message object
            if topLevelMessageID == nil {
                // keep topLevelMessageID unchanged if already present
            }
        } else {
            content = singleMessage["message"] as? String
            type = singleMessage["type"] as? String
            mediaUrl = normalizedURLString(singleMessage["mediaUrl"] as? String)
            thumbnailUrl = normalizedURLString(singleMessage["thumbnailUrl"] as? String)
        }
        
        // Attempt nested `_id` / messageID when top-level isn't present
        var resolvedMessageID: String? = topLevelMessageID
        if resolvedMessageID == nil, let message = singleMessage["message"] as? [String: Any] {
            resolvedMessageID = message["_id"] as? String ?? message["messageID"] as? String
        }
        
        let resolvedClientMessageID = topLevelClientMessageID ?? nestedClientMessageID
        let resolvedID = resolvedMessageID ?? resolvedClientMessageID ?? UUID().uuidString
        
        return PrivateMessage(
            id: resolvedID,
            createdAt: time,
            isSeen: isSeen,
            content: content,
            sentByMe: 0,
            type: type,
            messageID: resolvedMessageID,
            clientMessageID: resolvedClientMessageID,
            isEdited: topLevelIsEdited,
            editedAt: topLevelEditedAt,
            isDeleted: topLevelIsDeleted,
            deletedAt: topLevelDeletedAt,
            mediaUrl: mediaUrl,
            thumbnailUrl: thumbnailUrl,
            mediaID: mediaID,
            postID: postID,
            postOwnerID: postOwnerID,
            isSharedPost: nestedIsSharedPost ?? topLevelIsSharedPost,
            from: from,
            to: to
        )
    }
    
    // MARK: - Message edit/delete socket updates
    
    static func getEditMessageUpdate(data: [Any]) -> SocketMessageEditUpdate? {
        guard !data.isEmpty else { return nil }
        guard let payload = data.first as? [String: Any] else { return nil }
        
        let messageID = payload["messageID"] as? String
        let clientMessageID = payload["clientMessageID"] as? String
        let message = payload["message"] as? String
        let isEdited = boolValue(payload["isEdited"])
        let editedAt = payload["editedAt"] as? String
        let from = payload["from"] as? String
        let to = payload["to"] as? String
        
        return SocketMessageEditUpdate(
            messageID: messageID,
            clientMessageID: clientMessageID,
            message: message,
            isEdited: isEdited,
            editedAt: editedAt,
            from: from,
            to: to
        )
    }
    
    static func getDeleteMessageUpdate(data: [Any]) -> SocketMessageDeleteUpdate? {
        guard !data.isEmpty else { return nil }
        guard let payload = data.first as? [String: Any] else { return nil }
        
        let messageID = payload["messageID"] as? String
        let clientMessageID = payload["clientMessageID"] as? String
        let isDeleted = boolValue(payload["isDeleted"])
        let from = payload["from"] as? String
        let to = payload["to"] as? String
        
        return SocketMessageDeleteUpdate(
            messageID: messageID,
            clientMessageID: clientMessageID,
            isDeleted: isDeleted,
            from: from,
            to: to
        )
    }
}
