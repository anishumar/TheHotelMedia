//
//  SubscriptionPlanManager.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import Foundation


class SubscriptionPlanManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getPlans() async throws -> SubscriptionPlanResponse {
        
        let resource = Resource<SubscriptionPlanResponse>(url: .getPlans, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getActiveSubscription() async throws -> GetActiveSubscriptionResponse {
        
        let resource = Resource<GetActiveSubscriptionResponse>(url: .getActiveSubscription, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func cancelSubscription() async throws -> CancelSubscriptionResponse {
        
        let resource = Resource<CancelSubscriptionResponse>(url: .cancelSubscription, method: .delete)
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
