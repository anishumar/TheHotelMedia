//
//  EnterEmailViewModel.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI
import SwiftfulRouting
import Combine

class EnterEmailViewModel: ObservableObject {
    
    var router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    @Published var emailFieldText: String = ""
    @Published var nextButtonDisabled: Bool = true
    
    
    init(router: AnyRouter) {
        self.router = router
        addSubscribers()
    }
    
    
    func addSubscribers() {
        $emailFieldText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] text in
                guard let self else { return }
                if text.count > 3 {
                    nextButtonDisabled = false
                } else {
                    nextButtonDisabled = true
                }
            }
            .store(in: &cancellables)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func showConfirmEmailscreen() {
        router.showScreen(.push) { router in
            ConfirmEmailView(viewModel: ConfirmEmailViewModel(router: router, email: ""))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
}
