//
//  InsightDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 19/11/24.
//

import Foundation


class InsightDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getInsightData(filter: String) async throws -> GetInsightResponse {
        
        let resource = Resource<GetInsightResponse>(url: .getInsight, method: .get([URLQueryItem(name: "filter", value: filter)]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
