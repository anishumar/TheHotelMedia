//
//  UploadMenuViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import SwiftUI
import Combine
import SwiftfulRouting

class UploadMenuViewModel: ObservableObject {
    @Published var selectedFiles: [URL] = []
    @Published var isUploading: Bool = false
    @Published var errorMessage: String?
    
    let dataManager = RestaurantMenuDataManager()
    var router: AnyRouter
    var onUploadSuccess: () -> Void
    
    init(router: AnyRouter, onUploadSuccess: @escaping () -> Void) {
        self.router = router
        self.onUploadSuccess = onUploadSuccess
    }
    
    func addFiles(urls: [URL]) {
        for url in urls {
            let isSecurityScoped = url.startAccessingSecurityScopedResource()
            defer { if isSecurityScoped { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let data = try Data(contentsOf: url)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_" + url.lastPathComponent)
                try data.write(to: tempURL)
                selectedFiles.append(tempURL)
            } catch {
                errorMessage = "Failed to access file: \(url.lastPathComponent)"
            }
        }
    }
    
    func uploadMenu() {
        guard !selectedFiles.isEmpty else { return }
        
        isUploading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await dataManager.uploadRestaurantMenu(fileURLs: selectedFiles)
                await MainActor.run {
                    self.isUploading = false
                    if response.status {
                        self.onUploadSuccess()
                        self.router.dismissScreen()
                    } else {
                        self.errorMessage = response.message
                    }
                }
            } catch {
                await MainActor.run {
                    self.isUploading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func dismiss() {
        router.dismissScreen()
    }
}
