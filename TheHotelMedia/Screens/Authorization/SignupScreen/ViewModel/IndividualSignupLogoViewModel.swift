//
//  IndividualSignupLogoViewModel.swift
//  HotelMedia
//
//  Created by MAC on 07/08/24.
//

import SwiftUI
import SwiftfulRouting
import PhotosUI
import Combine


final class IndividualSignupLogoViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = IndividualProfilePicDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var image: Image? = nil
    @Published var selectedImage: UIImage? = nil
    @Published var returnedImage: UIImage? = nil
    @Published var croppedImage: Image?
    @Published var shouldPresentImagePicker = false
    @Published var shouldPresentCamera = false
    @Published var showLoadingIndicator: Bool = false
    var wentToNextScreen: Bool = false
    @Published var errorText: String = ""
    
//    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func addSubscribers() {
        $image
            .sink { [weak self]  image in
                guard let self else { return }
                
                if let image, !wentToNextScreen {
                    self.showCropView(image: image)
                }
            }
            .store(in: &cancellables)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showNextScreen() {
        router.showScreen(.push) { router in
            TermsAndConditionView(viewModel: TermsAndConditionViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    func showCropView(image: Image) {
        router.showScreen(.fullScreenCover) { router in
            CropView(crop: .square, image: image) { [ weak self ] image, isCropped in
                guard let self else { return }
                if isCropped {
                    croppedImage = image
                }
            }
            .environmentObject(ThemeManager.shared)
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
extension IndividualSignupLogoViewModel {
    func uploadProfilePic() {
        
        
        guard let croppedImage else {
                print("Returned here")
            return
        }
        
//        guard networkMonitor.isConnected else {
//            errorText = "No internet connection. Please try again."
//            showErrorModal()
//            return
//        }
        
        showLoadingIndicator = true
        Task {
            do {
                guard let uiImage = await croppedImage.render(convertToColorDepth: true, scale: Constants.scale) else {
                    await MainActor.run {
                        showLoadingIndicator = false
                    }
                    return
                }
                
                let result = try await dataManager.uploadProfilePic(uiImage: uiImage, parameters: [:])
                
                await MainActor.run {
                    showLoadingIndicator = false
                }
                
                print(result.message)
                if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                    wentToNextScreen = true
                    showNextScreen()
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
