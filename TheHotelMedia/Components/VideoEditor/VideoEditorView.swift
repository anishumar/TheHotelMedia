//
//  VideoEditorView.swift
//  TheHotelMedia
//
//  Created by MAC on 17/09/24.
//

import SwiftUI
import UIKit
import AVFoundation


struct VideoEditorView: UIViewControllerRepresentable {
    var videoURL: URL
    var limit: Double = 30
    var onComplete: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UINavigationBar.appearance().tintColor = UIColor(ThemeManager.shared.currentTheme.label)
        
        // Validate video file exists and is editable
        let videoPath = videoURL.path
        guard FileManager.default.fileExists(atPath: videoPath) else {
            print("❌ Video file does not exist at path: \(videoPath)")
            DispatchQueue.main.async {
                context.coordinator.parent.onComplete(nil)
            }
            // Return a placeholder view controller that will be dismissed
            return UIViewController()
        }
        
        guard UIVideoEditorController.canEditVideo(atPath: videoPath) else {
            print("⚠️ Video cannot be edited by system at path: \(videoPath). Using fallback preview.")
            
            // Return fallback preview controller
            let fallbackView = VideoPreviewFallbackView(videoURL: videoURL, onComplete: { url in
                DispatchQueue.main.async {
                    context.coordinator.parent.onComplete(url)
                }
            })
            return UIHostingController(rootView: fallbackView)
        }
        
        let editor = UIVideoEditorController()
        editor.videoMaximumDuration = limit
        editor.videoPath = videoPath
        editor.delegate = context.coordinator
        editor.videoQuality = .typeHigh
        return editor
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No need to update the view controller
    }

    class Coordinator: NSObject, UIVideoEditorControllerDelegate, UINavigationControllerDelegate {
        var parent: VideoEditorView
        var didComplete = false // Add this flag

        init(_ parent: VideoEditorView) {
            self.parent = parent
        }

        func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
            if !didComplete { // Check if already completed
                didComplete = true
                inspectVideo(url: URL(fileURLWithPath: editedVideoPath))
                parent.onComplete(URL(fileURLWithPath: editedVideoPath))
            }
            editor.dismiss(animated: true, completion: nil)
        }

        func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
            if !didComplete { // Check if already completed
                didComplete = true
                parent.onComplete(nil)
            }
            editor.dismiss(animated: true, completion: nil)
        }

        func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
            if !didComplete { // Check if already completed
                didComplete = true
                print("Video editing failed with error: \(error)")
                parent.onComplete(nil)
            }
            editor.dismiss(animated: true, completion: nil)
        }
        
        
        func inspectVideo(url: URL) {
            let asset = AVURLAsset(url: url)
            for track in asset.tracks {
                print("Track type: \(track.mediaType.rawValue)")
                print("Format Descriptions: \(track.formatDescriptions)")
                print("Track Settings: \(track.preferredTransform)")
            }
            
            print(url)
        }
    }
}

private struct VideoPreviewFallbackView: View {
    @Environment(\.dismiss) private var dismiss
    let videoURL: URL
    let onComplete: (URL?) -> Void
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let player = player {
                FallbackVideoPlayerView(player: player)
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                HStack {
                    Button("Cancel") {
                        onComplete(nil)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Spacer()
                    
                    Button("Choose") {
                        onComplete(videoURL)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                }
                .background(Color.black.opacity(0.5))
                
                Spacer()
                
                Text("Preview Mode (Simulator)\nTrimming not supported")
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            print("🎬 [VideoEditorView] Fallback player appearing for URL: \(videoURL)")
            
            // Check file existence one more time
            if !FileManager.default.fileExists(atPath: videoURL.path) {
                print("❌ [VideoEditorView] Error: File does NOT exist at path when trying to play: \(videoURL.path)")
            }
            
            let item = AVPlayerItem(url: videoURL)
            player = AVPlayer(playerItem: item)
            
            // Observe failure
            NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main) { notification in
                if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                    print("❌ [VideoEditorView] Fallback player item failed: \(error.localizedDescription)")
                }
            }
            
            player?.play()
            print("▶️ [VideoEditorView] Fallback player told to play")
        }
        .onDisappear {
            print("⏹️ [VideoEditorView] Fallback player disappearing")
            player?.pause()
        }
    }
}

private struct FallbackVideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

import AVKit

//extension FileManager {
//    var documentsDirectory: URL {
//        return self.urls(for: .documentDirectory, in: .userDomainMask).first!
//    }
//}
//
//struct VideoEditorView: UIViewControllerRepresentable {
//    var videoURL: URL
//    var onComplete: (URL?) -> Void
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    func makeUIViewController(context: Context) -> UIVideoEditorController {
//        let editor = UIVideoEditorController()
//        editor.videoMaximumDuration = 30
//        editor.videoPath = videoURL.path
//        editor.delegate = context.coordinator
//        return editor
//    }
//
//    func updateUIViewController(_ uiViewController: UIVideoEditorController, context: Context) {
//        // No need to update the view controller
//    }
//
//    class Coordinator: NSObject, UIVideoEditorControllerDelegate, UINavigationControllerDelegate {
//        var parent: VideoEditorView
//        var didComplete = false // Add this flag
//
//        init(_ parent: VideoEditorView) {
//            self.parent = parent
//        }
//
//        func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
//            if !didComplete {
//                didComplete = true
//
//                let originalFile = URL(fileURLWithPath: editedVideoPath)
//                let fileExtension = originalFile.pathExtension.lowercased()
//                let uniqueFileName = "CustomEditedVideo.\(fileExtension)" // Use the extracted extension
//                let copiedFile = FileManager.default.documentsDirectory.appendingPathComponent(uniqueFileName)
//
//                // Remove existing file if it exists
//                if FileManager.default.fileExists(atPath: copiedFile.path) {
//                    do {
//                        try FileManager.default.removeItem(at: copiedFile)
//                    } catch {
//                        print("Error removing existing file: \(error)")
//                    }
//                }
//
//                // Copy the edited video to the custom path
//                do {
//                    try FileManager.default.copyItem(at: originalFile, to: copiedFile)
//                    print("Video saved to custom path: \(copiedFile)")
//                    parent.onComplete(copiedFile) // Return the custom path
//                } catch {
//                    print("Error saving video to custom path: \(error)")
//                    parent.onComplete(nil)
//                }
//            }
//            editor.dismiss(animated: true, completion: nil)
//        }
//
//        func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
//            if !didComplete {
//                didComplete = true
//                parent.onComplete(nil)
//            }
//            editor.dismiss(animated: true, completion: nil)
//        }
//
//        func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
//            if !didComplete {
//                didComplete = true
//                print("Video editing failed with error: \(error)")
//                parent.onComplete(nil)
//            }
//            editor.dismiss(animated: true, completion: nil)
//        }
//    }
//}
