//
//  OtpForgotPasswordManager.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import Foundation


class OtpForgotPasswordManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getOtpForgotPassword(parameters: [String: Any]) async throws -> ForgotPasswordResponse {
        
        let resource = Resource<ForgotPasswordResponse>(url: .forgotPassword, method: .post(parameters))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
