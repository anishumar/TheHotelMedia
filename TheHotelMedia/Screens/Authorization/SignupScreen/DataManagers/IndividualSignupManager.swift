//
//  IndividualLoginManager.swift
//  TheHotelMedia
//
//  Created by MAC on 19/09/24.
//

import Foundation


class IndividualSignupManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func createAccount(parameters: [String: Any]) async throws -> NewAccountResponse {
        
        let resource = Resource<NewAccountResponse>(url: .signup, method: .post(parameters))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
