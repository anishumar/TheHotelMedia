//
//  BusinessSignupManager.swift
//  TheHotelMedia
//
//  Created by MAC on 24/09/24.
//

import Foundation


class BusinessSignupManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func businessSignup(parameters: [String: Any]) async throws -> BusinessSignupResponse {
        
        let resource = Resource<BusinessSignupResponse>(url: .signup, method: .post(parameters))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
