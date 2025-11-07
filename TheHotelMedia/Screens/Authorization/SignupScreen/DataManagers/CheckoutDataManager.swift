//
//  CheckoutDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import SwiftUI


class CheckoutDataManager {
    
    @AppStorage("accessToken") var accessToken: String = ""
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getCheckoutDetails(parameters: [String: Any]) async throws -> CheckoutResponse {
        
        let headers = [
            "Content-Type": "application/json",
            "x-access-token": accessToken
        ]
        
        let resource = Resource<CheckoutResponse>(url: .checkout, headers: headers,  method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func buySubscription(parameters: [String: Any]) async throws -> SubscriptionResponse {
        
        let headers = [
            "Content-Type": "application/json",
            "x-access-token": accessToken
        ]
        
        let resource = Resource<SubscriptionResponse>(url: .buySubscription, headers: headers, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func validateTransaction(parameters: [String: Any]) async throws -> TransactionValidateResponse {
        
        let resource = Resource<TransactionValidateResponse>(url: .verifyIAPTransaction, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
