//
//  ReportDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 04/12/24.
//

import Foundation


class ReportDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func reportProfile(id: String, parameters: [String: Any]) async throws -> ReportProfileResponse {
        guard let url = URL(string: "\(URL.reportUser.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<ReportProfileResponse>(url: url, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func reportPost(id: String, parameters: [String: Any]) async throws -> ReportPostResponse {
        
        guard let url = URL(string: "\(URL.reportPost)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<ReportPostResponse>(url: url, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    func reportComment(id: String, parameters: [String: Any]) async throws -> ReportCommentResponse {
        
        guard let url = URL(string: "\(URL.reportComment)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<ReportCommentResponse>(url: url, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
