//
//  CreatePostViewModel.swift
//  HotelMedia
//
//  Created by MAC on 07/08/24.
//

import SwiftUI
import PhotosUI
import SwiftfulRouting
import AVFoundation
import Combine
import QuickLook


final class CreatePostViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = CreatePostDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var descriptionFieldText: String = ""
    @Published var photoPickerItem: PhotosPickerItem? = nil
    @Published var hasSelectedSomeMedia: Bool = false
    @Published var photoPickerItems: [PhotosPickerItem] = []
    @Published var selectedImage: UIImage? = nil
    @Published var selectedVideoUrl: URL? = nil
    @Published var trimmedVideoUrl: URL? = nil
    @Published var reviewPlace: ProfileData? = nil
    @Published var selectedCameraImage: Image? = nil
    @Published var addressString: String = ""
    @Published var mediaAttachments: [MediaAttachment] = []
    @Published var tags: [String] = [
        "@Iida",
        "@Bakugo",
        "@All_Might",
        "@Uraraka_chan",
        "@Ashido",
        "@Shoto",
        "@Kirishima"
    ]
    @Published var tagProfiles: [SearchProfile] = []
    @Published var showPicker = false
    @Published var feeling: Feeling?
    @Published var showCameraPicker: Bool = false
    @Published var showLoadingAnimation: Bool = false
    @Published var postUploaded: Bool = false
    @Published var messageText: String = ""
    @Published var profileImage: String = ""
    @Published var coverImage: String = ""
    
    @AppStorage("videoLimit") var videoLimit: Double = 30
    @AppStorage("newPostCreated") var newPostCreated: Bool = false
    
    var onPostCreated: (() -> Void)?
    
    
    let imagesColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 8, alignment: .top),
        GridItem(.flexible(), spacing: 10)
    ]
    
    let tagColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 100)),
        GridItem(.adaptive(minimum: 100))
    ]
    
    init(router: AnyRouter, onPostCreated: (() -> Void)? = nil) {
        self.router = router
        self.onPostCreated = onPostCreated
        addSubscriber()
        onPhotoPickerSelection()
        print(videoLimit, "Limit")
    }
    
    func dismissScreen() {
        router.dismissScreen()
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.router.showScreen(.fullScreenCover) { router in
                            VideoEditorView(videoURL: url, limit: self.videoLimit) { [weak self] editedVideoURL in
                                guard let self else { return }
                                trimmedVideoUrl = editedVideoURL
                                hasSelectedSomeMedia = false
                            }
                        }
                    }
//                    trimmedVideoUrl = url
//                    hasSelectedSomeMedia = false
                }
            }
            .store(in: &cancellables)
        
        $trimmedVideoUrl
            .sink { [weak self] url in
                guard let self else { return }
                Task {
                    if let url {
                        do {
                            // Generate video thumbnail asynchronously
                            if let thumbnail = try await url.generateVideoThumbnail() {
                                // Update UI on the main actor
                                await MainActor.run {
                                    let videoAttachment = MediaAttachment(id: UUID().uuidString, type: .video(thumbnail, url))
                                    self.mediaAttachments.append(videoAttachment)
                                }
                            }
                        } catch {
                            print("Failed to generate thumbnail: \(error)")
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        
        $reviewPlace
            .sink { [weak self] place in
                guard let self else { return }
                if let place {
                    if let address = place.businessProfileRef?.address {
                        if let street = address.street {
                            if street.isEmpty {
                                addressString = "\(place.businessProfileRef?.name ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                            } else {
                                addressString = "\(address.street ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                            }
                        }
                    }
                    
                    if let id = place.businessProfileRef?.id, !id.isEmpty {
                        coverImage = place.businessProfileRef?.coverImage ?? ""
                        profileImage = place.businessProfileRef?.profilePic?.small ?? ""
                        
                    } else {
                        let mapApiKey = "&key=\(googlePlacesKey)"
                        
                        if let coverImage = place.businessProfileRef?.coverImage {
                            self.coverImage = coverImage + mapApiKey
                        }
                        
                        if let profileImage = place.businessProfileRef?.profilePic?.small {
                            self.profileImage = profileImage + mapApiKey
                        }
                    }
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
    
    
    func showCheckinScreen() {
        router.showScreen(.fullScreenCover) { router in
            CheckinScreen(viewModel: CheckinViewModel(router: router, onSelectingPlace: { [weak self] place in
                guard let self else { return }
                reviewPlace = place
            }))
            .environmentObject(ThemeManager.shared)
        }
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

extension CreatePostViewModel {
    
    func createPost() {
        
        showLoadingAnimation = true
        
        Task {
            var parameters: [String: Any] = [:]
            var tagged : [String] = []
            
            if !descriptionFieldText.isEmpty {
                parameters.updateValue(descriptionFieldText, forKey: "content")
            }
            
            if let placeName = reviewPlace?.businessProfileRef?.name,
               let lat = reviewPlace?.businessProfileRef?.address?.lat,
               let lng = reviewPlace?.businessProfileRef?.address?.lng {
                parameters.updateValue(placeName, forKey: "placeName")
                parameters.updateValue("\(lat)", forKey: "lat")
                parameters.updateValue("\(lng)", forKey: "lng")
            }
            
            if let feeling {
                parameters.updateValue("\(feeling.emoji) \(feeling.title)" , forKey: "feelings")
            }
            
            
            if !tagProfiles.isEmpty {
                for profile in tagProfiles {
                    tagged.append(profile.id)
                }
            }
            
            do {
                let result = try await dataManager.createPost(attachments: mediaAttachments, tagged: tagged, parameters: parameters)
                
                await MainActor.run {
                    showLoadingAnimation = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        postUploaded = true
                        newPostCreated = true
                        onPostCreated?()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) { [weak self] in
                            guard let self else { return }
                            dismissScreen()
                        }
                    } else {
                        messageText = result.message
                        ErrorModalManager.showErrorModal(router: router, errorText: messageText)
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingAnimation = false
                }
                print(error)
            }
        }
    }
    
    
    func createPostBackground() {
        var parameters: [String: Any] = [:]
        var tagged : [String] = []
        
        if !descriptionFieldText.isEmpty {
            parameters.updateValue(descriptionFieldText, forKey: "content")
        }
        
        if let placeName = reviewPlace?.businessProfileRef?.name,
           let lat = reviewPlace?.businessProfileRef?.address?.lat,
           let lng = reviewPlace?.businessProfileRef?.address?.lng {
            parameters.updateValue(placeName, forKey: "placeName")
            parameters.updateValue("\(lat)", forKey: "lat")
            parameters.updateValue("\(lng)", forKey: "lng")
        }
        
        if let feeling {
            parameters.updateValue("\(feeling.emoji) \(feeling.title)" , forKey: "feelings")
        }
        
        
        if !tagProfiles.isEmpty {
            for profile in tagProfiles {
                tagged.append(profile.id)
            }
        }
        
        dataManager.createPostBackground(attachments: mediaAttachments, tagged: tagged, parameters: parameters)
        print("Uploading started")
    }
}
