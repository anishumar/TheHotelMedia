//
//  JSONParsingManager.swift
//  TheHotelMedia
//
//  Created by MAC on 26/11/24.
//

import Foundation
import SwiftyJSON


class JSONSerializationManager {
    
    
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
                        let profilePicLarge = profilePic["large"] as? String
                        let profilePicMedium = profilePic["medium"] as? String
                        let profilePicSmall = profilePic["small"] as? String
                        
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
                            let profilePicLarge = profilePic["large"] as? String
                            let profilePicMedium = profilePic["medium"] as? String
                            let profilePicSmall = profilePic["small"] as? String
                            
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
                        let newMessage = message["message"] as? String
                        let type = message["type"] as? String
                        let mediaUrl = message["mediaUrl"] as? String
                        let thumbnailUrl = message["thumbnailUrl"] as? String
                        
                        array.append(PrivateMessage(id: id, createdAt: createdAt, isSeen: isSeen, content: newMessage, sentByMe: sentByMe, type: type, mediaUrl: mediaUrl, thumbnailUrl: thumbnailUrl))
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
        
        if let singleMessage = data.first as? [String: Any] {
            let from = singleMessage["from"] as? String
            let to = singleMessage["to"] as? String
            let time = singleMessage["time"] as? String
            let isSeen = singleMessage["isSeen"] as? Int
            
            if let message = singleMessage["message"] as? [String: Any] {
                let content = message["message"] as? String
                let type = message["type"] as? String
                let mediaUrl = message["mediaUrl"] as? String
                let thumbnailUrl = message["thumbnailUrl"] as? String
                
                return PrivateMessage(id: UUID().uuidString, createdAt: time, isSeen: isSeen, content: content, sentByMe: 0, type: type, mediaUrl: mediaUrl, thumbnailUrl: thumbnailUrl, from: from, to: to)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
