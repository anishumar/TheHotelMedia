//
//  CollaborationResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 07/02/25.
//

import Foundation


struct InviteCollaboratorResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}

struct RespondCollaborationResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
}

struct GetCollaborationsResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [CollaborationData]?
}

struct CollaborationData: Codable, Identifiable {
    let id: String
    let userID: CollaborationUser?
    let collaborators: [CollaborationUser]?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userID
        case collaborators
    }
}

struct CollaborationUser: Codable {
    let name: String?
    let profilePic: String?
}

struct GetCollaboratorsResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: [CollaboratorProfile]?
}

struct CollaboratorProfile: Codable, Identifiable {
    let id: String
    let name: String?
    let profilePic: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case profilePic
    }
}

