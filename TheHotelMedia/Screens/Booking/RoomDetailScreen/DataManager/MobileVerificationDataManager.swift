//
//  MobileVerificationDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 11/03/25.
//

import Foundation


class MobileVerificationDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func requestOtp(parameters: [String: Any]) async throws -> RequestMobileOTPResponse {
        
        let resource = Resource<RequestMobileOTPResponse>(url: .requestMobileNoVerifyOTP, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func verifyOtp(parameters: [String: Any]) async throws -> VerifyMobileOTPResponse {
        
        let resource = Resource<VerifyMobileOTPResponse>(url: .verifyMobileNoOTP, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
