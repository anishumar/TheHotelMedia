//
//  BookingHistoryViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 04/03/25.
//

import SwiftfulRouting
import Combine


class BookingHistoryViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = BookingHistoryDataManager()
    var pageNo: Int = 1
    var totalPages: Int = 1
    var refreshData: Bool = false
    @Published var historyData: [BookingHistory] = []
    @Published var showLoadingIndicator: Bool = false
    
    init(router: AnyRouter) {
        self.router = router
        getHistoryData(pageNo: pageNo)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    func showCancelBookingModal(id: String) {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: "Do you really want to cancel your booking?",
            rightButtonTitle: "no".localized(LocalizationManager.shared.language),
            leftButtonTitle: "yes".localized(LocalizationManager.shared.language)
        ) { [weak self] in
            self?.cancelBooking(id: id)
        } onRightButtonPressed: { } onDismiss: { }
    }
    
    
    func showSummaryScreen(id: String) {
        router.showScreen(.push) { router in
            BookingSummaryView(viewModel: BookingSummaryViewModel(router: router, bookingDetailID: id, onBookingCancelled: { [weak self] in
                guard let self else { return }
                refreshData = true
            }))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showTableSummaryScreen(id: String) {
        router.showScreen(.push) { router in
            TableSummaryView(viewModel: TableSummaryViewModel(router: router, bookingDetailID: id))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
}


// MARK: - Networking
extension BookingHistoryViewModel {
    
    func getHistoryData(pageNo: Int) {
        guard pageNo <= totalPages else { return }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getBookingHistory(pageNo: pageNo)
                
                await MainActor.run {
                    let range = 200...204
                    showLoadingIndicator = false
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            if pageNo == 1 {
                                historyData = data
                            } else {
                                historyData += data
                            }
                            totalPages = result.totalPages ?? 1
                            self.pageNo = result.pageNo ?? 1
                        }
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                }
            }
        }
    }
    
    private func cancelBooking(id: String) {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.cancelBooking(id: id)
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    
                    if result.status {
                        // Refresh list to reflect the new status (e.g. "canceled by user")
                        pageNo = 1
                        totalPages = 1
                        getHistoryData(pageNo: 1)
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    if let networkError = error as? NetworkError {
                        ErrorModalManager.showErrorModal(router: router, errorText: networkError.localizedDescription)
                    } else {
                        ErrorModalManager.showErrorModal(router: router, errorText: "internal_server_error_please_try_again".localized(LocalizationManager.shared.language))
                    }
                }
            }
        }
    }
}
