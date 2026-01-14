//
//  StoryUploadNotificationManager.swift
//  TheHotelMedia
//
//  Created by MAC on 31/01/25.
//

import Foundation
import UserNotifications

class StoryUploadNotificationManager {
    static let shared = StoryUploadNotificationManager()
    
    private let notificationIdentifier = "storyUploadNotification"
    
    private init() {}
    
    /// Send a story upload progress notification
    /// - Parameters:
    ///   - progress: Upload progress (0.0 to 1.0)
    ///   - isCompleted: Whether upload is completed
    ///   - isFailed: Whether upload failed
    ///   - errorMessage: Error message if failed
    func sendStoryUploadNotification(
        progress: Double? = nil,
        isCompleted: Bool = false,
        isFailed: Bool = false,
        errorMessage: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        
        if isFailed {
            content.title = "Story Upload Failed"
            content.body = errorMessage ?? "Failed to upload your story. Please try again."
            content.sound = .defaultCritical
        } else if isCompleted {
            content.title = "Story Uploaded"
            content.body = "Your story has been uploaded successfully."
            content.sound = .default
        } else if let progress = progress {
            let percentage = Int(progress * 100)
            content.title = "Uploading Story"
            content.body = "Upload in progress: \(percentage)%"
            content.sound = nil // No sound for progress updates
        } else {
            content.title = "Uploading Story"
            content.body = "Your story is being uploaded..."
            content.sound = nil
        }
        
        // Use a unique identifier for each progress update to replace previous notifications
        let identifier = isCompleted || isFailed ? notificationIdentifier : "\(notificationIdentifier)_progress"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [StoryUploadNotification] Failed to send notification: \(error.localizedDescription)")
            } else {
                print("✅ [StoryUploadNotification] Notification sent - Progress: \(progress?.description ?? "N/A"), Completed: \(isCompleted), Failed: \(isFailed)")
            }
        }
    }
}
