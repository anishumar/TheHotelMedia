//
//  TableSummaryViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 07/04/25.
//

import Foundation
import Combine
import SwiftfulRouting


class TableSummaryViewModel: ObservableObject {
    
    let router: AnyRouter
    let bookingDetailID: String
    let showButtons: Bool
    let dataManager = BookingSummaryDataManager()
    @Published var bookingSummary: BookingSummary? = nil
    @Published var showLoadingIndicator: Bool = false
    @Published var bookingCancelled: Bool = false
    
    init(router: AnyRouter, bookingDetailID: String, showButtons: Bool = false) {
        self.router = router
        self.bookingDetailID = bookingDetailID
        self.showButtons = showButtons
        getBookingSummary(id: bookingDetailID)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    func dismissAllScreens() {
        router.dismissScreenStack()
    }
}

// MARK: - Networking
extension TableSummaryViewModel {
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
                            if data.status == "canceled" {
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
    
    
    func bookingAction(isAccepted: Bool) {
        showLoadingIndicator = true
        Task {
            do {
                let result = try await dataManager.bookingAction(isAccepted: isAccepted, bookingID: bookingDetailID)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    if result.status && range.contains(result.statusCode) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                            guard let self else { return }
                            self.dismissAllScreens()
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "Internal server error!")
                }
            }
        }
    }
}
