//
//  StoryDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 11/11/24.
//

import Foundation


class StoryDataManager {
    let baseNetworkManager = BaseNetworkManager.shared
    
    func postStory(attachments: [MediaAttachment], parameters: [String: Any] = [:]) async throws -> PostStoryResponse {
        
        let resource = Resource<PostStoryResponse>(url: .createStory, method: .createStory(attachments, parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getStories(pageNo: Int) async throws -> GetStoriesResponse {
        
        let resource = Resource<GetStoriesResponse>(url: .getStories, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "38")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    func publishPostAsStory(postID: String) async throws -> PostStoryResponse {
        // Construct URL: /api/v1/post/:id/publish-as-story
        let urlString = "\(URL.default)/post/\(postID)/publish-as-story"
        guard let url = URL(string: urlString) else {
            throw NetworkError.badURL
        }
        
        let resource = Resource<PostStoryResponse>(url: url, method: .publishPostAsStory)
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
