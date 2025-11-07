//
//  MediaPreviewViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 08/01/25.
//

import Foundation
import SwiftUI


class MediaPreviewViewModel: ObservableObject {
    
    let dataManager = MediaPreviewDataManager()
    @Published var showCommentSection: Bool = false
    @Published var isSharePresented: Bool = false
    @Published var downloadingMedia: Bool = false
    @AppStorage("ownUserID") var ownUserID: String = ""
    @Published var shareURL: URL = URL(string: "https://thehotelmedia.com/post")!
    
    let hlsDownloader = HLSDownloader.shared
    let downloadManager = FileDownloadManager.shared
    
    func viewMedia(postID: String, mediaID: String) {
        
        let paramaters: [String: Any] = [
            "postID": postID,
            "mediaID" : mediaID
        ]
        
        Task {
            do {
                let result = try await dataManager.viewMedia(parameters: paramaters)
                
                print(result.message)
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func downloadVideo(url: URL) {
        downloadingMedia = true
        hlsDownloader.downloadAndConvertHLS(m3u8URL: url, completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let savedUrl):
                DispatchQueue.main.async {
                    self.shareURL = savedUrl
                    self.isSharePresented.toggle()
                    self.downloadingMedia = false
                }
            case .failure( _):
//                ErrorModalManager.showErrorModal(router: router, errorText: "Failed to download the video.")
                DispatchQueue.main.async {
                    self.downloadingMedia = false
                }
                print("Failed to download the video.")
            }
        })
    }
    
    
    func downloadImage(url: URL) {
        downloadingMedia = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "THM-Image-\(dateString).\(url.pathExtension)"
        downloadManager.downloadFile(from: url.absoluteString, fileName: fileName) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let savedUrl):
                DispatchQueue.main.async {
                    self.shareURL = savedUrl
                    self.isSharePresented.toggle()
                    self.downloadingMedia = false
                }
                
            case .failure( _):
                DispatchQueue.main.async {
                    self.downloadingMedia = false
                }
            }
        }
    }
    
    
    func showShareView(id: String, isEventPost: Bool = false) {
        
        var baseURLString = "https://thehotelmedia.com/share/posts"
        
        if isEventPost {
            baseURLString = "https://thehotelmedia.com/share/events"
        }
        
        if !id.isEmpty && !ownUserID.isEmpty {
            
            if let encryptedID = EncryptionHelper.encrypt(id),
               let encryptedUserID = EncryptionHelper.encrypt(ownUserID) {
                
                shareURL = URL(string: "\(baseURLString)?postID=\(encryptedID)&userID=\(encryptedUserID)")!
                isSharePresented.toggle()
            }
        }
    }
}
