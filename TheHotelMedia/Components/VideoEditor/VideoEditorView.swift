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

    func makeUIViewController(context: Context) -> UIVideoEditorController {
        UINavigationBar.appearance().tintColor = UIColor(ThemeManager.shared.currentTheme.label)
        let editor = UIVideoEditorController()
        editor.videoMaximumDuration = limit
        editor.videoPath = videoURL.path
        editor.delegate = context.coordinator
        editor.videoQuality = .typeHigh
        return editor
    }

    func updateUIViewController(_ uiViewController: UIVideoEditorController, context: Context) {
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
