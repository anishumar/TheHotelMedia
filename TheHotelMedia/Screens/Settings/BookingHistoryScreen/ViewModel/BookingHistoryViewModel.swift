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
                            historyData = data
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
}
