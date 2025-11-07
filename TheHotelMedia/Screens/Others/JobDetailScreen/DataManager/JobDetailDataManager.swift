//
//  JobDetailDatamanager.swift
//  TheHotelMedia
//
//  Created by MAC on 08/04/25.
//

import Foundation


class JobDetailDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func getJobDetailData(jobID: String) async throws -> JobDetailResponse {
        
        guard !jobID.isEmpty else { throw NetworkError.badURL }
        
        guard let url = URL(string: "\(URL.getJobDetail.absoluteString)\(jobID)") else { throw NetworkError.badURL }
        
        let resource = Resource<JobDetailResponse>(url: url, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
