//
//  SubscriptionViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 18/11/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import StoreKit


class SubscriptionViewModel: ObservableObject {
    
    let router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    let dataManager = SubscriptionPlanManager()
    @Published var currentIndex: Int = 0
    @Published var showLoadingIndicator: Bool = false
    @Published var plans: [SubscriptionPlan] = []
    @Published var plansToShow: [SubscriptionPlan] = []
    @Published var subscription: ActiveSubscription? = nil
    @Published var errorText: String = ""
    @Published var showCancelSubscriptionModel: Bool = false
    @Published var subscriptionProducts: [Product] = []
    
    @AppStorage("locationString") var locationString: String = ""
    @AppStorage("isIndividual") var isIndividual: Bool = false

    @AppStorage("hasSubscription") var hasSubscription: Bool = false
    @AppStorage("businessProfileCreatedAt") var businessProfileCreatedAt: String = ""
    
    
    let iapManager = StoreKitAndIAPManager()
    
    init(router: AnyRouter) {
        self.router = router
        checkGracePeriod()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            self.plans.append(Constants.individualPlan)
//            self.plansToShow.append(Constants.individualPlan)
//        }
    }
    
    func addSubscribers() {
        $plans
            .sink { [weak self] array in
                guard let self, !array.isEmpty else { return }
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
        
        guard let planAmount = plans[currentIndex].price else { return }
        
        guard planAmount > 0 else {
            ErrorModalManager.showErrorModal(router: router, errorText: "This is a free plan.")
            return
        }
        
        if isIndividual && locationString.isEmpty {
            router.showScreen(.push) { router in
                if let id = self.plans[self.currentIndex].id, !self.subscriptionProducts.isEmpty {
                    EditAddressView(viewModel: EditAddressViewModel(router: router, currentAddress: "", subscriptionPlanID: id, product: product))
                        .environmentObject(ThemeManager.shared)
                        .navigationBarBackButtonHidden()
                }
                
            }
        } else {
            router.showScreen(.push) { router in
                if let id = self.plans[self.currentIndex].id, !self.subscriptionProducts.isEmpty {
                    ReviewSummaryView(viewModel: ReviewSummaryViewModel(router: router, subscriptionPlanID: id, product: product))
                        .environmentObject(ThemeManager.shared)
                        .navigationBarBackButtonHidden()
                }
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
    

    
    func checkGracePeriod() {
        if Date.isWithinGracePeriod(dateString: businessProfileCreatedAt) {
            router.dismissScreen()
        }
    }
    
}


// MARK: - Networking
extension SubscriptionViewModel {
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
    
    
    func getActiveSubscription() {
        Task {
            do {
                let result = try await dataManager.getActiveSubscription()
                
                await MainActor.run {
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let subscription = result.data?.subscription {
                            self.subscription = subscription
                            hasSubscription = true
                        } else {
                            hasSubscription = false
                        }
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func cancelUserPlanSubscription() {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.cancelSubscription()
                await MainActor.run {
                    
                    showLoadingIndicator = false
                    
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        subscription = nil
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
