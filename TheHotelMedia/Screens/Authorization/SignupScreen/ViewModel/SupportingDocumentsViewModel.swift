//
//  SupportingDocumentsViewModel.swift
//  HotelMedia
//
//  Created by MAC on 09/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


final class SupportingDocumentsViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = BusinessDocumentManager()
    var cancellables = Set<AnyCancellable>()
    @Published var addressProofImage: Image?
    @Published var selectedAddressProofImage: Image?
    @Published var businessRegistrationImage: Image?
    @Published var selectedBusinessRegistrationImage: Image?
    @Published var shouldPresentImagePickerLeftField = false
    @Published var shouldPresentImagePickerRightField = false
    @Published var shouldPresentCameraLeftField = false
    @Published var shouldPresentCameraRightField = false
    @Published var showDialogBox: Bool = false
    @Published var fieldType: FieldType = .left
    @Published var showFileImporter: Bool = false
    @Published var leftPdfData: Data? = nil
    @Published var rightPdfData: Data? = nil
    @Published var leftPdfName: String?
    @Published var rightPdfName: String?
    @Published var showLoadingIndicator: Bool = false
    @Published var isRegistrationDocumentSelected: Bool = false
    @Published var isAddressDocumentSelected: Bool = false
    @Published var nextButtonDisabled: Bool = false
    @Published var errorText: String = ""
    
//    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func addSubscribers() {
        $businessRegistrationImage
            .sink { [weak self] image in
                guard let self else { return }
                if let image {
                    self.leftPdfData = nil
                    self.leftPdfName = nil
                    showCropViewForRegisterationImage(image: image)
                    businessRegistrationImage = nil
                }
            }
            .store(in: &cancellables)
        
        $addressProofImage
            .sink { [weak self] image in
                guard let self else { return }
                if let image {
                    self.rightPdfData = nil
                    self.rightPdfName = nil
                    showCropViewForAddressImage(image: image)
                    addressProofImage = nil
                }
            }
            .store(in: &cancellables)
        
        $leftPdfData
            .sink { [weak self] data in
                guard let self else { return }
                if data != nil {
                    selectedBusinessRegistrationImage = nil
                    isRegistrationDocumentSelected = true
                }
            }
            .store(in: &cancellables)
        
        $rightPdfData
            .sink { [weak self] data in
                guard let self else { return }
                if data != nil {
                    selectedAddressProofImage = nil
                    isAddressDocumentSelected = true
                }
            }
            .store(in: &cancellables)
        
        $selectedBusinessRegistrationImage
            .sink { [weak self] image in
                guard let self else { return }
                if image != nil {
                    isRegistrationDocumentSelected = true
                }
            }
            .store(in: &cancellables)
        
        $selectedAddressProofImage
            .sink { [weak self] image in
                guard let self else { return }
                
                if image != nil {
                    isAddressDocumentSelected = true
                }
            }
            .store(in: &cancellables)
        
        $isRegistrationDocumentSelected
            .combineLatest($isAddressDocumentSelected)
            .sink { [weak self] (bool1, bool2) in
                guard let self else { return }
                
                nextButtonDisabled = !bool1 || !bool2
            }
            .store(in: &cancellables)
        
    }
    
    
    func showCropViewForRegisterationImage(image: Image) {
        let width = UIScreen.main.bounds.width - 100
        router.showScreen(.fullScreenCover) { _ in
            CropView(crop: .custom(CGSize(width: width, height: width * 1.414)), image: image) { [weak self] image, isCropped in
                guard let self else { return }
                if isCropped {
                    selectedBusinessRegistrationImage = image
                }
            }
            .environmentObject(ThemeManager.shared)
        }
    }
    
    
    func showCropViewForAddressImage(image: Image) {
        let width = UIScreen.main.bounds.width - 100
        router.showScreen(.fullScreenCover) { _ in
            CropView(crop: .custom(CGSize(width: width, height: width * 1.414)), image: image) { [weak self] image, isCropped in
                guard let self else { return }
                if isCropped {
                    selectedAddressProofImage = image
                }
            }
            .environmentObject(ThemeManager.shared)
        }
    }
    
    
    func showNextScreen() {
        router.showScreen(.push) { router in
            TermsAndConditionView(viewModel: TermsAndConditionViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func pdfSelected(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                url.stopAccessingSecurityScopedResource()
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                handlePdfData(data: data, url: url)
                url.stopAccessingSecurityScopedResource()
                
            } catch {
                print("Error obtaining content of pdf from url \(error)")
            }
            
        case .failure(let error):
            print("Error loading pdf \(error)")
        }
    }
    
    
    func handlePdfData(data: Data, url: URL) {
        if fieldType == .left {
            leftPdfData = data
            leftPdfName = url.lastPathComponent
            businessRegistrationImage = nil
        }
        
        if fieldType == .right {
            rightPdfData = data
            rightPdfName = url.lastPathComponent
            addressProofImage = nil
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

extension SupportingDocumentsViewModel {
    
    func uploadDocuments() {
        
//        guard networkMonitor.isConnected else {
//            errorText = "No internet connection. Please try again."
//            showErrorModal()
//            return
//        }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let files = await getFiles()
                
                let result = try await dataManager.uploadDocuments(files: files)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    print(result.message)
                    
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        showNextScreen()
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
    
    func getFiles() async -> [FileModel] {
        var files: [FileModel] = []
        
        if let leftPdfData,
           let leftPdfName {
            
            let file = FileModel(data: leftPdfData, parameterName: "businessRegistration", fileName: leftPdfName, mimeType: "application/pdf")
            files.append(file)
            
        } else if let selectedBusinessRegistrationImage {
            
            let imageData = await getImageJpegData(image: selectedBusinessRegistrationImage)
            
            if let imageData {
                let file = FileModel(data: imageData, parameterName: "businessRegistration", fileName: "businessRegistration.jpeg", mimeType: "image/jpeg")
                files.append(file)
            }
        }
        
        
        if let rightPdfData,
           let rightPdfName {
            
            let file = FileModel(data: rightPdfData, parameterName: "addressProof", fileName: rightPdfName, mimeType: "application/pdf")
            files.append(file)
            
        } else if let selectedAddressProofImage {
            
            let imageData = await getImageJpegData(image: selectedAddressProofImage)
            
            if let imageData {
                let file = FileModel(data: imageData, parameterName: "addressProof", fileName: "addressProof.jpeg", mimeType: "image/jpeg")
                files.append(file)
            }
        }
        
        return files
    }
    
    
    func getImageJpegData(image: Image) async -> Data? {
        let uiImage = await image.render(convertToColorDepth: true, scale: Constants.scale)
        
        guard let uiImage else { return nil }
        
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.8) else { return nil }
        
        return jpegData
    }
}
