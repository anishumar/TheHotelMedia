//
//  ProfileDataManager.swift
//  TheHotelMedia
//
//  Created by MAC on 27/09/24.
//

import UIKit


class ProfileDataManager {
    
    let baseNetworkManager = BaseNetworkManager.shared
    
    func getProfile() async throws -> ProfileResponse {
        
        let resource = Resource<ProfileResponse>(url: .getProfile, method: .get([]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getPublicProfile(id: String) async throws -> ProfileResponse {
        guard !id.isEmpty else {
            print("❌ Attempted to fetch profile with empty ID")
            throw NetworkError.badURL
        }
        
        guard let url = URL(string: "\(URL.getProfile)/\(id)") else {
            print("❌ Malformed URL: \(URL.getProfile)/\(id)")
            throw NetworkError.badURL
        }
        
        let resource = Resource<ProfileResponse>(url: url, method: .get([]))
        return try await baseNetworkManager.accessLoad(resource)
    }
    
    
    func editProfileData(parameters: [String: Any]) async throws -> EditProfileResponse {
        
        let resource = Resource<EditProfileResponse>(url: .editProfile, method: .patch(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func changeProfilePic(image: UIImage) async throws -> ProfilePicResponse {
        
        let resource = Resource<ProfilePicResponse>(url: .editProfilePic, method: .postImage(image, [:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getProfilePosts(id: String, pageNo: Int) async throws -> GetUserPostsResponse {
        
        guard let url = URL(string: "\(URL.getUserPosts.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<GetUserPostsResponse>(url: url, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "10")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getProfilePostImages(id: String, pageNo: Int) async throws -> GetUserImageResponse {
        
        guard let url = URL(string: "\(URL.getUserImages.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<GetUserImageResponse>(url: url, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "20")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    func getProfilePostVideos(id: String, pageNo: Int) async throws -> GetUserVideosResponse {
        
        guard let url = URL(string: "\(URL.getUserVideos.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<GetUserVideosResponse>(url: url, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "20")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func getBusinessReviews(id: String, pageNo: Int) async throws -> GetBusinessReviewsResponse {
        
        guard let url = URL(string: "\(URL.getBusinessReviews.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<GetBusinessReviewsResponse>(url: url, method: .get([URLQueryItem(name: "pageNumber", value: "\(pageNo)"), URLQueryItem(name: "documentLimit", value: "10")]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func blockUser(id: String) async throws -> BlockUserResponse {
        guard let url = URL(string: "\(URL.blockUser.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<BlockUserResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func updateBillingAddress(parameters: [String: Any]) async throws -> BillingAddressResponse {
        let resource = Resource<BillingAddressResponse>(url: .uploadBillingAddress, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func collectData(parameters: [String: Any]) async throws -> CollectDataResponse {
        let resource = Resource<CollectDataResponse>(url: .collectData, method: .post(parameters))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    
    func profileShared(sharedID: String, sharedByID: String) async throws -> ProfileSharedResponse {
        let resource = Resource<ProfileSharedResponse>(url: .profileShared, method: .get([URLQueryItem(name: "id", value: sharedID), URLQueryItem(name: "userID", value: sharedByID)]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
    
    func reportProfile(id: String) async throws -> ReportProfileResponse {
        guard let url = URL(string: "\(URL.reportUser.absoluteString)\(id)") else { throw NetworkError.badURL }
        
        let resource = Resource<ReportProfileResponse>(url: url, method: .post([:]))
        
        let result = try await baseNetworkManager.accessLoad(resource)
        
        return result
    }
}
