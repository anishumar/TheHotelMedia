//
//  BlockedUsersDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 08/11/24.
//

import Foundation


class BlockedUsersDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getBlockedUsers(pageNo: Int) async throws -> BlockedUsersResponse {
        
        let resource = Resource<BlockedUsersResponse>(url: .getBlockedUsers, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "10")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
