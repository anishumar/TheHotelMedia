//
//  DocumentsViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 06/12/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


class DocumentsViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = DocumentsDataManger()
    @Published var selectedPdfURL: URL = URL(string: "https://thehotelmedia.com")!
    @Published var toDownloadPdfUrl: URL? = nil
    @Published var selectedMedia: MediaType = .image(urlString: "")
    @Published var selectedImage: UIImage? = nil
    @Published var showPdfView: Bool = false
    @Published var pdfData = Data()
    @Published var showImagePreview: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var documentData: DocumentData? = nil
    
    init(router: AnyRouter) {
        self.router = router
        getDocuments()
    }
    
    func dismissScreen() {
        router.dismissScreen()
    }
}


// MARK: - Networking
extension DocumentsViewModel {
    func getDocuments() {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getDocuments()
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data, !data.isEmpty {
                            documentData = data[0]
                        }
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
