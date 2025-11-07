//
//  BookingSummaryViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 04/03/25.
//

import SwiftfulRouting
import Combine
import SwiftUI


class BookingSummaryViewModel: ObservableObject {
    
    let router: AnyRouter
    let bookingDetailID: String
    let lastScreen: String?
    var onBookingCancelled: (() -> Void)? = nil
    let dataManager = BookingSummaryDataManager()
    @Published var bookingSummary: BookingSummary? = nil
    @Published var showLoadingIndicator: Bool = false
    @Published var bookingCancelled: Bool = false
    let localizationManager = LocalizationManager.shared
    let downloadManager = FileDownloadManager.shared
    
    init(router: AnyRouter, bookingDetailID: String, onBookingCancelled: (() -> Void)? = nil, lastScreen: String? = nil) {
        self.router = router
        self.bookingDetailID = bookingDetailID
        self.onBookingCancelled = onBookingCancelled
        self.lastScreen = lastScreen
        getBookingSummary(id: bookingDetailID)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showCancelBookingModal() {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "Do you really want to cancel your booking?",
            rightButtonTitle: "no".localized(localizationManager.language),
            leftButtonTitle: "yes".localized(localizationManager.language)) { [weak self] in
                guard let self else { return }
                cancelBooking()
            } onRightButtonPressed: {
                
            } onDismiss: {
                
            }
    }
    
    
    func showDownloadInvoiceModal() {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "Do you want to download the invoice?",
            rightButtonTitle: "no".localized(localizationManager.language),
            leftButtonTitle: "yes".localized(localizationManager.language)) { [weak self] in
                guard let self else { return }
                downloadInvoice()
            } onRightButtonPressed: {
                
            } onDismiss: {
                
            }
    }
    
    
    func showActivityIndicator(at fileURL: URL) {
        DispatchQueue.main.async {
            do {
                // Create an activity view controller to share the file data
                let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

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


// MARK: - Networking
extension BookingSummaryViewModel {
    
    func getBookingSummary(id: String) {
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.getBookingSummary(id: id)
                
                await MainActor.run {
                    let range = 200...204
                    showLoadingIndicator = false
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            bookingSummary = data
                            if data.status?.contains("canceled") ?? false {
                                bookingCancelled = true
                            }
                        } else {
                            ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
        }
    }
    
    
    func downloadInvoice() {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getBookingInvoicePath(id: bookingDetailID)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        
                        if let data = result.data,
                           let filename = data.filename,
                           let filepath = data.filepath,
                           let type = data.type {
                            
                            downloadManager.downloadFile(from: filepath, fileName: filename) { [weak self] result in
                                guard let self else { return }
                                showLoadingIndicator = false
                                switch result {
                                case .success(let url):
                                    showActivityIndicator(at: url)
                                    
                                case .failure(let error):
                                    break
                                }
                            }
                        }
                    } else {
                        showLoadingIndicator = false
                        ErrorModalManager.showErrorModal(router: router, errorText: "Failed to download invoice!".localized(localizationManager.language))
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "internal_server_error_please_try_again".localized(localizationManager.language))
                }
            }
        }
    }
    
    
    func cancelBooking() {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.cancelBooking(id: bookingDetailID)
                
                await MainActor.run {
                    let range = 200...204
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        bookingCancelled = true
                        onBookingCancelled?()
                    }
                    ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "internal_server_error_please_try_again".localized(localizationManager.language))
                }
            }
        }
    }
}
