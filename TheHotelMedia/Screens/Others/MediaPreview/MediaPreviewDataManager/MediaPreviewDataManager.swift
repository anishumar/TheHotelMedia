//
//  MediaPreviewDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 08/01/25.
//

import Foundation


class MediaPreviewDataManager {
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func viewMedia(parameters: [String: Any]) async throws -> ViewMediaResponse {
        
        let resource = Resource<ViewMediaResponse>(url: .viewMedia, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
