//
//  CommentDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 10/10/24.
//

import Foundation


class CommentDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getComments(postID: String, pageNo: Int) async throws -> CommentsDataResponse {
        
        guard let url = URL(string: "\(URL.getComments.absoluteString)\(postID)") else { throw NetworkError.badURL }
        
        let resource = Resource<CommentsDataResponse>(url: url, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "20")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func postComment(parameters: [String: Any]) async throws -> CreateCommentResponse {
        
        let resource = Resource<CreateCommentResponse>(url: .postComment, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func likeAComment(commentID: String) async throws -> CommentLikeResponse {
        
        guard let url = URL(string: "\(URL.likeAComment.absoluteString)\(commentID)") else { throw NetworkError.badURL }
        
        let resource = Resource<CommentLikeResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
