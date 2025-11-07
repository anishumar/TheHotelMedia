//
//  BackgroundNetworkManager.swift
//  TheHotelMedia
//
//  Created by MAC on 03/02/25.
//

import SwiftUI
import UserNotifications
import UIKit
import SwiftyJSON
import UniformTypeIdentifiers

class BackgroundNetworkManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    static let shared = BackgroundNetworkManager()

    private var session: URLSession!
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    @AppStorage("accessToken") var accessToken: String = ""
    @AppStorage("appIsActive") var appIsActive: Bool = true
    
    override init() {
        super.init()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.thehotelmedia.background.upload")
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        resumePendingUploads()
    }
    
    
    func resumePendingUploads() {
        session.getAllTasks { tasks in
            if tasks.isEmpty {
                print("No pending uploads.")
            } else {
                print("Resuming \(tasks.count) pending uploads...")
                tasks.forEach { $0.resume() }
            }
        }
    }
    

    // Start uploading
    func startUpload(attachments: [MediaAttachment], tags: [String], parameters: [String: Any]) {
        // Begin background task
//        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "UploadTask") {
//            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
//            self.backgroundTaskIdentifier = .invalid
//        }
        
        sendProgressNotification(isInProgress: true)
        
        var request = URLRequest(url: URL.createPost)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(accessToken, forHTTPHeaderField: "x-access-token")
        
        // Create the multipart form data and save it as a temporary file
        if let tempFileURL = saveMultipartDataToTempFile(attachments: attachments, tags: tags, parameters: parameters, boundary: boundary) {
            let task = session.uploadTask(with: request, fromFile: tempFileURL)
            task.resume()
        } else {
            print("Error: Failed to create multipart data file.")
            sendProgressNotification(isInProgress: false, success: false)
        }
    }

    // Save multipart data to a temporary file
    private func saveMultipartDataToTempFile(attachments: [MediaAttachment], tags: [String], parameters: [String: Any], boundary: String) -> URL? {
        var data = Data()
        
        // Add attachments (photos, videos)
        for attachment in attachments {
            switch attachment.type {
            case .photo(let image):
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    data.append(createFormData(withName: "media", fileName: "image.jpeg", mimeType: "image/jpeg", data: imageData, boundary: boundary))
                }
            case .video(_, let videoURL):
                if let videoData = try? Data(contentsOf: videoURL) {
                    if let mimeType = mimeType(for: videoURL) {
                        data.append(createFormData(withName: "media", fileName: videoURL.lastPathComponent, mimeType: mimeType, data: videoData, boundary: boundary))
                    }
                    
                }
            }
        }
        
        // Add tags
        for tag in tags {
            if let tagData = tag.data(using: .utf8) {
                data.append(createFormData(withName: "tagged[]", data: tagData, boundary: boundary))
            }
        }
        
        // Add parameters
        for (key, value) in parameters {
            if let valueString = value as? String, let paramData = valueString.data(using: .utf8) {
                data.append(createFormData(withName: key, data: paramData, boundary: boundary))
            }
        }
        
        // Add closing boundary
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Save the data to a temporary file
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try data.write(to: tempFileURL)
            return tempFileURL
        } catch {
            print("Error saving multipart data to file: \(error.localizedDescription)")
            return nil
        }
    }

    // Helper function to create form data
    private func createFormData(withName name: String, fileName: String? = nil, mimeType: String? = nil, data: Data, boundary: String) -> Data {
        var formData = Data()
        
        // Add boundary
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        
        // Add content disposition
        if let fileName = fileName, let mimeType = mimeType {
            let disposition = "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n"
            formData.append(disposition.data(using: .utf8)!)
            formData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        } else {
            let disposition = "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
            formData.append(disposition.data(using: .utf8)!)
        }
        
        // Append the actual data
        formData.append(data)
        formData.append("\r\n".data(using: .utf8)!)
        
        return formData
    }

    // Send progress notification
    private func sendProgressNotification(isInProgress: Bool, success: Bool? = nil, errorMessage: String? = nil) {
        let content = UNMutableNotificationContent()
        
        if isInProgress {
            content.title = "Upload in Progress"
            content.body = "Your upload is ongoing."
        } else if let success = success, success {
            content.title = "Upload Successful"
            content.body = "Your post has been uploaded successfully."
        } else {
            content.title = "⚠️ Upload Failed"
            content.body = errorMessage ?? "Something went wrong while uploading your post."
        }
        
        let request = UNNotificationRequest(identifier: "uploadNotification", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    // Delegate method for task completion
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Upload failed with error: \(error.localizedDescription)")
            sendProgressNotification(isInProgress: false, success: false)
        } else {
            print("Upload completed.")
            if !appIsActive {
                if let httpResponse = task.response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    print("Server response status code: \(statusCode)")
                    
                    let successRange = 200...204
                    if successRange.contains(statusCode) {
//                        sendProgressNotification(isInProgress: false, success: true)
                    } else {
                        sendProgressNotification(isInProgress: false, success: false, errorMessage: "Upload failed with status code \(statusCode)")
                    }
                } else {
                    print("No HTTP response received.")
                    sendProgressNotification(isInProgress: false, success: false, errorMessage: "No server response.")
                }
            }
        }
        
        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
        backgroundTaskIdentifier = .invalid
        
        DispatchQueue.main.async {
            if let completionHandler = (UIApplication.shared.delegate as? AppDelegate)?.backgroundCompletionHandler {
                completionHandler()
                (UIApplication.shared.delegate as? AppDelegate)?.backgroundCompletionHandler = nil // Reset it
            }
        }
        
    }
    
    // Delegate method for receiving response
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let json = JSON(data)
        print(json)
        do {
            let decodedData = try JSONDecoder().decode(CreatePostResponse.self, from: data)
            
            let range = 200...204
            if decodedData.status && range.contains(decodedData.statusCode) {
                sendProgressNotification(isInProgress: false, success: true)
            } else {
                sendProgressNotification(isInProgress: false, success: false, errorMessage: decodedData.message)
            }
            
        } catch {
            sendProgressNotification(isInProgress: false, success: false)
        }
    }
    
    
    // Track upload progress
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        print("Upload Progress: \(progress * 100)%")
    }

    
    
    func mimeType(for url: URL) -> String? {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return nil
        }
        return type.preferredMIMEType
    }
    
    
    private func handleUploadResponse(_ data: Data, statusCode: Int) {
        let range = 200...204
        
        do {
            let decodedData = try JSONDecoder().decode(CreatePostResponse.self, from: data)
            
            if decodedData.status && range.contains(decodedData.statusCode) {
                sendProgressNotification(isInProgress: false, success: true)
            } else {
                sendProgressNotification(isInProgress: false, success: false, errorMessage: decodedData.message)
            }
            
        } catch {
            sendProgressNotification(isInProgress: false, success: false)
        }
    }
}
