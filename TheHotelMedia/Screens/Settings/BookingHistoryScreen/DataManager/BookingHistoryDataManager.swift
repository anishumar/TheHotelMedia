//
//  BookingHistoryDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 04/03/25.
//

import Foundation


class BookingHistoryDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    
    func getBookingHistory(pageNo: Int) async throws -> BookingHistoryResponse {
        
        let resource = Resource<BookingHistoryResponse>(url: .bookingHistory, method: .get([URLQueryItem(name: "pageNo", value: "\(pageNo)")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
