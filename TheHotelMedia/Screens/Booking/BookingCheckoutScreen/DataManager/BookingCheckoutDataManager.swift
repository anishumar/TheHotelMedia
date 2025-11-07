//
//  BookingCheckoutDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 21/02/25.
//

import Foundation


class BookingCheckoutDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getCheckoutData(parameters: [String: Any]) async throws -> BookingCheckoutResponse {
        
        let resource = Resource<BookingCheckoutResponse>(url: .bookingCheckOut, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func confirmBooking(parameters: [String: Any]) async throws -> ConfirmBookingResponse {
        
        let resource = Resource<ConfirmBookingResponse>(url: .confirmBooking, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
