//
//  MediaPickerItem_Types.swift
//  HotelMedia
//
//  Created by MAC on 12/08/24.
//

import SwiftUI


struct VideoPickerTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exportingFile in
            return .init(exportingFile.url)
        } importing: { receivedTransferredFile in
            let originalFile = receivedTransferredFile.file
            let fileExtension = originalFile.pathExtension.lowercased()
            let uniqueFileName = "videoPicker.\(fileExtension)" // Use the extracted extension
            
            let copiedFile = URL.documentsDirectory.appendingPathComponent(uniqueFileName)
            
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: copiedFile.path) {
                try FileManager.default.removeItem(at: copiedFile)
            }
            
            // Copy the original file to the new location
            try FileManager.default.copyItem(at: originalFile, to: copiedFile)
            
            return .init(url: copiedFile)
        }
    }
}


struct MediaAttachment: Identifiable {
    let id: String
    let type: MediaAttachmentType
    
    var thumbnail: UIImage {
        switch type {
        case .photo(let thumbnail):
            return thumbnail
        case .video(let thumbnail, _):
            return thumbnail
        }
    }
}


enum MediaAttachmentType: Equatable {
    case photo(_ thumbnail: UIImage)
    case video(_ thumbnail: UIImage, _ url: URL)
    
    
    static func == (lhs: MediaAttachmentType, rhs: MediaAttachmentType) -> Bool {
        switch (lhs, rhs) {
        case (.photo, .photo), (.video, .video):
            return true
        default:
            return false
        }
    }
}
