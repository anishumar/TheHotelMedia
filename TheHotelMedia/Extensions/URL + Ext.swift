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
    
    /// Trims a video to a specified maximum duration
    /// - Parameter maxDuration: Maximum duration in seconds
    /// - Returns: URL of the trimmed video
    func trimVideo(toMaxDuration maxDuration: TimeInterval) async throws -> URL {
        let asset = AVURLAsset(url: self)
        
        // Get video duration
        let duration = try await asset.load(.duration)
        let durationInSeconds = CMTimeGetSeconds(duration)
        
        // If video is already within limit, return original
        if durationInSeconds <= maxDuration {
            return self
        }
        
        // Create output URL
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputURL = tempDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        
        // Remove existing file if present
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "VideoTrimming", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Set time range to trim (from start to maxDuration)
        let startTime = CMTime.zero
        let endTime = CMTime(seconds: maxDuration, preferredTimescale: duration.timescale)
        exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)
        
        // Export the trimmed video
        return try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: outputURL)
                case .failed:
                    continuation.resume(throwing: exportSession.error ?? NSError(domain: "VideoTrimming", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export failed"]))
                case .cancelled:
                    continuation.resume(throwing: NSError(domain: "VideoTrimming", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export cancelled"]))
                default:
                    continuation.resume(throwing: NSError(domain: "VideoTrimming", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown export status"]))
                }
            }
        }
    }

}
