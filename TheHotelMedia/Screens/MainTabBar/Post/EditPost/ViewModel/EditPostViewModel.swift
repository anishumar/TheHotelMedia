//
//  EditPostViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 05/03/25.
//

import SwiftUI
import PhotosUI
import SwiftfulRouting
import AVFoundation
import Combine
import SDWebImageSwiftUI

final class EditPostViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = CreatePostDataManager()
    var cancellables = Set<AnyCancellable>()
    
    let postData: PostData
    
    @Published var descriptionFieldText: String = ""
    @Published var photoPickerItem: PhotosPickerItem? = nil
    @Published var hasSelectedSomeMedia: Bool = false
    @Published var photoPickerItems: [PhotosPickerItem] = []
    @Published var selectedImage: UIImage? = nil
    @Published var selectedVideoUrl: URL? = nil
    @Published var trimmedVideoUrl: URL? = nil
    
    @AppStorage("videoLimit") var videoLimit: Double = 180
    @Published var selectedCameraImage: Image? = nil
    @Published var mediaAttachments: [MediaAttachment] = []
    @Published var existingMediaRefs: [MediaRef] = [] // Existing media from the post
    @Published var deletedMediaIDs: [String] = [] // Media IDs to delete
    @Published var tagProfiles: [SearchProfile] = []
    @Published var collaboratorProfiles: [SearchProfile] = []
    @Published var showPicker = false
    @Published var feeling: Feeling?
    @Published var showCameraPicker: Bool = false
    @Published var showLoadingAnimation: Bool = false
    @Published var postUpdated: Bool = false
    @Published var messageText: String = ""
    
    var onPostUpdated: (() -> Void)?
    
    let imagesColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 8, alignment: .top),
        GridItem(.flexible(), spacing: 10)
    ]
    
    init(router: AnyRouter, postData: PostData, onPostUpdated: (() -> Void)? = nil) {
        self.router = router
        self.postData = postData
        self.onPostUpdated = onPostUpdated
        loadPostData()
        addSubscriber()
        onPhotoPickerSelection()
    }
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    private func loadPostData() {
        // Load existing content
        descriptionFieldText = postData.content ?? ""
        
        // Load existing media
        if let mediaRefs = postData.mediaRef {
            existingMediaRefs = mediaRefs
            // Convert MediaRef to MediaAttachment for display
            Task {
                await loadExistingMedia(mediaRefs: mediaRefs)
            }
        }
        
        // Load feelings
        if let feelingsString = postData.feelings {
            // Parse feelings string (format: "emoji title")
            let components = feelingsString.components(separatedBy: " ")
            if components.count >= 2 {
                let emoji = components[0]
                let title = components.dropFirst().joined(separator: " ")
                feeling = Feeling(id: UUID().uuidString, emoji: emoji, title: title)
            }
        }
        
        // Load tagged profiles
        if let taggedRefs = postData.taggedRef {
            // Convert TaggedRef to SearchProfile
            tagProfiles = taggedRefs.compactMap { taggedRef in
                var profile = SearchProfile(id: taggedRef.id)
                profile.name = taggedRef.name
                profile.username = taggedRef.username
                profile.profilePic = taggedRef.profilePic
                profile.accountType = taggedRef.accountType
                profile.role = taggedRef.role
                return profile
            }
        }
    }
    
    private func loadExistingMedia(mediaRefs: [MediaRef]) async {
        var attachments: [MediaAttachment] = []
        
        for mediaRef in mediaRefs {
            if mediaRef.mediaType == "image" {
                // Load image from URL
                if let thumbnailURL = mediaRef.thumbnailURL ?? mediaRef.sourceURL,
                   let url = URL(string: thumbnailURL) {
                    if let image = await loadImage(from: url) {
                        let attachment = MediaAttachment(id: mediaRef.id ?? UUID().uuidString, type: .photo(image))
                        attachments.append(attachment)
                    }
                }
            } else if mediaRef.mediaType == "video" {
                // Load video thumbnail
                if let thumbnailURL = mediaRef.thumbnailURL,
                   let url = URL(string: thumbnailURL) {
                    if let thumbnail = await loadImage(from: url) {
                        // For existing videos, we create a placeholder attachment
                        // The actual video file is on the server, so we use a placeholder URL
                        // This attachment will be kept if not deleted, but won't be re-uploaded
                        let placeholderURL = URL(string: "https://placeholder.com")!
                        let attachment = MediaAttachment(id: mediaRef.id ?? UUID().uuidString, type: .video(thumbnail, placeholderURL))
                        attachments.append(attachment)
                    }
                }
            }
        }
        
        await MainActor.run {
            mediaAttachments = attachments
        }
    }
    
    private func loadImage(from url: URL) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            SDWebImageManager.shared.loadImage(
                with: url,
                options: [],
                progress: nil
            ) { image, _, _, _, _, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    func addSubscriber() {
        $tagProfiles
            .sink { profiles in
                print(profiles)
            }
            .store(in: &cancellables)
        
        $selectedImage
            .sink { [weak self] image in
                guard let self else { return }
                if let image {
                    showImageEditorScreen(image: image)
                }
            }
            .store(in: &cancellables)
        
        $selectedVideoUrl
            .sink { [weak self] url in
                guard let self else { return }
                if let url {
                    showVideoEditorScreen(videoUrl: url)
                }
            }
            .store(in: &cancellables)
        
        $selectedCameraImage
            .sink { [weak self] image in
                guard let self else { return }
                if let image {
                    Task {
                        if let uiImage = await image.render(convertToColorDepth: true) {
                            await MainActor.run {
                                self.selectedImage = uiImage
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func onPhotoPickerSelection() {
        $photoPickerItems
            .sink { [weak self] items in
                guard let self else { return }
                
                if !items.isEmpty {
                    photoPickerItem = items[0]
                    hasSelectedSomeMedia = true
                }
            }
            .store(in: &cancellables)
        
        $photoPickerItem
            .sink { [weak self] item in
                guard let self else { return }
                Task {
                    if let item {
                        await self.parsePhotoPickerItem(item)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func parsePhotoPickerItem(_ photoPickerItem: PhotosPickerItem) async {
        if photoPickerItem.isVideo {
            if let mov = try? await photoPickerItem.loadTransferable(type: VideoPickerTransferable.self) {
                await MainActor.run {
                    selectedVideoUrl = mov.url
                }
            }
        } else {
            guard
            let data = try? await photoPickerItem.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
            else { return }
            
            await MainActor.run {
                selectedImage = image
                hasSelectedSomeMedia = false
            }
        }
    }
    
    private func showImageEditorScreen(image: UIImage) {
        router.showScreen(.fullScreenCover) { router in
            EditImageView(viewModel: EditImageViewModel(router: router, image: image), returnedImage: { [weak self] image in
                guard let self else { return }
                let photoAttachment = MediaAttachment(id: UUID().uuidString, type: .photo(image))
                self.mediaAttachments.append(photoAttachment)
            }, onDismissed: { [weak self] in
                guard let self else { return }
                hasSelectedSomeMedia = false
            })
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    private func showVideoEditorScreen(videoUrl: URL) {
        let limit = videoLimit
        router.showScreen(.fullScreenCover) { router in
            VideoEditorView(videoURL: videoUrl, limit: limit) { [weak self] editedVideoURL in
                guard let self else { return }
                if let editedVideoURL {
                    Task {
                        do {
                            // Generate video thumbnail asynchronously
                            if let thumbnail = try await editedVideoURL.generateVideoThumbnail() {
                                // Update UI on the main actor
                                await MainActor.run {
                                    let videoAttachment = MediaAttachment(id: UUID().uuidString, type: .video(thumbnail, editedVideoURL))
                                    self.mediaAttachments.append(videoAttachment)
                                    self.hasSelectedSomeMedia = false
                                }
                            }
                        } catch {
                            await MainActor.run {
                                print("Failed to generate thumbnail: \(error)")
                                self.hasSelectedSomeMedia = false
                            }
                        }
                    }
                } else {
                    hasSelectedSomeMedia = false
                }
            }
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
    
    func removeMediaAttachment(at index: Int) {
        let attachment = mediaAttachments[index]
        
        // Check if this is an existing media (has an ID from MediaRef)
        let mediaID = attachment.id
        if existingMediaRefs.contains(where: { $0.id == mediaID }) {
            // Add to deleted media IDs
            if !deletedMediaIDs.contains(mediaID) {
                deletedMediaIDs.append(mediaID)
            }
        }
        
        mediaAttachments.remove(at: index)
    }
    
    func showBottomAlert(message: String) {
        router.showModal(transition: .move(edge: .bottom)) {
            BottomAlert(message: message)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 ) {
            self.router.dismissModal()
        }
    }
}

// MARK: - Networking

extension EditPostViewModel {
    
    func updatePost() {
        showLoadingAnimation = true
        
        Task {
            var parameters: [String: Any] = [:]
            var tagged: [String] = []
            
            if !descriptionFieldText.isEmpty {
                parameters.updateValue(descriptionFieldText, forKey: "content")
            }
            
            if let feeling {
                parameters.updateValue("\(feeling.emoji) \(feeling.title)", forKey: "feelings")
            }
            
            if !tagProfiles.isEmpty {
                for profile in tagProfiles {
                    tagged.append(profile.id)
                }
            }
            
            // Filter out new media attachments (those not in existingMediaRefs)
            // Only include attachments that are truly new (not from existing media)
            let newMediaAttachments = mediaAttachments.filter { attachment in
                // Check if this attachment ID exists in existingMediaRefs
                let isExisting = existingMediaRefs.contains(where: { $0.id == attachment.id })
                // Also check if it's a placeholder video (existing video)
                if case .video(_, let url) = attachment.type {
                    if url.absoluteString == "https://placeholder.com" {
                        return false // Don't upload placeholder videos
                    }
                }
                return !isExisting
            }
            
            do {
                let result = try await dataManager.updatePost(
                    postID: postData.id ?? "",
                    attachments: newMediaAttachments,
                    tagged: tagged,
                    parameters: parameters,
                    deletedMedia: deletedMediaIDs
                )
                
                await MainActor.run {
                    showLoadingAnimation = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        postUpdated = true
                        onPostUpdated?()
                        dismissScreen()
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingAnimation = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "an_error_occured_while_updating_the_post".localized(LocalizationManager.shared.language))
                }
            }
        }
    }
}

