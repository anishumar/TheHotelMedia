//
//  ExportChatResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 07/01/25.
//

import Foundation


struct ExportChatResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: ExportData?
}


struct ExportData: Codable {
    let filename: String?
    let filepath: String?
    let type: String?
}
