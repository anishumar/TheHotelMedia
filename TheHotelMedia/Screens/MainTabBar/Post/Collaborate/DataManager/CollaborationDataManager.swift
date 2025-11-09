//
//  CollaborationDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 07/02/25.
//

import Foundation


class CollaborationDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func inviteCollaborator(postID: String, invitedUserID: String) async throws -> InviteCollaboratorResponse {
        let parameters: [String: Any] = [
            "postID": postID,
            "invitedUserID": invitedUserID
        ]
        
        let resource = Resource<InviteCollaboratorResponse>(url: .inviteCollaborator, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    func respondCollaboration(postID: String, action: String) async throws -> RespondCollaborationResponse {
        let parameters: [String: Any] = [
            "postID": postID,
            "action": action
        ]
        
        let resource = Resource<RespondCollaborationResponse>(url: .respondCollaboration, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    func getCollaborations() async throws -> GetCollaborationsResponse {
        let resource = Resource<GetCollaborationsResponse>(url: .getCollaborations, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    func getCollaborators(postID: String) async throws -> GetCollaboratorsResponse {
        // URL format: /collaboration/:postID/collaborators
        let urlString = URL.default + "/collaboration/\(postID)/collaborators"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(urlString)"])
        }
        let resource = Resource<GetCollaboratorsResponse>(url: url, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}

