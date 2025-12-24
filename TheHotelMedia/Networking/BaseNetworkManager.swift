//
//  BaseNetworkManager.swift
//  TheHotelMedia
//
//  Created by MAC on 19/09/24.
//

import Foundation
import Alamofire
import SwiftUI
import SwiftyJSON
import AVKit
import Photos
import UniformTypeIdentifiers


protocol Refreshable {
    var status: Bool { get }
    var statusCode: Int { get }
    var message: String { get }
}


enum NetworkError: LocalizedError, Equatable {
    case badURL
    case invalidResponse
    case decodingError
    case encodingError
    case invalidServerResponse(message: String? = nil)
    case accessTokenExpired
    case refreshTokenExpired
    case sessionInitializationFailed
    
    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .invalidServerResponse(let message):
            return message ?? "Invalid server response"
        case .accessTokenExpired:
            return "Access token expired"
        case .refreshTokenExpired:
            return "Refresh token expired"
        case .sessionInitializationFailed:
            return "Session initialization failed"
        }
    }
    
    var localizedDescription: String {
        return errorDescription ?? "Network error occurred"
    }
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.badURL, .badURL),
             (.invalidResponse, .invalidResponse),
             (.decodingError, .decodingError),
             (.encodingError, .encodingError),
             (.invalidServerResponse, .invalidServerResponse),
             (.accessTokenExpired, .accessTokenExpired),
             (.refreshTokenExpired, .refreshTokenExpired),
             (.sessionInitializationFailed, .sessionInitializationFailed):
            return true
        default:
            return false
        }
    }
}


enum HttpMethod {
    case get([URLQueryItem])
    case post([String: Any])
    case postWithArray([String: Any], [String])
    case postWithItems([String: Any])
    case delete
    case postImage(UIImage, [String: Any])
    case patch([String: Any])
    case postJSON(Data?)
    case postFiles([FileModel])
    case createPost([MediaAttachment], [String], [String: Any])
    case createPostBackground([MediaAttachment], [String], [String: Any])
    case createReview([MediaAttachment], [ReviewQuestionRating], [String: Any])
    case mediaMessage([MessageMedia], [String: Any])
    case createEvent(UIImage, [String: Any])
    case createStory([MediaAttachment], [String: Any])
    case updatePost([MediaAttachment], [String], [String: Any], [String])
    
    var name: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .delete:
            return "DELETE"
        case .postImage:
            return "POST"
        case .patch:
            return "PATCH"
        case .postJSON:
            return "POST"
        case .postFiles:
            return "POST"
        case .createPost:
            return "POST"
        case .createEvent:
            return "POST"
        case .createStory:
            return "POST"
        case .mediaMessage:
            return "POST"
        case .createReview:
            return "POST"
        case .postWithItems:
            return "POST"
        case .createPostBackground:
            return "POST"
        case .postWithArray:
            return "POST"
        case .updatePost:
            return "PUT"
        }
    }
    
    var alamofireMethod: Alamofire.HTTPMethod {
        switch self {
        case .get:
            return .get
        case .post:
            return .post
        case .delete:
            return .delete
        case .postImage:
            return .post
        case .patch:
            return .patch
        case .postJSON:
            return .post
        case .postFiles:
            return .post
        case .createPost:
            return .post
        case .createEvent:
            return .post
        case .createStory:
            return .post
        case .mediaMessage:
            return .post
        case .createReview:
            return .post
        case .postWithItems:
            return .post
        case .createPostBackground:
            return .post
        case .postWithArray:
            return .post
        case .updatePost:
            return .put
        }
    }
    
}


struct Resource<T: Codable> {
    let url: URL
    var headers: [String: String] = ["Content-Type": "application/json"]
    var method: HttpMethod = .get([])
}


class BaseNetworkManager {
    
    static let shared = BaseNetworkManager()
    let tokenManager = TokenManager.shared
    
    // Custom session with longer timeouts for uploads
    let session: Session = {
        let configuration = URLSessionConfiguration.default
        // Timeout for individual request (waiting for response)
        configuration.timeoutIntervalForRequest = 300 // 5 minutes
        // Total timeout for the entire resource transfer (including upload)
        configuration.timeoutIntervalForResource = 600 // 10 minutes
        // Allow cellular network
        configuration.allowsCellularAccess = true
        // Wait for connectivity
        configuration.waitsForConnectivity = true
        
        return Session(configuration: configuration)
    }()
    
    init() {
    }
    
    @AppStorage("hasLoggedIn") var hasLoggedIn: Bool = false
    @AppStorage("accessToken") var accessToken: String = ""
    @AppStorage("username") var username: String = ""
    @AppStorage("name") var name: String = ""
    @AppStorage("profilePic") var profilePic: String = ""
    @AppStorage("locationString") var locationString: String = ""
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    // This method does not refreshes token.
    // This method does not require access token.
    func load<T: Codable>(_ resource: Resource<T>) async throws -> T {
        var request: DataRequest?
        
        switch resource.method {
        case .get(let querys):
            var urlComponents = URLComponents(string: resource.url.absoluteString)
            urlComponents?.queryItems = querys
            
            if let url = urlComponents?.url {
                request = session.request(url, method: .get, headers: HTTPHeaders(resource.headers))
            }
            
        case .post(let dictionary):
            request = session.request(resource.url, method: .post, parameters: dictionary, encoding: JSONEncoding.default, headers: HTTPHeaders(resource.headers))
            
        case .patch(let parameters):
            request = session.request(resource.url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: HTTPHeaders(resource.headers))
            
        case .postImage(let image, let parameters):
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NetworkError.badURL
            }
            
            let header = [
                "Content-Type": "multipart/form-data",
                "x-access-token": accessToken
            ]
            
            request = session.upload(multipartFormData: { multipartFormData in
                
                multipartFormData.append(imageData, withName: "profilePic", fileName: "profilePic.jpeg", mimeType: "image/jpeg")
                
                for (key, value) in parameters {
                    if let valueString = value as? String,
                       let data = valueString.data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    } else if let value = value as? CustomStringConvertible {
                        // Handles cases where value could be an Int, Bool, etc.
                        let stringValue = String(describing: value)
                        if let data = stringValue.data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
                
                
            }, to: resource.url, headers: HTTPHeaders(header))
            
            
        case .postJSON(let jsonData):
            request = session.request(resource.url, method: .post, headers: HTTPHeaders(resource.headers)) { request in
                request.httpBody = jsonData
            }
            
        case .postFiles(let files):
            let header = [
                "Content-Type": "multipart/form-data",
                "x-access-token": accessToken
            ]
            
            request = session.upload(multipartFormData: { multipartFormData in
                
                for file in files {
                    multipartFormData.append(file.data, withName: file.parameterName, fileName: file.fileName, mimeType: file.mimeType)
                }
                
            }, to: resource.url, headers: HTTPHeaders(header))
            
        default:
            break
        }
        
        guard let request else { throw NetworkError.badURL }
        
        let result = await request.serializingData().response
        
        guard let response = result.response else {
            if let data = result.data {
                let jsonData = JSON(data)
                print("Response data without HTTP response: \(jsonData)")
            }
            throw NetworkError.invalidServerResponse()
        }
        
        let statusCode = response.statusCode
        guard (200...204).contains(statusCode) else {
            var errorMessage: String? = nil
            if let data = result.data {
                let jsonData = JSON(data)
                print("Error response: \(jsonData), Status Code: \(statusCode)")
                if let message = jsonData["message"].string {
                    errorMessage = message
                } else if let nestedData = jsonData["data"]["message"].string {
                    errorMessage = nestedData
                }
            }
            throw NetworkError.invalidServerResponse(message: errorMessage)
        }
        
        guard let data = result.data else { throw NetworkError.invalidResponse }
        
        let jsonData = JSON(data)
//        print("➡️",jsonData, "⬅️")
        
        do {
            let resultModel = try JSONDecoder().decode(T.self, from: data)
            return resultModel
        } catch {
            
            throw NetworkError.decodingError
        }
    }
    
    
    // This method requires access token and also refreshes token.
    func accessLoad<T: Codable & Refreshable>(_ resource: Resource<T>) async throws -> T {
        
        let request = try await configureDataRequest(resource: resource)
        
        do {
            let data = try await getAndValidateResponse(request: request)
            
            let jsonData = JSON(data)
//            print("➡️",jsonData, "⬅️")
            
            let resultModel: T = try decodeData(data: data)
            
            handleBackgroundResponse(resource, response: resultModel)
            
            return resultModel
            
        } catch {
            guard let error = error as? NetworkError else { throw error }
            
            if error == .accessTokenExpired {
                
                do {
                    let isRefreshed = try await tokenManager.refreshAccessToken()
                    
                    if isRefreshed {
                        let request2 = try await configureDataRequest(resource: resource)
                        
                        let data = try await getAndValidateResponse(request: request2)
                        
                        let resultModel: T = try decodeData(data: data)
                        
//                        print(resultModel.message, "2️⃣")
                        
                        guard resultModel.status else {
                            resetUserData()
                            SocketIOViewModel.shared.disconnectSocket()
                            hasLoggedIn = false
                            throw NetworkError.refreshTokenExpired
                        }
                        
                        return resultModel
                        
                    } else {
                        resetUserData()
                        SocketIOViewModel.shared.disconnectSocket()
                        hasLoggedIn = false
                        throw error
                    }
                    
                } catch {
                    resetUserData()
                    SocketIOViewModel.shared.disconnectSocket()
                    hasLoggedIn = false
                    throw error
                }
                
            } else {
                throw error
            }
        }
    }
    
    
    func resetUserData() {
        name = ""
        username = ""
        isIndividual = true
        ownUserID = ""
        locationString = ""
        profilePic = ""
    }

    
    private func configureDataRequest<T: Codable>(resource: Resource<T>) async throws -> DataRequest {
        var request: DataRequest? = nil
        var header = [
            "Content-Type": "application/json",
            "x-access-token": accessToken
        ]
        
        switch resource.method {
        case .get(let querys):
            var urlComponents = URLComponents(string: resource.url.absoluteString)
            urlComponents?.queryItems = querys
            
            if let url = urlComponents?.url {
                request = session.request(url, method: .get, headers: HTTPHeaders(header))
            }
            
        case .post(let parameters):
            request = session.request(resource.url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: HTTPHeaders(header))
            
        case .postWithItems(let items):
            request = session.request(resource.url, method: .post, parameters: items, encoding: URLEncoding.default, headers: HTTPHeaders(header))
            
        case .delete:
            request = session.request(resource.url, method: .delete, headers: HTTPHeaders(header))
            
        case .postImage(let image, let parameters):
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NetworkError.badURL
            }
            
            header = [
                "Content-Type": "multipart/form-data",
                "x-access-token": accessToken
            ]
            
            request = session.upload(multipartFormData: { multipartFormData in
                
                multipartFormData.append(imageData, withName: "profilePic", fileName: "profilePic.jpeg", mimeType: "image/jpeg")
                
                for (key, value) in parameters {
                    if let valueString = value as? String,
                       let data = valueString.data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    } else if let value = value as? CustomStringConvertible {
                        // Handles cases where value could be an Int, Bool, etc.
                        let stringValue = String(describing: value)
                        if let data = stringValue.data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
                
            }, to: resource.url, headers: HTTPHeaders(header))
            
        case .createEvent(let image, let parameters):
            guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                throw NetworkError.badURL
            }
            
            printDataSizeInMB(data: imageData)
            
            let header = [
                "Content-Type": "multipart/form-data",
                "x-access-token": accessToken
            ]
            
            request = session.upload(multipartFormData: { multipartFormData in
                
                multipartFormData.append(imageData, withName: "images", fileName: "images.jpeg", mimeType: "image/jpeg")
                
                for (key, value) in parameters {
                    if let valueString = value as? String,
                       let data = valueString.data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    } else if let value = value as? CustomStringConvertible {
                        // Handles cases where value could be an Int, Bool, etc.
                        let stringValue = String(describing: value)
                        if let data = stringValue.data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
            }, to: resource.url, headers: HTTPHeaders(header))
            
        case .patch(let parameters):
            request = session.request(resource.url, method: .patch, parameters: parameters, encoding: JSONEncoding.default, headers: HTTPHeaders(header))
            
        case .createPost(let attachments, let tags, let parameters):
            
            header = [
                "Content-Type": "multipart/form-data",
                "x-access-token": accessToken
            ]
           /*
            var updatedMediaAttachments: [MediaAttachment] = []

            for attachment in attachments {
                switch attachment.type {
                case .video(_ , let videoURL):
                    if let newvideoURL = try? await encodeVideo(at: videoURL) {
                        updatedMediaAttachments.append(MediaAttachment(id: attachment.id, type: .video(attachment.thumbnail, videoURL)))
                    }
                    
                case .photo(let image):
                    updatedMediaAttachments.append(MediaAttachment(id: attachment.id, type: .photo(image)))
                }
            }
            */ // Previous code for converting .mov to mp4 for uplaoding.
            
            request = session.upload(multipartFormData: { [weak self] multipartFormData in
                guard let self else { return }
                
                for attachment in attachments {
                    switch attachment.type {
                    case .photo(let image):
                        if let imageData = image.jpegData(compressionQuality: 0.5) {
                            multipartFormData.append(imageData, withName: "media", fileName: "image.jpeg", mimeType: "image/jpeg")
                        }
                    case .video( _, let videoURL):
                        if let videoData = try? Data(contentsOf: videoURL) {
                            if let mimeType = self.mimeType(for: videoURL) {
                                print(mimeType)
                                print(videoURL.lastPathComponent)
                                multipartFormData.append(videoData, withName: "media", fileName: videoURL.lastPathComponent, mimeType: mimeType)
                            }
                        }
                    }
                }
                
                
                for tag in tags {
                    multipartFormData.append(Data(tag.utf8), withName: "tagged[]")
                }
                
                
                for (key, value) in parameters {
                    if let valueString = value as? String,
                       let data = valueString.data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    } else if let value = value as? CustomStringConvertible {
                        // Handles cases where value could be an Int, Bool, etc.
                        let stringValue = String(describing: value)
                        if let data = stringValue.data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
                
                
            }, to: resource.url, headers: HTTPHeaders(header))
            
        case .updatePost(let attachments, let tags, let parameters, let deletedMedia):
            
            header = [
                "Content-Type": "multipart/form-data",
                "x-access-token": accessToken
            ]
            
            request = session.upload(multipartFormData: { [weak self] multipartFormData in
                guard let self else { return }
                
                for attachment in attachments {
                    switch attachment.type {
                    case .photo(let image):
                        if let imageData = image.jpegData(compressionQuality: 0.5) {
                            multipartFormData.append(imageData, withName: "media", fileName: "image.jpeg", mimeType: "image/jpeg")
                        }
                    case .video( _, let videoURL):
                        if let videoData = try? Data(contentsOf: videoURL) {
                            if let mimeType = self.mimeType(for: videoURL) {
                                print(mimeType)
                                print(videoURL.lastPathComponent)
                                multipartFormData.append(videoData, withName: "media", fileName: videoURL.lastPathComponent, mimeType: mimeType)
                            }
                        }
                    }
                }
                
                for tag in tags {
                    multipartFormData.append(Data(tag.utf8), withName: "tagged[]")
                }
                
                for deletedMediaID in deletedMedia {
                    multipartFormData.append(Data(deletedMediaID.utf8), withName: "deletedMedia")
                }
                
                for (key, value) in parameters {
                    if let valueString = value as? String,
                       let data = valueString.data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    } else if let value = value as? CustomStringConvertible {
                        // Handles cases where value could be an Int, Bool, etc.
                        let stringValue = String(describing: value)
                        if let data = stringValue.data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
                
            }, to: resource.url, method: .put, headers: HTTPHeaders(header))
            
        case .postWithArray(let parameters, let array):
//            header = [
//                "Content-Type": "multipart/form-data",
//                "x-access-token": accessToken
//            ]
//            
//            request = session.upload(multipartFormData: { [weak self] multipartFormData in
//                guard let self else { return }
//                
//                for (key, value) in parameters {
//                    if let valueString = value as? String,
//                       let data = valueString.data(using: .utf8) {
//                        multipartFormData.append(data, withName: key)
//                    } else if let value = value as? CustomStringConvertible {
//                        // Handles cases where value could be an Int, Bool, etc.
//                        let stringValue = String(describing: value)
//                        if let data = stringValue.data(using: .utf8) {
//                            multipartFormData.append(data, withName: key)
//                        }
//                    }
//                }
//                
//                for item in array {
//                    multipartFormData.append(Data(item.utf8), withName: "childrenAge[]")
//                }
//                
//                
//            }, to: resource.url, headers: HTTPHeaders(header))
            
            var encodedParameters: [String: Any] = parameters
            for (index, value) in array.enumerated() {
                encodedParameters["childrenAge[\(index)]"] = value
            }

            header = [
                "Content-Type": "application/x-www-form-urlencoded",
                "x-access-token": accessToken
            ]

            // Send request
            request = session.request(resource.url,
                                      method: .post,
                                      parameters: encodedParameters,
                                      encoding: URLEncoding.default,
                                      headers: HTTPHeaders(header))
            
        case .createReview(let attachments, let reviews, let parameters):
            
            header = [
                "Content-Type": "multipart/form-data",
                "x-access-token": accessToken
            ]
            
            var updatedMediaAttachments: [MediaAttachment] = []
            
            for attachment in attachments {
                switch attachment.type {
                case .video(_ , let videoURL):
                    if let newvideoURL = try? await encodeVideo(at: videoURL) {
                        updatedMediaAttachments.append(MediaAttachment(id: attachment.id, type: .video(attachment.thumbnail, newvideoURL)))
                    }
                    
                case .photo(let image):
                    updatedMediaAttachments.append(MediaAttachment(id: attachment.id, type: .photo(image)))
                }
            }
            
            request = session.upload(multipartFormData: { [weak self] multipartFormData in
                guard let self else { return }
                
                for attachment in updatedMediaAttachments {
                    switch attachment.type {
                    case .photo(let image):
                        if let imageData = image.jpegData(compressionQuality: 0.5) {
                            multipartFormData.append(imageData, withName: "images", fileName: "image.jpeg", mimeType: "image/jpeg")
                        }
                    case .video( _, let videoURL):
                        if let videoData = try? Data(contentsOf: videoURL) {
                            if let mimeType = self.mimeType(for: videoURL) {
                                print(mimeType)
                                print(videoURL.lastPathComponent)
                                multipartFormData.append(videoData, withName: "videos", fileName: videoURL.lastPathComponent, mimeType: mimeType)
                            }
                        }
                    }
                }
                
                
                for review in reviews {
                    let jsonData = try? JSONEncoder().encode(review)
                    let jsonString = String(data: jsonData ?? Data(), encoding: .utf8) ?? "{}"
                    
                    multipartFormData.append(Data(jsonString.utf8), withName: "reviews[]")
                }
                
                
                for (key, value) in parameters {
                    if let valueString = value as? String,
                       let data = valueString.data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    } else if let value = value as? CustomStringConvertible {
                        // Handles cases where value could be an Int, Bool, etc.
                        let stringValue = String(describing: value)
                        if let data = stringValue.data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
                
                
            }, to: resource.url, headers: HTTPHeaders(header))
            
        case .mediaMessage(let attachments, let parameters):
            
            header = [
                "Content-Type": "multipart/form-data",
                "x-access-token": accessToken
            ]
            
            var updatedMediaAttachments: [MessageMedia] = []
            
            for attachment in attachments {
                switch attachment.type {
                case .photo(_):
                    updatedMediaAttachments.append(attachment)
                case .video(_, let videoURL):
                    if let newvideoURL = try? await encodeVideo(at: videoURL) {
                        updatedMediaAttachments.append(MessageMedia(id: attachment.id, type: .video(UIImage(), newvideoURL)))
                    }
                case .file(_):
                    updatedMediaAttachments.append(attachment)
                }
            }
            
            request = session.upload(multipartFormData: { [weak self] multipartFormData in
                guard let self else { return }
                
                for attachment in updatedMediaAttachments {
                    switch attachment.type {
                    case .photo(let image):
                        if let imageData = image.jpegData(compressionQuality: 0.5) {
                            multipartFormData.append(imageData, withName: "media", fileName: "image.jpeg", mimeType: "image/jpeg")
                        }
                    case .video( _, let videoURL):
                        if let videoData = try? Data(contentsOf: videoURL) {
                            if let mimeType = self.mimeType(for: videoURL) {
                                print(mimeType)
                                print(videoURL.lastPathComponent)
                                multipartFormData.append(videoData, withName: "media", fileName: videoURL.lastPathComponent, mimeType: mimeType)
                            }
                        }
                    case .file(let data):
                        multipartFormData.append(data, withName: "media", fileName: "file.pdf", mimeType: "application/pdf")
                    }
                }
                
                for (key, value) in parameters {
                    if let valueString = value as? String,
                       let data = valueString.data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    } else if let value = value as? CustomStringConvertible {
                        // Handles cases where value could be an Int, Bool, etc.
                        let stringValue = String(describing: value)
                        if let data = stringValue.data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
                
                
            }, to: resource.url, headers: HTTPHeaders(header))
            
        case .createStory(let attachments, let parameters):
            
            header = [
                "Content-Type": "multipart/form-data",
                "x-access-token": accessToken
            ]
            
            // Skip video encoding - upload directly like posts do
            request = session.upload(multipartFormData: { [weak self] multipartFormData in
                guard let self else { return }
                
                for attachment in attachments {
                    switch attachment.type {
                    case .photo(let image):
                        if let imageData = image.jpegData(compressionQuality: 0.8) {
                            multipartFormData.append(imageData, withName: "images", fileName: "image.jpeg", mimeType: "image/jpeg")
                        }
                    case .video( _, let videoURL):
                        if let videoData = try? Data(contentsOf: videoURL) {
                            if let mimeType = self.mimeType(for: videoURL) {
                                print("📹 Uploading video: \(videoURL.lastPathComponent), MIME: \(mimeType)")
                                multipartFormData.append(videoData, withName: "videos", fileName: videoURL.lastPathComponent, mimeType: mimeType)
                            }
                        }
                    }
                }
                
                // Add body parameters (excluding tagged array which is handled separately)
                for (key, value) in parameters {
                    // Skip tagged array - handle separately
                    if key == "tagged" { continue }
                    
                    if let valueString = value as? String,
                       let data = valueString.data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    } else if let value = value as? CustomStringConvertible {
                        let stringValue = String(describing: value)
                        if let data = stringValue.data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
                
                // Handle tagged array
                if let tagged = parameters["tagged"] as? [String] {
                    for tagID in tagged {
                        if let data = tagID.data(using: .utf8) {
                            multipartFormData.append(data, withName: "tagged[]")
                        }
                    }
                }
            }, to: resource.url, headers: HTTPHeaders(header))
            
            
        case .postJSON:
            break
            
        default:
            break
        }
        
        guard let request else {
            throw NetworkError.badURL
        }
        
        return request
    }
    
    
    private func getAndValidateResponse(request: DataRequest) async throws -> Data {
        let result = await request.serializingData().response
        
        let jsondata = JSON(result.data ?? Data())
        print(jsondata)
        
        guard let response = result.response else { throw NetworkError.invalidServerResponse() }
        
        let statusCode = response.statusCode
        print(statusCode, "This is server status Code 📀")
        
        if  statusCode == 401 || statusCode == 403 {
            throw NetworkError.accessTokenExpired
        }
        
        guard (200...204).contains(statusCode) else { 
            var errorMessage: String? = nil
            if let data = result.data {
                let jsonData = JSON(data)
                print("Error response: \(jsonData), Status Code: \(statusCode)")
                if let message = jsonData["message"].string {
                    errorMessage = message
                } else if let nestedData = jsonData["data"]["message"].string {
                    errorMessage = nestedData
                }
            }
            throw NetworkError.invalidServerResponse(message: errorMessage)
        }
        
        guard let data = result.data else { throw NetworkError.invalidResponse }
        
        return data
    }
    
    
    private func decodeData<T: Codable>(data: Data) throws -> T {
        do {
            let resultModel = try JSONDecoder().decode(T.self, from: data)
            return resultModel
        } catch let decodingError as DecodingError {
            // Handle and print detailed decoding error
            switch decodingError {
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription) at codingPath: \(context.codingPath)")
            case .keyNotFound(let key, let context):
                print("Key '\(key)' not found: \(context.debugDescription) at codingPath: \(context.codingPath)")
            case .typeMismatch(let type, let context):
                print("Type mismatch for type '\(type)': \(context.debugDescription) at codingPath: \(context.codingPath)")
            case .valueNotFound(let type, let context):
                print("Value not found for type '\(type)': \(context.debugDescription) at codingPath: \(context.codingPath)")
            @unknown default:
                print("Unknown decoding error")
            }
            throw NetworkError.decodingError
        } catch {
            // Handle other errors if needed
            print("Unexpected error: \(error.localizedDescription)")
            throw NetworkError.decodingError
        }
    }
    
    
    private func printDataSizeInMB(data: Data) {
        // Calculate the size in bytes
        let sizeInBytes = data.count
        
        // Convert to megabytes (MB)
        let sizeInMB = Double(sizeInBytes) / (1024.0 * 1024.0)
        
        // Print the size in MB
        print("Data Size: \(sizeInMB) MB", "🌤️")
    }
    
    
    func mimeType(for url: URL) -> String? {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return nil
        }
        return type.preferredMIMEType
    }
    

    func mimeType(for data: Data) -> String? {
        // Create a temporary file with the data
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? data.write(to: tempURL)
        
        // Infer the MIME type from the file's extension or content
        if let utType = UTType(filenameExtension: tempURL.pathExtension) {
            return utType.preferredMIMEType
        }
        
        return nil
    }

    

    func encodeVideo(at videoURL: URL) async throws -> URL {
        let avAsset = AVURLAsset(url: videoURL)
        
        // Set up a temporary file path for the exported video
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputURL = tempDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        
        // Remove any existing file at the output location
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        // Create and configure the export session
        guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHEVCHighestQuality) else {
            throw NSError(domain: "com.example.videoexport",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create export session."])
        }
        exportSession.outputFileType = .mp4
        exportSession.outputURL = outputURL
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Perform the export operation
        return try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: outputURL)
                case .failed:
                    continuation.resume(throwing: exportSession.error ?? NSError(domain: "com.example.videoexport",
                                                                                 code: -1,
                                                                                 userInfo: [NSLocalizedDescriptionKey: "Export failed."]))
                case .cancelled:
                    continuation.resume(throwing: NSError(domain: "com.example.videoexport",
                                                          code: -1,
                                                          userInfo: [NSLocalizedDescriptionKey: "Export cancelled."]))
                default:
                    break
                }
            }
        }
    }

    
    func saveToPhotosLibrary(videoURL: URL) throws {
        try PHPhotoLibrary.shared().performChangesAndWait {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }
        print("Video saved to photos gallery")
    }
}


// MARK: - Background Task Management
extension BaseNetworkManager {
    
    func handleBackgroundResponse<T: Codable & Refreshable>(_ resource: Resource<T>, response: T) {
        switch resource.method {
        case .createPostBackground:
            let range = 200...204
            if response.status && range.contains(response.statusCode) {
                print("Post uploaded successfully.")
            }
        default:
            break
        }
    }
    
    
    // Function to send notifications
    private func sendNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
}
