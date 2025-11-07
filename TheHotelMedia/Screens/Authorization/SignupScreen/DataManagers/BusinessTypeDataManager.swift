//
//  BusinessTypeDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 23/09/24.
//

import UIKit


class BusinessTypeDataManager {
    
    let baseNetworkManager = BaseNetworkManager()
    
    
    func getBusinessType() async throws -> BusinessTypeResponse {
        let resource = Resource<BusinessTypeResponse>(url: .getBusinessTypes, method: .get([]))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
