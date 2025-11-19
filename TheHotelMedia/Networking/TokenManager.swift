//
//  TokenManager.swift
//  TheHotelMedia
//
//  Created by MAC on 19/09/24.
//

import Foundation
import SwiftUI
import Alamofire


class TokenManager {
    
    
    static let shared = TokenManager()
    
    @AppStorage("accessToken") var accessToken: String = ""
    @AppStorage("refreshToken") var refreshToken: String = ""
    
    
    func refreshAccessToken() async throws -> Bool {
        let cookie = "SessionToken=\(refreshToken); UserDeviceID=\(DeviceIDManager.shared.getDeviceID()); X-Access-Token=\(accessToken)"
        
        let headers = [
            "Content-Type": "application/json",
            "Cookie": cookie
        ]
        
        let request = AF.request( URL.refreshToken, method: .post, encoding: JSONEncoding.default, headers: HTTPHeaders(headers))
        
        let result = await request.serializingData().response
        
        guard let response = result.response,
              response.statusCode == 200 || response.statusCode == 201 else {
            throw NetworkError.invalidServerResponse()
        }
        
        
        guard let data = result.data else { throw NetworkError.invalidResponse }
        
        do {
            let resultModel = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
            
            guard resultModel.status && resultModel.statusCode == 200 || resultModel.status && resultModel.statusCode == 201 else {
                return false
            }
            
            guard let data = resultModel.data,
                  let accessToken = data.accessToken,
                  let refreshToken = data.refreshToken else { return false }
            
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            
            return true
            
            
        } catch {
            throw NetworkError.decodingError
        }
    }
}


struct RefreshTokenResponse: Codable {
    let status: Bool
    let statusCode: Int
    let data: RefreshData?
}


struct RefreshData: Codable {
    let accessToken: String?
    let refreshToken: String?
}
