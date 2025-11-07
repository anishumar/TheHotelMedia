//
//  IndividualProfilePicDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 23/09/24.
//

import UIKit

class IndividualProfilePicDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func uploadProfilePic(uiImage: UIImage, parameters: [String: Any] ) async throws -> IndividualProfilePicResponse {
        let resource = Resource<IndividualProfilePicResponse>(url: .profilePic, method: .postImage(uiImage, parameters))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
