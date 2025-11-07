//
//  SigninManager.swift
//  TheHotelMedia
//
//  Created by MAC on 20/09/24.
//

import Foundation


class SigninManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func login(parameters: [String: Any]) async throws -> LoginResponse {
        
        let resource = Resource<LoginResponse>(url: .signin, method: .post(parameters))
        
        do {
            let result = try await baseNetworkManager.load(resource)
            return result
            
        } catch {
            throw error
        }
    }
    
    
    func socialLogin(parameters: [String: Any]) async throws -> LoginResponse {
        
        let resource = Resource<LoginResponse>(url: .socialLogin, method: .post(parameters))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
