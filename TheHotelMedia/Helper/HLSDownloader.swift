//
//  HLSDownloader.swift
//  TheHotelMedia
//
//  Created by MAC on 14/01/25.
//

import Foundation
import FFmpeg_Kit

class HLSDownloader {
    
    static let shared = HLSDownloader()
    
    /// Downloads and converts an HLS stream to MP4.
    /// - Parameters:
    ///   - m3u8URL: The URL of the HLS `.m3u8` file.
    ///   - completion: Completion handler with the output file URL or an error.
    func downloadAndConvertHLS(m3u8URL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        // Step 1: Generate a filename with the format "THM-Video-DD-MM-YYYY"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "THM-Video-\(dateString).mp4"
        
        // Step 2: Define output file path in cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let outputURL = cacheDirectory.appendingPathComponent(fileName)
        
        // Step 3: Check if file already exists and remove it if necessary
        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
                print("Existing file removed: \(outputURL.path)")
            } catch {
                print("Failed to remove existing file: \(error)")
                completion(.failure(NSError(domain: "HLSDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to remove existing file."])))
                return
            }
        }
        
        // Step 4: Create FFmpeg command
//        let ffmpegCommand = "-i \(m3u8URL.absoluteString) -c:v h264 -c:a aac -strict experimental \(outputURL.path)"
        let ffmpegCommand = "-i \(m3u8URL.absoluteString) -c copy \(outputURL.path)"



    
        // Step 5: Execute FFmpeg command
        FFmpegKit.executeAsync(ffmpegCommand) { session in
            guard let session = session else {
                let error = "FFmpeg_Kit session is nil."
                print("Error: \(error)")
                completion(.failure(NSError(domain: "HLSDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: error])))
                return
            }
            
            let returnCode = session.getReturnCode()
            
            if let returnCode {
                if returnCode.isValueSuccess() {
                    print("HLS conversion successful. File saved at: \(outputURL.path)")
                    completion(.success(outputURL))
                } else {
                    let error = session.getFailStackTrace() ?? "Unknown error"
                    print("HLS conversion failed with error: \(error)")
                    completion(.failure(NSError(domain: "HLSDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: error])))
                }
            } else {
                let error = "Unknown return code."
                print("Error: \(error)")
                completion(.failure(NSError(domain: "HLSDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: error])))
            }
        }
    }
}
