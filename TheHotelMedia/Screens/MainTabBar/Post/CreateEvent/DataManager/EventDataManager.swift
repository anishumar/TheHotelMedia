//
//  EventDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 09/10/24.
//

import UIKit


class EventDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func postEvent(image: UIImage, parameters: [String: Any]) async throws -> CreateEventResponse {
        
        let resource = Resource<CreateEventResponse>(url: .createEvent, method: .createEvent(image, parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
