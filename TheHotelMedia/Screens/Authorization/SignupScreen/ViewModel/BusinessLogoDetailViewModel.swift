//
//  BusinessLogoDetailViewModel.swift
//  HotelMedia
//
//  Created by MAC on 07/08/24.
//

import SwiftUI
import PhotosUI
import SwiftfulRouting
import Combine

final class BusinessLogoDetailViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = BusinessLogoDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var logoImage: UIImage? = nil
    @Published var logoCameraImage: Image? = nil
    @Published var cameraImage: Image? = nil
    @Published var selectedLogoImage: Image?
    @Published var images: [UIImage] = []
    @Published var shouldOpenCamera: Bool = false
    @Published var shouldOpenImagePicker: Bool = false
    @Published var shouldOpenLogoImagePicker: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var nextButtonDisabled: Bool = true
    @Published var errorText: String = ""
    @Published var wentToNextScreen: Bool = false
    @Published var shouldOpenLogoCameraPicker: Bool = false
    @Published var shouldOpenCameraPicker: Bool = false
    @Published var showPickerOptions: Bool = false
    @Published var showLogoPickerOptions: Bool = false
    
//    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    @Published var pickerConfig = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
    
    var logoPickerConfig: PHPickerConfiguration {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .any(of: [.images])
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        return config
    }
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    func addSubscribers() {
        
        $logoImage
            .sink { [weak self] image in
                guard let self else { return }
                
                if let image, !wentToNextScreen {
                    showCropView(image: Image(uiImage: image))
                    logoImage = nil
                }
            }
            .store(in: &cancellables)
        
        $logoCameraImage
            .sink { [weak self] image in
                guard let self else { return }
                
                if let image, !wentToNextScreen {
                    showCropView(image: image)
                    logoCameraImage = nil
                }
            }
            .store(in: &cancellables)
        
        $selectedLogoImage
            .combineLatest($images)
            .sink { [weak self] (image, images) in
                guard let self else { return }
                nextButtonDisabled = image == nil || images.isEmpty
            }
            .store(in: &cancellables)
        
        $cameraImage
            .sink { [weak self] image in
                guard let self else { return }
                Task {
                    if let uiImage = await image?.render(convertToColorDepth: true) {
                        await MainActor.run {
                            self.images.append(uiImage)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    
    func showNextScreen() {
        router.showScreen(.push) { router in
            SupportingDocumentsView(viewModel: SupportingDocumentsViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showCropView(image: Image) {
        router.showScreen(.fullScreenCover) { router in
            CropView(crop: .square, image: image) { [weak self] image, isCropped in
                guard let self else { return }
                if isCropped {
                    if let image {
                        self.selectedLogoImage = image
                    }
                }
            }
            .environmentObject(ThemeManager.shared)
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
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
            self.images += newImages
        }
    }
    
    
    func handlePickedLogoImage(_ results: [PHPickerResult]) {
        let group = DispatchGroup()
        var newImage: UIImage? = nil
        
        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    newImage = image
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let newImage {
                self.logoImage = newImage
            }
        }
    }
    
    
    func cancelSubcriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    
    func showErrorModal() {
        router.showModal(transition: .move(edge: .bottom)) {
            BottomAlert(message: self.errorText)
        }
        print(self.errorText)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) {
            self.router.dismissModal()
            self.errorText = ""
        }
    }
}


// MARK: - Networking
extension BusinessLogoDetailViewModel {
    
    func uploadBusinessProfilePic() {
        guard let selectedLogoImage else {
                print("Returned here")
            return
        }
        
//        guard networkMonitor.isConnected else {
//            errorText = "No internet connection. Please try again."
//            showErrorModal()
//            return
//        }
        
//        wentToNextScreen = true
//        showNextScreen()
//        return
        
        guard images.count <= 10 else {
            ErrorModalManager.showErrorModal(router: router, errorText: "You cannot upload more than 10 property images.")
            return
        }
        
        showLoadingIndicator = true
        Task {
            do {
                guard let uiImage = await selectedLogoImage.render(convertToColorDepth: true, scale: Constants.scale) else {
                    await MainActor.run {
                        showLoadingIndicator = false
                    }
                    return
                }
                
                let result = try await dataManager.uploadProfilePic(uiImage: uiImage, parameters: [:])
                
                await MainActor.run {
                    showLoadingIndicator = false
                    print(result.message)
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        uploadPropertyImages()
                    } else {
                        errorText = result.message
                        ErrorModalManager.showErrorModal(router: router, errorText: errorText)
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
    
    
    func uploadPropertyImages() {
        
        showLoadingIndicator = true
        
        Task {
            var files: [FileModel] = []
            
            var newImages: [UIImage] = []
            
            for image in self.images {
                let newImage = Image(uiImage: image)
                if let uiImage = await newImage.render(convertToColorDepth: true) {
                    newImages.append(uiImage)
                }
            }
            
            for image in newImages {
                if let jpegData = image.jpegData(compressionQuality: 0.8) {
                    let file = FileModel(data: jpegData, parameterName: "images", fileName: "images.jpeg", mimeType: "image/jpeg")
                    files.append(file)
                } else {
                    print("Unable to fetch jpegData")
                }
            }
            
            do {
                let result = try await dataManager.uploadPropertyImages(files: files)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        wentToNextScreen = true
                        showNextScreen()
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    print(error)
                }
            }
        }
    }
}
