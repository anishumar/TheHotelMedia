//
//  SelectBusinessTypeViewModel.swift
//  HotelMedia
//
//  Created by MAC on 06/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


final class SelectBusinessTypeViewModel: ObservableObject {
    
    let router: AnyRouter
    let dataManager = BusinessTypeDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var dropDownOpen: Bool = false
    @Published var businessType: BusinessType? = nil
    @Published var nextButtonDisabled: Bool = true
    @Published var selectedID: String = ""
    @Published var typesArray: [TypeModel] = []
    @Published var selectedType: TypeModel? = nil
    @Published var showLoadingIndicator: Bool = false
    @Published var errorText: String = ""
    
//    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func addSubscribers() {
        $selectedType
            .sink { [weak self] type in
                guard let self else { return }
                nextButtonDisabled = type != nil ? false : true
            }
            .store(in: &cancellables)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showNextScreen() {
        guard let selectedType else { return }
        
        router.showScreen(.push) { router in
            BusinessDetailView(viewModel: BusinessDetailViewModel(router: router, selectedType: selectedType))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
        
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    
    func cancelSubcriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
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
}


// MARK: - Networking
extension SelectBusinessTypeViewModel {
    
    func getBusinessTypes() {
        
//        guard networkMonitor.isConnected else {
//            errorText = "No internet connection. Please try again."
//            showErrorModal()
//            return
//        }
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.getBusinessType()
                
                await MainActor.run {
                    showLoadingIndicator = false
                }
                
                if result.status && result.statusCode == 200 || result.status && result.statusCode == 201 {
                    if let data = result.data {
                        await MainActor.run {
                            typesArray = data
                        }
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


