//
//  CreateReviewViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 25/09/24.
//

import Foundation
import SwiftfulRouting
import Combine
import PhotosUI
import SwiftUI


class CreateReviewViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = ReviewDataManager()
    let checkInDataManager = PlacesDataManager()
    var cancelables = Set<AnyCancellable>()
    @Published var descriptionFieldText: String = ""
    @Published var reviewPlace: ProfileData? = nil
    @Published var showLoadingIndicator: Bool = false
    @Published var questionRatings: [ReviewQuestionRating] = []
    @Published var selectedImages: [UIImage] = []
    @Published var mediaAttachments: [MediaAttachment] = []
    @Published var pickerConfig = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
    @Published var showPicker: Bool = false
    @Published var profileImage: String = ""
    @Published var coverImage: String = ""
    @Published var addressString: String = ""
    @Published var nextButtonDisabled: Bool = true
    @Published var showLoadingAnimation: Bool = false
    @Published var hasSelectedSomeMedia: Bool = false
    @Published var postUploaded: Bool = false
    @Published var photoPickerItems: [PhotosPickerItem] = []
    @Published var photoPickerItem: PhotosPickerItem? = nil
    @Published var selectedVideoUrl: URL? = nil
    @Published var selectedImage: UIImage? = nil
    @Published var trimmedVideoUrl: URL? = nil
    
    @AppStorage("videoLimit") var videoLimit: Double = 180
    
    var placeID: String = ""
    
    @AppStorage("newPostCreated") var newPostCreated: Bool = false
    
    var onReviewCreated: (() -> Void)?
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    init(router: AnyRouter, reviewPlace: ProfileData? = nil, businessProfileID: String? = nil, placeID: String? = nil, onReviewCreated: (() -> Void)? = nil) {
        self.router = router
        self.onReviewCreated = onReviewCreated
        addSubscribers()
        self.reviewPlace = reviewPlace
        
        if let businessProfileID, let placeID {
            self.placeID = placeID
            if let decryptedID = EncryptionHelper.decrypt(businessProfileID) {
                getReviewProfile(placeID: placeID, businessProfileID: decryptedID)
            }
        }
    }
    
    
    func addSubscribers() {
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
                    
                    var array: [ReviewQuestionRating] = []
                    
                    if let reviewQuestions = place.reviewQuestions {
                        for question in reviewQuestions {
                            array.append(ReviewQuestionRating(questionID: question.id, rating: nil))
                        }
                    }
                    
                    self.questionRatings = array
                }
            }
            .store(in: &cancelables)
        
        $questionRatings
            .combineLatest($descriptionFieldText)
            .sink { [weak self] ratings, description in
                guard let self else { return }
                
                if ratings.isEmpty {
                    nextButtonDisabled = description.isEmpty
                } else {
                    var bool = true
                    for rating in ratings {
                        if rating.rating == nil {
                            bool = true
                            break
                        } else {
                            bool = false
                        }
                    }
                    
                    nextButtonDisabled = bool
                }
            }
            .store(in: &cancelables)
        
        $photoPickerItems
            .sink { [weak self] items in
                guard let self else { return }
                
                if !items.isEmpty {
                    photoPickerItem = items[0]
                    hasSelectedSomeMedia = true
                }
                
            }
            .store(in: &cancelables)
        
        
        $photoPickerItem
            .sink { [weak self] item in
                guard let self else { return }
                Task {
                    if let item {
                        await self.parsePhotoPickerItem(item)
                    }
                    
                }
            }
            .store(in: &cancelables)
        
        $selectedImage
            .sink { [weak self] image in
                guard let self else { return }
                if let image {
                    showImageEditorScreen(image: image)
                }
            }
            .store(in: &cancelables)
        
        $selectedVideoUrl
            .sink { [weak self] url in
                guard let self else { return }
                if let url {
                    router.showScreen(.fullScreenCover) { router in
                        VideoEditorView(videoURL: url, limit: self.videoLimit) { [weak self] editedVideoURL in
                            guard let self else { return }
                            trimmedVideoUrl = editedVideoURL
                            hasSelectedSomeMedia = false
                        }
                    }
//                    trimmedVideoUrl = url
//                    hasSelectedSomeMedia = false
                }
            }
            .store(in: &cancelables)
        
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
            .store(in: &cancelables)
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
    
    
    func handlePickedImages(_ results: [PHPickerResult]) {
        let group = DispatchGroup()
        var newImages: [UIImage] = []
        
        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    newImages.append(image)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.selectedImages += newImages
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
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showCheckinScreen() {
        router.showScreen(.fullScreenCover) { router in
            CheckinScreen(viewModel: CheckinViewModel(router: router, onSelectingPlace: { [weak self] place in
                guard let self else { return }
                reviewPlace = place
            }))
            .environmentObject(ThemeManager.shared)
            .navigationBarBackButtonHidden()
        }
    }
}


// MARK: - Networking
extension CreateReviewViewModel {
    
    func createReview() {
        guard !descriptionFieldText.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "Please write a brief description.")
            return
        }
        
        showLoadingAnimation = true
        Task {
            do {
                var parameters: [String: Any] = [:]
                
                parameters.updateValue(descriptionFieldText, forKey: "content")
                parameters.updateValue(reviewPlace?.businessProfileRef?.placeID ?? placeID, forKey: "placeID")
                
                if let id = reviewPlace?.businessProfileRef?.id, !id.isEmpty {
                    if let type = reviewPlace?.businessProfileRef?.type {
                        if type == "google-business-profile" {
                            parameters.updateValue(id, forKey: "anonymousUserID")
                            parameters.updateValue("", forKey: "businessProfileID")
                            
                        } else {
                            parameters.updateValue(id, forKey: "businessProfileID")
                            parameters.updateValue("", forKey: "anonymousUserID")
                        }
                    }
                    
                } else {
                    parameters.updateValue(reviewPlace?.businessProfileRef?.name ?? "", forKey: "name")
                    parameters.updateValue(reviewPlace?.businessProfileRef?.address?.street ?? "", forKey: "street")
                    parameters.updateValue(reviewPlace?.businessProfileRef?.address?.city ?? "", forKey: "city")
                    parameters.updateValue(reviewPlace?.businessProfileRef?.address?.state ?? "", forKey: "state")
                    parameters.updateValue(reviewPlace?.businessProfileRef?.address?.zipCode ?? "", forKey: "zipCode")
                    parameters.updateValue(reviewPlace?.businessProfileRef?.address?.country ?? "", forKey: "country")
                    parameters.updateValue(reviewPlace?.businessProfileRef?.address?.lat ?? "", forKey: "lat")
                    parameters.updateValue(reviewPlace?.businessProfileRef?.address?.lng ?? "", forKey: "lng")
                    
                }
                
                let result = try await dataManager.createReview(parameters: parameters, attachments: mediaAttachments, ratings: questionRatings.isEmpty ? [ReviewQuestionRating(questionID: "not-indexed", rating: 4)] : questionRatings)
                
                await MainActor.run {
                    showLoadingAnimation = false
//                    ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        postUploaded = true
                        newPostCreated = true
                        onReviewCreated?()
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
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
    
    
    func getReviewProfile(placeID: String, businessProfileID: String) {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await checkInDataManager.getBusinessProfile(placeID: placeID, businessProfileID: businessProfileID)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        if let data = result.data {
                            reviewPlace = data
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
                print(error)
            }
        }
    }
}
