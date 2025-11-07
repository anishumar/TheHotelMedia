//
//  SuggestionsDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 17/01/25.
//

import Foundation


class SuggestionsDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getSuggestion(pageNo: Int) async throws -> SuggestionResponse {
        
        let resource = Resource<SuggestionResponse>(url: .getSuggestions, method: .get([URLQueryItem(name: "documentLimit", value: "30"), URLQueryItem(name: "pageNumber", value: "\(pageNo)")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
