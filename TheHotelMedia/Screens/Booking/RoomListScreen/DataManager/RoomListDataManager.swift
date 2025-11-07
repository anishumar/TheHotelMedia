//
//  RoomListDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 20/02/25.
//

import Foundation


class RoomListDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func getRoomList() async throws -> GetAllRoomsResponse {
        
        let resource = Resource<GetAllRoomsResponse>(url: .allRooms, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
