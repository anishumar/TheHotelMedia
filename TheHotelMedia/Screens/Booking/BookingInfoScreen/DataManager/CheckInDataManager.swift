//
//  CheckInDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 20/02/25.
//

import Foundation


class CheckInDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func checkIn(paramters: [String: Any]) async throws -> CheckInResponse {
        
        let resource = Resource<CheckInResponse>(url: .bookingCheckIn, method: .post(paramters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
