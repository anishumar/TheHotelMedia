//
//  FileDownloadManager.swift
//  TheHotelMedia
//
//  Created by MAC on 07/01/25.
//

import SwiftUI
import UserNotifications

class FileDownloadManager: ObservableObject {
    
    static let shared = FileDownloadManager()
    
    private let fileManager = FileManager.default

    func downloadFile(from urlString: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            self.showErrorNotification(message: "Invalid URL.")
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data(contentsOf: url)

                guard let documentsDirectory = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                    DispatchQueue.main.async {
                        self.showErrorNotification(message: "Unable to access Documents directory.")
                        completion(.failure(NSError(domain: "Documents Directory Error", code: -2, userInfo: nil)))
                    }
                    return
                }

                var fileURL = documentsDirectory.appendingPathComponent(fileName)
                var counter = 1

                // Handle duplicate filenames
                while self.fileManager.fileExists(atPath: fileURL.path) {
                    let baseName = fileName.deletingPathExtension
                    let fileExtension = fileName.pathExtension
                    let newFileName = fileExtension.isEmpty
                        ? "\(baseName)(\(counter))"
                        : "\(baseName)(\(counter)).\(fileExtension)"
                    fileURL = documentsDirectory.appendingPathComponent(newFileName)
                    counter += 1
                }

                try data.write(to: fileURL)

                DispatchQueue.main.async {
//                    self.showSuccessNotification(fileName: fileURL.lastPathComponent, fileURL: fileURL)
                    completion(.success(fileURL))
                }

            } catch {
                DispatchQueue.main.async {
                    print(error.localizedDescription, error)
                    self.showErrorNotification(message: "Download failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    private func showSuccessNotification(fileName: String, fileURL: URL) {
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "Tap to open \(fileName)"
        content.sound = .default
        content.userInfo = ["fileURL": fileURL.absoluteString]

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing success notification: \(error.localizedDescription)")
            }
        }
    }

    private func showErrorNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Download Failed"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing error notification: \(error.localizedDescription)")
            }
        }
    }

    // Optional: Handle file opening when notification is tapped
    func handleNotificationResponse(response: UNNotificationResponse) {
        if let fileURLString = response.notification.request.content.userInfo["fileURL"] as? String,
           let fileURL = URL(string: fileURLString) {
            openFile(at: fileURL)
        }
    }

    func openFile(at fileURL: URL) {
        DispatchQueue.main.async {
            do {
                // Fetch the data from the file URL
                let fileData = try Data(contentsOf: fileURL)

                // Create an activity view controller to share the file data
                let activityViewController = UIActivityViewController(activityItems: [fileData], applicationActivities: nil)

                // Find the active scene and its window
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(activityViewController, animated: true, completion: nil)
                } else {
                    print("Unable to find a root view controller to present the activity view controller.")
                }
            } catch {
                print("Failed to load file data: \(error.localizedDescription)")
            }
        }
    }
}

private extension String {
    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }

    var pathExtension: String {
        (self as NSString).pathExtension
    }
}

