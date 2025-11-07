//
//  ReviewDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 04/10/24.
//

import Foundation


class ReviewDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func createReview(parameters: [String: Any], attachments: [MediaAttachment], ratings: [ReviewQuestionRating]) async throws -> ReviewResponse {
        let resource = Resource<ReviewResponse>(url: .createReview, method: .createReview(attachments, ratings, parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
