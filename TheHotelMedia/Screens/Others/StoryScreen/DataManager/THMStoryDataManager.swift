//
//  THMStoryDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 12/11/24.
//

import Foundation


class THMStoryDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func deleteStory(id: String) async throws -> DeleteStoryResponse {
        
        guard let url = URL(string: "\(URL.deleteStory.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<DeleteStoryResponse>(url: url, method: .delete)
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func viewStory(id: String) async throws -> ViewStoryResponse {
        
        guard let url = URL(string: "\(URL.viewedStory.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<ViewStoryResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func likeStory(id: String) async throws -> LikeStoryResponse {
        
        guard let url = URL(string: "\(URL.likeStory.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<LikeStoryResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
