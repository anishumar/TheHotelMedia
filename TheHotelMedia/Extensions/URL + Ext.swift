//
//  URL + Ext.swift
//  HotelMedia
//
//  Created by MAC on 12/08/24.
//

import UIKit
import AVFoundation


extension URL {
    var dummyURL: URL {
        return URL(string: "htttps://www.google.com")!
    }
    
    func generateVideoThumbnail() async throws -> UIImage? {
        
        let asset = AVAsset(url: self)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
                if let cgImage {
                    let thumbnailImage = UIImage(cgImage: cgImage)
                    continuation.resume(returning: thumbnailImage)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "", code: 0, userInfo: nil))
                }
            }
        }
    }
    
    
    func generateVideoThumbnail(completion: @escaping (UIImage?, Error?) -> Void) {
        let asset = AVAsset(url: self)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
            if let cgImage {
                let thumbnailImage = UIImage(cgImage: cgImage)
                completion(thumbnailImage, nil)
            } else {
                completion(nil, error ?? NSError(domain: "", code: 0, userInfo: nil))
            }
        }
    }

}
