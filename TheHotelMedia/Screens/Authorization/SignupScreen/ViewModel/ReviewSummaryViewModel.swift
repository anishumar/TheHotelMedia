//
//  ReviewSummaryViewModel.swift
//  HotelMedia
//
//  Created by MAC on 09/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine
import StoreKit


final class ReviewSummaryViewModel: ObservableObject {
    
    let router: AnyRouter
    let subscriptionPlanID: String
    let dataManager = CheckoutDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var promoFieldText: String = ""
    @Published var errorText: String = ""
    @Published var showLoadingIndicator: Bool = false
    @Published var checkoutData: CheckoutData? = nil
    @Published var orderID: String? = nil
    @Published var currency: String = ""
    @Published var amount: String = ""
    @Published var razorID: String = ""
    @Published var phoneNumber: String = ""
    @Published var addressString: String = ""
    @Published var product: Product? = nil
    @Published var showPurchaseLoading: Bool = false
    @Published var startedPurchase: Bool = false
    @Published var showActiveSubAlert: Bool = false
    @Published var retrycounter: Int = 0
    @Published var showAlert: Bool = false
    @Published var showDismissAlert: Bool = false
    @Published var showFetchingSubscriptionAlert: Bool = false
    var purchaseTask: Task<Void, Never>?
    let iapManager = StoreKitAndIAPManager()
//    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    init(router: AnyRouter, subscriptionPlanID: String, product: Product? = nil) {
        self.router = router
        self.subscriptionPlanID = subscriptionPlanID
        self.product = product
        addSubscribers()
        getCheckouDetails()
    }
    
    
    func addSubscribers() {
        $checkoutData
            .sink { [weak self] data in
                guard let self else { return }
                
                if let data {
                    if let address = data.billingAddress?.address {
                        addressString = "\(address.street ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                    }
                    
                    if let promoCode = data.payment?.promoCode {
                        promoFieldText = promoCode.code
                    } else {
                        promoFieldText = ""
                    }
                }
                
                if let orderID = data?.orderID {
                    self.orderID = orderID
                }
                
                if let razorID = data?.razorPayOrder?.id {
                    self.razorID = razorID
                }
                
                if let amount = data?.razorPayOrder?.amount {
                    self.amount = "\(amount)"
                }
                
                if let currency = data?.razorPayOrder?.currency {
                    self.currency = currency
                }
                
                if let phoneNumber = data?.billingAddress?.phoneNumber {
                    self.phoneNumber = phoneNumber
                }
            }
            .store(in: &cancellables)
    }
    
    
    func cancelPurchaseTask() {
        purchaseTask?.cancel()
        purchaseTask = nil
    }
    
    
    func cancelSubscriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    
    func showNextScreen() {
        router.showScreen(.push) { router in
            PaymentOptionView(viewModel: PaymentOptionViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func dismissAllScreens() {
        router.dismissScreenStack()
    }
    
    
    func showErrorModal() {
        router.showModal(transition: .move(edge: .bottom)) {
            BottomAlert(message: self.errorText)
        }
        print(self.errorText)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.router.dismissModal()
            self.errorText = ""
        }
    }
}


// MARK: - Networking
extension ReviewSummaryViewModel {
    
    func getCheckouDetails(addPromoCode: Bool = false, promoCode: String = "") {
        showLoadingIndicator = true
        
        Task {
            var parameters: [String: Any] = [
                "subscriptionPlanID" : subscriptionPlanID
            ]
            
            if addPromoCode && !promoCode.isEmpty {
                parameters.updateValue(promoCode, forKey: "promoCode")
            }
            
            do {
                let result = try await dataManager.getCheckoutDetails(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    
                    if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                        if let data = result.data {
                            checkoutData = data
                        }
                    } else {
                        errorText = result.message
                        ErrorModalManager.showErrorModal(router: router, errorText: errorText)
                        
                        if !promoCode.isEmpty {
                            getCheckouDetails()
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: "Failed to fetch checkout data! Please try again.")
                }
                print(error)
            }
        }
    }
    
    
    func buySubcription(paymentID: String, signature: String, orderID: String) {
        let parameters: [String: Any] = [
            "orderID" : orderID,
            "paymentID" : paymentID,
            "signature" : signature
        ]
        
        print(paymentID, signature, orderID)
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.buySubscription(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    
                    
                    if result.status && range.contains(result.statusCode) {
                        errorText = result.message
                        ErrorModalManager.showErrorModal(router: router, errorText: errorText)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                            guard let self else { return }
                            dismissAllScreens()
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
    
    
    func buyPlan2(token: String, type: String) {
        let parameters: [String: Any] = [
            "orderID": orderID ?? "",
            "token": token
        ]
        
        print(token)
        print(orderID)
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.validateTransaction(parameters: parameters)
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                            guard let self else { return }
                            dismissAllScreens()
                        }
                    } else {
                        showLoadingIndicator = true
                        retrycounter += 1
                        print(retrycounter, "🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵")
                        Task {
                            let result = try await dataManager.getCheckoutDetails(parameters: ["subscriptionPlanID" : subscriptionPlanID])
                            if let data = result.data {
                                checkoutData = data
                            }
                            
                            if let newToken = await iapManager.getJwsToken(retries: 10) {
                                if retrycounter >= 100 {
                                    tryAgain(token: newToken, type: type)
                                } else {
                                    buyPlan2(token: newToken, type: type)
                                }
                                
                            } else {
                                await MainActor.run {
                                    showLoadingIndicator = false
                                }
                            }
                        }
                    }
                }
                
                
            } catch {
                await MainActor.run {
                    showLoadingIndicator = true
                    retrycounter += 1
                    print(retrycounter, "🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵🌵")
                    Task {
                        
                        let result = try await dataManager.getCheckoutDetails(parameters: ["subscriptionPlanID" : subscriptionPlanID])
                        if let data = result.data {
                            checkoutData = data
                        }
                        
                        if let newToken = await iapManager.getJwsToken(retries: 10) {
                            if retrycounter >= 100 {
                                tryAgain(token: newToken, type: type)
                            } else {
                                buyPlan2(token: newToken, type: type)
                            }
                        } else {
                            await MainActor.run {
                                showLoadingIndicator = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func tryAgain(token: String, type: String) {
        let parameters: [String: Any] = [
            "orderID": orderID ?? "",
            "token": token
        ]
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.validateTransaction(parameters: parameters)
                await MainActor.run {
                    showLoadingIndicator = false
                    ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                        guard let self else { return }
                        dismissAllScreens()
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    if type == "error" {
                        ErrorModalManager.showErrorModal(router: router, errorText: "An error occured while performing your request!")
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                        guard let self else { return }
                        dismissAllScreens()
                    }
                }
            }
        }
    }
}
