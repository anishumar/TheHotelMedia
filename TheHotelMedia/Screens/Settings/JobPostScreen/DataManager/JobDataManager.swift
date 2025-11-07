//
//  JobDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 07/04/25.
//

import Foundation


class JobDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func createJobPost(parameters: [String: Any]) async throws -> CreateJobPostResponse {
        
        let resource = Resource<CreateJobPostResponse>(url: .createJobPost, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
