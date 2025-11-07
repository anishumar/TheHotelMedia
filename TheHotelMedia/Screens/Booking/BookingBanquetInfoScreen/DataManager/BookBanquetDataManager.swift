//
//  BookBanquetDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 02/04/25.
//

import Foundation


class BookBanquetDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func bookBanquet(parameters: [String: Any]) async throws -> BookBanquetResponse {
        
        let resource = Resource<BookBanquetResponse>(url: .bookBanquet, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
