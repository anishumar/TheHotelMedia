//
//  BusinessSubTypeDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 23/09/24.
//

import Foundation


class BusinessSubTypeDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getBusinessSubType(id: String) async throws -> BusinessSubTypeResponse {
        
        let string = URL.getBusinessSubTypes.absoluteString
        let resource = Resource<BusinessSubTypeResponse>(url: URL(string: "\(string)/\(id)")!, method: .get([]))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
