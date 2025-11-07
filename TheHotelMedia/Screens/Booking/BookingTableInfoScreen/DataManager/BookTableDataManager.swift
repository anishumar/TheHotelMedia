//
//  BookTableDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 02/04/25.
//

import Foundation


class BookTableDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func bookTable(parameters: [String: Any]) async throws -> BookTableResponse {
        
        let resource = Resource<BookTableResponse>(url: .bookTable, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
