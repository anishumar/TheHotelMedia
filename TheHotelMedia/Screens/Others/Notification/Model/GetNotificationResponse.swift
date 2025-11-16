//
//  GetNotificationResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 23/10/24.
//

import Foundation


// MARK: - GetNotificationResponse
struct GetNotificationResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [NotificationModel]?
    let pageNo, totalPages, totalResources: Int?
}

// MARK: - NotificationModel
struct NotificationModel: Codable, Identifiable, Hashable {
    let id: String?
    let isSeen: Bool?
    let userID: String?
    let title: String?
    let description: String?
    let type: String?
    let metadata: Metadata?
    let createdAt: String?
    let usersRef: UsersRef?
    let isConnected, isRequested: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case isSeen, userID, title, description, type, metadata, createdAt, usersRef, isConnected, isRequested
    }
}

// MARK: - Metadata
struct Metadata: Codable, Hashable {
    let connectionID, userID, postID, message, postType, jobID, type, bookingID: String?
    let commentID: String?
}

struct CollaborationRespondResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}

struct CollaborationInviteResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}

// MARK: - GetAllCollaborationsResponse
struct GetAllCollaborationsResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [CollaborationData]?
}

// MARK: - CollaborationData
struct CollaborationData: Codable, Identifiable {
    let id: String?
    let userID: CollaborationUserRef?
    let collaborators: [CollaborationUserRef]?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userID
        case collaborators
    }
}

// MARK: - CollaborationUserRef
struct CollaborationUserRef: Codable, Identifiable {
    let id: String?
    let name: String?
    let profilePic: ProfilePic?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case profilePic
    }
}

// MARK: - GetCollaboratorsResponse
struct GetCollaboratorsResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [CollaborationUserRef]?
}


enum CollaborationStatus {
    case pending
    case accepted
    case rejected
}


extension NotificationModel {
    
    var isCollaborationInvite: Bool {
        // Check type field
        if let type = type {
            let lowerType = type.lowercased()
            
            // Check for various collaboration invite type patterns
            if lowerType.contains("collaboration") || lowerType.contains("collab") || lowerType.contains("invite") {
                print("🔍 [NOTIF CHECK] ✅ Found collaboration in type: '\(type)'")
                return true
            }
        }
        
        // Check metadata type
        if let metadataType = metadata?.type?.lowercased() {
            if metadataType.contains("collaboration") || metadataType.contains("collab") || metadataType.contains("invite") {
                print("🔍 [NOTIF CHECK] ✅ Found collaboration in metadata.type: '\(metadata?.type ?? "N/A")'")
                return true
            }
        }
        
        // Check title for collaboration-related text
        if let title = title?.lowercased() {
            if title.contains("collaboration") || title.contains("collab") || title.contains("invite") {
                print("🔍 [NOTIF CHECK] ✅ Found collaboration in title: '\(self.title ?? "N/A")'")
                return true
            }
        }
        
        // Check description for collaboration-related text
        if let description = description?.lowercased() {
            if description.contains("collaboration") || description.contains("collab") || description.contains("invite") {
                print("🔍 [NOTIF CHECK] ✅ Found collaboration in description: '\(self.description ?? "N/A")'")
                return true
            }
        }
        
        // Check if metadata has postID (collaboration invites typically have postID in metadata)
        if let metadata = metadata, metadata.postID != nil {
            // If it has postID and type/invite keywords, it might be a collaboration invite
            let typeLower = (type ?? "").lowercased()
            let metaTypeLower = (metadata.type ?? "").lowercased()
            if typeLower.contains("invite") || metaTypeLower.contains("invite") {
                print("🔍 [NOTIF CHECK] ✅ Found postID in metadata with invite keyword: postID=\(metadata.postID ?? "N/A")")
                return true
            }
        }
        
        return false
    }
    
    var collaborationStatus: CollaborationStatus {
        if let metadataType = metadata?.type?.lowercased() {
            if metadataType.contains("accept") {
                return .accepted
            } else if metadataType.contains("reject") || metadataType.contains("decline") {
                return .rejected
            } else if metadataType.contains("pending") {
                return .pending
            }
        }
        
        if let type = type?.lowercased() {
            if type.contains("accept") {
                return .accepted
            } else if type.contains("reject") || type.contains("decline") {
                return .rejected
            }
        }
        
        if let description = description?.lowercased() {
            if description.contains("accepted") {
                return .accepted
            } else if description.contains("declined") || description.contains("rejected") {
                return .rejected
            }
        }
        
        return .pending
    }
}

// MARK: - UsersRef
struct UsersRef: Codable, Hashable {
    let id: String?
    let accountType: String?
    let profilePic: ProfilePic?
    let username, name, phoneNumber, dialCode, email: String?
    let businessProfileRef: BusinessProfileRef?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case accountType, profilePic, username, name, businessProfileRef, dialCode, phoneNumber, email
    }
}
