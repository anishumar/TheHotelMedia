//
//  EditAddressViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 19/11/24.
//

import SwiftUI
import SwiftfulRouting
import GooglePlaces
import CoreLocation
import Combine
import StoreKit


class EditAddressViewModel: ObservableObject {
    
    let router: AnyRouter
    var currentAddress: String
    let subscriptionPlanID: String
    var product: Product? = nil
    var cancellables = Set<AnyCancellable>()
    let dataManager = ProfileDataManager()
    @Published var addressFieldText: String = ""
    @Published var selectedPlace: GMSPlace?
    @Published var showPlaceSearch = false
    @Published var selectedAddress: Address? = nil
    @Published var showLoadingIndicator: Bool = false
    
    @AppStorage("locationString") var locationString: String = ""
    
    init(router: AnyRouter, currentAddress: String = "", subscriptionPlanID: String = "", product: Product? = nil) {
        self.router = router
        self.currentAddress = currentAddress
        self.subscriptionPlanID = subscriptionPlanID
        self.product = product
        addressFieldText = currentAddress
        addSubscribers()
    }
    
    
    func addSubscribers() {
        $selectedPlace
            .sink { [weak self] place in
                guard let self else { return }
                if let place {
                    AddressManager.shared.fetchAddressFromGMSPlace(place: place) { [weak self] address in
                        guard let self else { return }
                        selectedAddress = address
                    }
                }
            }
            .store(in: &cancellables)
        
        $selectedAddress
            .sink { [weak self] address in
                guard let self else { return }
                if let address {
                    let addressString = "\(address.street ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                    addressFieldText = addressString
                }
            }
            .store(in: &cancellables)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showSubscriptionCheckoutScreen() {
        router.showScreen(.push) { router in
            if let product = self.product {
                ReviewSummaryView(viewModel: ReviewSummaryViewModel(router: router, subscriptionPlanID: self.subscriptionPlanID, product: product))
                    .environmentObject(ThemeManager.shared)
                    .navigationBarBackButtonHidden()
            }
            
        }
    }
}


// MARK: - Networking
extension EditAddressViewModel {
    func uploadBillingAddress(address: Address) {
        
        let parameters: [String: Any] = [
            "street" : address.street ?? "",
            "city" : address.city ?? "",
            "state" : address.state ?? "",
            "zipCode" : address.zipCode ?? "",
            "country" : address.country ?? "",
            "lat" : address.lat,
            "lng" : address.lng
        ]
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.updateBillingAddress(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        locationString = "\(address.street ?? ""), \(address.city ?? ""), \(address.state ?? ""), \(address.zipCode ?? ""), \(address.country ?? "")"
                        
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [weak self] in
                            guard let self else { return }
                            if !subscriptionPlanID.isEmpty {
                                showSubscriptionCheckoutScreen()
                            } else {
                                dismissScreen()
                            }
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
