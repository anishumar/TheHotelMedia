//
//  NotificationDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 23/10/24.
//

import Foundation


class NotificationDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func getNotifications(pageNo: Int) async throws -> GetNotificationResponse {
        
        let resource = Resource<GetNotificationResponse>(url: .getNotifications, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func acceptFollowRequest(id: String) async throws -> AcceptFollowResponse {
        
        guard let url = URL(string: URL.acceptFollowRequest.absoluteString + id) else { throw NetworkError.badURL }
        
        let resource = Resource<AcceptFollowResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func rejectFollowRequest(id: String) async throws -> RejectFollowResponse {
        
        guard let url = URL(string: URL.rejectFollowRequest.absoluteString + id) else { throw NetworkError.badURL }
        
        let resource = Resource<RejectFollowResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func followBackUser(id: String) async throws -> FollowResponse {
        
        guard let url = URL(string: URL.followback.absoluteString + id) else { throw NetworkError.badURL }
        
        let resource = Resource<FollowResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getNotificationStatus() async throws -> NotificationStatusResponse {
        let resource = Resource<NotificationStatusResponse>(url: URL.notificationStatus, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
