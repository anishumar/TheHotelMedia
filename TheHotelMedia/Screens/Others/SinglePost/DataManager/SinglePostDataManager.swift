//
//  SinglePostDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 05/12/24.
//

import Foundation


class SinglePostDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func postShared(postID: String, sharedByID: String) async throws -> SharedPostResponse {
        
        let resource = Resource<SharedPostResponse>(url: .postShared, method: .get([URLQueryItem(name: "postID", value: postID), URLQueryItem(name: "userID", value: sharedByID)]))
        
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getSinglePost(id: String) async throws -> GetPostResponse {
        
        guard let url = URL(string: "\(URL.getSinglePost.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<GetPostResponse>(url: url, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
