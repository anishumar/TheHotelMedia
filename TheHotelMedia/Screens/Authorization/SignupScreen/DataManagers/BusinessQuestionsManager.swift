//
//  BusinessQuestionsManager.swift
//  TheHotelMedia
//
//  Created by MAC on 24/09/24.
//

import SwiftUI


class BusinessQuestionsManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    @AppStorage("accessToken") var accessToken: String = ""
    
    func getBusinessQuestions(parameters: [String: Any]) async throws -> BusinessQuestionResponse {
        
        let resource = Resource<BusinessQuestionResponse>(
            url: .businessQuestions,
            headers: [
                "Content-Type": "application/json",
                "x-access-token": accessToken
            ]
            , method: .post(parameters)
        )
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
    
    
    func postBusinessAnswers(data: Data?) async throws -> BusinessQuestionPostResponse {
        
        let resource = Resource<BusinessQuestionPostResponse>(
            url: .businessAnswers,
            headers: [
                "Content-Type": "application/json",
                "x-access-token": accessToken
            ]
            , method: .postJSON(data)
        )
        
        let result = try await baseNetworkManager.load(resource)
        
        return result
    }
}
