//
//  PostDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 10/10/24.
//

import Foundation


class PostDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func likeAPost(postID: String) async throws -> PostLikedResponse {
        
        guard let url = URL(string: "\(URL.likeAPost)\(postID)") else { throw NetworkError.badURL }
        
        let resource = Resource<PostLikedResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func saveAPost(postID: String) async throws -> PostSavedResponse {
        
        guard let url = URL(string: "\(URL.saveAPost)\(postID)") else { throw NetworkError.badURL }
        
        let resource = Resource<PostSavedResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    func joinEvent(postID: String) async throws -> EventJoinResponse {
        
        let resource = Resource<EventJoinResponse>(url: .joinEvent, method: .post(["postID": postID]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    func reportPost(id: String) async throws -> ReportPostResponse {
        
        guard let url = URL(string: "\(URL.reportPost)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<ReportPostResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func deletePost(postID: String) async throws -> DeletePostResponse {
        
        guard let url = URL(string: "\(URL.deletePost)\(postID)/soft") else { throw NetworkError.badURL }
        
        let resource = Resource<DeletePostResponse>(url: url, method: .delete)
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
        
    }
    
    
    func increasePostViews(array: [String]) async throws -> PostViewsReponse {
        
        let resource = Resource<PostViewsReponse>(url: .increasePostViews, method: .post(["postIDs": array]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    func publishPostAsStory(postID: String) async throws -> PostStoryResponse {
        
        guard let url = URL(string: "\(URL.publishPostAsStory)\(postID)/publish-as-story") else { throw NetworkError.badURL }
        
        let resource = Resource<PostStoryResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
}
