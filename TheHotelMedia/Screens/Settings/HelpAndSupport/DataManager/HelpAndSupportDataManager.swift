//
//  HelpAndSupportDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 25/10/24.
//

import Foundation


class HelpAndSupportDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func getFaqs(pageNo: Int, query: String, type: String) async throws -> FaqResponse {
        
        let resource = Resource<FaqResponse>(url: .getFaqs, method: .get([
            URLQueryItem(name: "pageNumber", value: "\(pageNo)"),
            URLQueryItem(name: "documentLimit", value: "10"),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "type", value: type)
        ]))
        
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
    
    
    func contactUs(parameters: [String: Any]) async throws -> ContactUsResponse {
        let resource = Resource<ContactUsResponse>(url: .contactUs, method: .post(parameters))
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
