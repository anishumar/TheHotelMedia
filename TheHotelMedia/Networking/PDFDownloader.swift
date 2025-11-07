//
//  PDFDownloader.swift
//  TheHotelMedia
//
//  Created by MAC on 09/05/25.
//

import Foundation
import Alamofire

class PDFDownloader {
    
    static let shared = PDFDownloader()
    
    func downloadPDF(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let dataTask = AF.request(url).serializingData()
        let data = try await dataTask.value
        return data
    }
}

