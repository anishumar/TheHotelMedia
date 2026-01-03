//
//  BookingSummaryDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 04/03/25.
//

import Foundation


class BookingSummaryDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getBookingSummary(id: String) async throws -> BookingSummaryResponse {
        
        guard let url = URL(string: "\(URL.bookingSummary.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<BookingSummaryResponse>(url: url, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getBookingInvoicePath(id: String) async throws -> DownloadInvoiceResponse {
        
        guard let url = URL(string: "\(URL.bookingInvoice.absoluteString)\(id)/invoice") else { throw NetworkError.badURL }
        
        let resource = Resource<DownloadInvoiceResponse>(url: url, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func cancelBooking(id: String) async throws -> CancelBookingResponse {
        
        // Dedicated user cancel endpoint:
        // DELETE /api/v1/bookings/user/cancel/:id
        guard let url = URL(string: "\(URL.cancelBookingUser.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<CancelBookingResponse>(url: url, method: .delete)
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func bookingAction(isAccepted: Bool, bookingID: String) async throws -> BookingActionResponse {
        
        guard let url = URL(string: "\(URL.bookingAction.absoluteString)\(bookingID)/change-status") else { throw NetworkError.badURL }
        
        let resource = Resource<BookingActionResponse>(url: url, method: .patch(["status": isAccepted ? "confirmed" : "canceled by business"]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
