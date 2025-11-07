//
//  SelectPlanViewModel.swift
//  HotelMedia
//
//  Created by MAC on 09/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import StoreKit


final class SelectPlanViewModel: ObservableObject {
    
    let router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    let dataManager = SubscriptionPlanManager()
    @Published var currentIndex: Int = 0
    @Published var showLoadingIndicator: Bool = false
    @Published var plans: [SubscriptionPlan] = []
    @Published var plansToShow: [SubscriptionPlan] = []
    @Published var errorText: String = ""
    @Published var subscriptionProducts: [Product] = []
    let iapManager = StoreKitAndIAPManager()
    
//    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    init(router: AnyRouter) {
        self.router = router
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            self.plans.append(Constants.individualPlan)
//            self.plansToShow.append(Constants.individualPlan)
//        }
    }
    
    
    func addSubscribers() {
        $plans
            .sink { [weak self] array in
                guard let self else { return }
                var newArray: [SubscriptionPlan] = []
                var productIDs: [String] = []
                
                for _ in 0...2 {
                    newArray.append(contentsOf: array)
                }
                
                for item in array {
                    if let id = item.appleSubscriptionID, !id.isEmpty {
                        productIDs.append(id)
                    }
                }
                showLoadingIndicator = true
                Task {
                    do {
                        try await self.iapManager.fetchSubscriptions(productIds: productIDs)
                        await MainActor.run {
                            self.showLoadingIndicator = false
                        }
                    } catch {
                        await MainActor.run {
                            self.showLoadingIndicator = false
                        }
                    }
                }
                
                plansToShow = newArray
            }
            .store(in: &cancellables)
        
        $currentIndex
            .sink { index in
                print(index)
            }
            .store(in: &cancellables)
        
        iapManager.$subscriptions
            .sink { [weak self] products in
                guard let self else { return }
                print(products)
                subscriptionProducts = products
            }
            .store(in: &cancellables)
    }
    
    
    func showNextScreen(product: Product) {
        router.showScreen(.push) { router in
            if let id = self.plans[self.currentIndex].id, !self.subscriptionProducts.isEmpty {
                ReviewSummaryView(viewModel: ReviewSummaryViewModel(router: router, subscriptionPlanID: id, product: product))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
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
    
    
    func cancelSubscriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
}


// MARK: - Networking
extension SelectPlanViewModel {
    func getPlans() {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getPlans()
                await MainActor.run {
                    
                    showLoadingIndicator = false
                    
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        if let data = result.data {
                            plans = data
                        }
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
}
