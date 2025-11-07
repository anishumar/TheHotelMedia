//
//  EventDetailDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 07/11/24.
//

import Foundation


class EventDetailDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getSinglePost(id: String) async throws -> GetPostResponse {
        
        guard let url = URL(string: "\(URL.getSinglePost.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<GetPostResponse>(url: url, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func joinEvent(postID: String) async throws -> EventJoinResponse {
        
        let resource = Resource<EventJoinResponse>(url: .joinEvent, method: .post(["postID": postID]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func saveAPost(postID: String) async throws -> PostSavedResponse {
        
        guard let url = URL(string: "\(URL.saveAPost)\(postID)") else { throw NetworkError.badURL }
        
        let resource = Resource<PostSavedResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
}
