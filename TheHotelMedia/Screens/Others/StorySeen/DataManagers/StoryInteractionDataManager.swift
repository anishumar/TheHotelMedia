//
//  StoryInteractionDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 13/11/24.
//

import Foundation



class StoryInteractionDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getStoryViews(id: String, pageNo: Int) async throws -> GetStoryViewsResponse {
        
        guard let url = URL(string: "\(URL.getStoryViews)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<GetStoryViewsResponse>(url: url, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "5")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getStoryLikes(id: String, pageNo: Int) async throws -> GetStoryLikesResponse {
        
        guard let url = URL(string: "\(URL.getStoryLikes)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<GetStoryLikesResponse>(url: url, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "5")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
