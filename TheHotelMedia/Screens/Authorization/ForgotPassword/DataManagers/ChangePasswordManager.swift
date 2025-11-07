//
//  ChangePasswordManager.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import Foundation


class ChangePasswordManager {
    
    let baseNetworkmanager = BaseNetworkManager.shared
    
    func changePassword(parameters: [String: Any]) async throws -> ChangePasswordResponse {
        
        let resource = Resource<ChangePasswordResponse>(url: .changePassword, method: .post(parameters))
        
        let result = try await baseNetworkmanager.load(resource)
        
        return result
    }
}
