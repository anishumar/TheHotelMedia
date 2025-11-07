//
//  OtpDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 20/09/24.
//

import Foundation


class OtpDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func verifyOtp(parameters: [String: Any]) async throws -> OtpVerifyResponse {
        
        let resource = Resource<OtpVerifyResponse>(url: .emailVerify, method: .post(parameters))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
    
    
    func verifyForgotPasswordOtp(parameters: [String: Any]) async throws -> ForgotPasswordOtpVerifyResponse {
        
        let resource = Resource<ForgotPasswordOtpVerifyResponse>(url: .forgotPasswordOtpVerify, method: .post(parameters))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
        
    }
    
    
    func resendOtp(parameters: [String: Any]) async throws -> OtpResendResponse {
        
        let resource = Resource<OtpResendResponse>(url: .resendOTP, method: .post(parameters))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
