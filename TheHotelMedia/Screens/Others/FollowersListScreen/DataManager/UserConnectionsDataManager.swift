//
//  UserConnectionsDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 22/10/24.
//

import Foundation


class UserConnectionsDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func getfollowers(id: String, pageNo: Int) async throws -> GetFollowersResponse {
        
        guard let url = URL(string: "\(URL.getFollowers.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<GetFollowersResponse>(url: url, method: .get([URLQueryItem(name: "documentLimit", value: "30"), URLQueryItem(name: "pageNumber", value: "\(pageNo)")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getfollowing(id: String, pageNo: Int) async throws -> GetFollowingResponse {
        
        guard let url = URL(string: "\(URL.getFollowing.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<GetFollowingResponse>(url: url, method: .get([URLQueryItem(name: "documentLimit", value: "30"), URLQueryItem(name: "pageNumber", value: "\(pageNo)")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func followUser(id: String) async throws -> FollowResponse {
        
        guard let url = URL(string: URL.follow.absoluteString + id) else { throw NetworkError.badURL }
        
        let resource = Resource<FollowResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func unFollowUser(id: String) async throws -> UnfollowResponse {
        
        guard let url = URL(string: URL.unfollow.absoluteString + id) else { throw NetworkError.badURL }
        
        let resource = Resource<UnfollowResponse>(url: url, method: .delete)
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
