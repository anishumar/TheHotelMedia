//
//  TransactionsViewModel.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI
import SwiftfulRouting


class TransactionsViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = TransactionDataManager()
    @Published var transactions: [SubscriptionTransaction] = []
    @Published var pageNumber: Int = 1
    @Published var totalPages: Int = 1
    @Published var showLoadingIndicator: Bool = false
    
    init(router: AnyRouter) {
        self.router = router
        getTransactions()
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
}


// MARK: - Networking
extension TransactionsViewModel {
    
    func getTransactions() {
        
        guard pageNumber <= totalPages else { return }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getTransactions(pageNumber: pageNumber)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            transactions += data
                        }
                        pageNumber = result.pageNo ?? 1
                        totalPages = result.totalPages ?? 1
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
