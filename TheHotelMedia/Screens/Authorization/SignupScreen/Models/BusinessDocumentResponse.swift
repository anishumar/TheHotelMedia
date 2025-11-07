//
//  BusinessDocumentResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 25/09/24.
//

import Foundation


struct BusinessDocumentResponse: Codable, Refreshable {
    var status: Bool
    var statusCode: Int
    var message: String
}
