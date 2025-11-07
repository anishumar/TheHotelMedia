//
//  RoomDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 20/02/25.
//

import Foundation


class RoomDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getRoomData(id: String) async throws -> RoomDataResponse {
        
        guard let url = URL(string: "\(URL.fetchRoomData.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<RoomDataResponse>(url: url, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
