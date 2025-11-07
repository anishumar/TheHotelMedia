//
//  HelpAndSupportViewModel.swift
//  HotelMedia
//
//  Created by MAC on 19/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


final class HelpAndSupportViewModel: ObservableObject {
    
    var router: AnyRouter
    var cancellables = Set<AnyCancellable>()
    let dataManager = HelpAndSupportDataManager()
    @Published var descriptionFieldText: String = ""
    @Published var nameFieldText: String = ""
    @Published var emailFieldText: String = ""
    @Published var showLoadingIndicator: Bool = false
    @Published var enterFields: Bool = false
    @Published var nextButtonDisabled: Bool = false
    @Published var currentTab: HelpandSupportTab = .faqs
    @Published var currentFilter: QuestionFilter = .general
    @Published var searchFieldText: String = ""
    var recentQuery: String = ""
    
    @Published var generalQuestions: [QuestionAnswer] = []
    @Published var generalPageNo: Int = 1
    @Published var generalTotalPages: Int = 1
    
    @Published var accountQuestions: [QuestionAnswer] = []
    @Published var accountpageNo: Int = 1
    @Published var accountTotalPages: Int = 1
    
    @Published var privacyQuestions: [QuestionAnswer] = []
    @Published var privacyPageNo: Int = 1
    @Published var privacyTotalPages: Int = 1
    
    @Published var contentQuestions: [QuestionAnswer] = []
    @Published var contentPageNo: Int = 1
    @Published var contentTotalPages: Int = 1
    
    let localizationManager = LocalizationManager.shared
    
    init(router: AnyRouter, enterFields: Bool = true) {
        self.router = router
        self.enterFields = enterFields
        addSubscriber()
    }
    
    
    func addSubscriber() {
        $currentFilter
            .sink { [weak self] type in
                guard let self else { return }
                
                switch type {
                case .general:
                    generalQuestions.removeAll()
                    generalPageNo = 1
                case .account:
                    accountQuestions.removeAll()
                    accountpageNo = 1
                case .privacy:
                    privacyQuestions.removeAll()
                    privacyPageNo = 1
                case .content:
                    contentQuestions.removeAll()
                    contentPageNo = 1
                }
                
                getFaqs(query: searchFieldText, type: type)
            }
            .store(in: &cancellables)
        
        $searchFieldText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }
                
                guard recentQuery != query else { return }
                
                recentQuery = query
                
                switch currentFilter {
                case .general:
                    generalQuestions.removeAll()
                    generalPageNo = 1
                case .account:
                    accountQuestions.removeAll()
                    accountpageNo = 1
                case .privacy:
                    privacyQuestions.removeAll()
                    privacyPageNo = 1
                case .content:
                    contentQuestions.removeAll()
                    contentPageNo = 1
                }
                
                getFaqs(query: query, type: currentFilter)
            }
            .store(in: &cancellables)
        
        $descriptionFieldText
            .combineLatest($nameFieldText, $emailFieldText)
            .sink { [weak self] (description, name, email) in
                guard let self else { return }
                
                if !description.isEmpty && !name.isEmpty && !email.isEmpty && isValidEmail(email) {
                    nextButtonDisabled = false
                } else {
                    nextButtonDisabled = true
                }
            }
            .store(in: &cancellables)
    }
    
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[a-z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    
    
    func toggleExpansion(for question: QuestionAnswer) {
        switch currentFilter {
        case .general:
            if let index = generalQuestions.firstIndex(where: { $0.id == question.id }) {
                if let _ = generalQuestions[index].isExpanded {
                    generalQuestions[index].isExpanded?.toggle()
                } else {
                    generalQuestions[index].isExpanded = true
                }
            }
        case .account:
            if let index = accountQuestions.firstIndex(where: { $0.id == question.id }) {
                if let _ = accountQuestions[index].isExpanded {
                    accountQuestions[index].isExpanded?.toggle()
                } else {
                    accountQuestions[index].isExpanded = true
                }
            }
        case .privacy:
            if let index = privacyQuestions.firstIndex(where: { $0.id == question.id }) {
                if let _ = privacyQuestions[index].isExpanded {
                    privacyQuestions[index].isExpanded?.toggle()
                } else {
                    privacyQuestions[index].isExpanded = true
                }
            }
        case .content:
            if let index = contentQuestions.firstIndex(where: { $0.id == question.id }) {
                if let _ = contentQuestions[index].isExpanded {
                    contentQuestions[index].isExpanded?.toggle()
                } else {
                    contentQuestions[index].isExpanded = true
                }
            }
        }
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func openWhatsapp() {
        let phoneNumber = "917738727020"
        
        let urlString = "https://api.whatsapp.com/send?phone=\(phoneNumber)&text=Hello World"
        
        let urlStringEncoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        if let url = NSURL(string: urlStringEncoded!) as? URL {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // WhatsApp is not installed. You can redirect to the App Store or show an alert.
                // For example:
//                showWhatsAppNotInstalledAlert()
                print("Whatsapp not installed.")
            }
        }
        
        
    }
}


// MARK: - Netorking
extension HelpAndSupportViewModel {
    
    func getFaqs(query: String = "", type: QuestionFilter, isPagination: Bool = false) {
        
        Task {
            var pageNo: Int = 1
            
            switch type {
            case .general:
                guard generalPageNo <= generalTotalPages else { return }
                pageNo = generalPageNo
            case .account:
                guard accountpageNo <= accountTotalPages else { return }
                pageNo = accountpageNo
            case .privacy:
                guard privacyPageNo <= privacyTotalPages else { return }
                pageNo = privacyPageNo
            case .content:
                guard contentPageNo <= contentTotalPages else { return }
                pageNo = contentPageNo
            }
            
            await MainActor.run {
                if !isPagination {
                    showLoadingIndicator = true
                }
            }
            
            do {
                let result = try await dataManager.getFaqs(pageNo: pageNo, query: query, type: type.rawValue)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            
                            if isPagination {
                                switch type {
                                case .general:
                                    generalQuestions += data
                                    generalPageNo = result.pageNo ?? 1
                                    generalTotalPages = result.totalPages ?? 1
                                    
                                case .account:
                                    accountQuestions += data
                                    accountpageNo = result.pageNo ?? 1
                                    accountTotalPages = result.totalPages ?? 1
                                    
                                case .privacy:
                                    privacyQuestions += data
                                    privacyPageNo = result.pageNo ?? 1
                                    privacyTotalPages = result.totalPages ?? 1
                                    
                                case .content:
                                    contentQuestions += data
                                    contentPageNo = result.pageNo ?? 1
                                    contentTotalPages = result.totalPages ?? 1
                                }
                            } else {
                                switch type {
                                case .general:
                                    generalQuestions = data
                                    generalPageNo = result.pageNo ?? 1
                                    generalTotalPages = result.totalPages ?? 1
                                case .account:
                                    accountQuestions = data
                                    accountpageNo = result.pageNo ?? 1
                                    accountTotalPages = result.totalPages ?? 1
                                    
                                case .privacy:
                                    privacyQuestions = data
                                    privacyPageNo = result.pageNo ?? 1
                                    privacyTotalPages = result.totalPages ?? 1
                                    
                                case .content:
                                    contentQuestions = data
                                    contentPageNo = result.pageNo ?? 1
                                    contentTotalPages = result.totalPages ?? 1
                                }
                            }
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
    
    func contactUs(name: String, email: String, message: String) {
        
        guard !name.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "enter_your_full_name".localized(localizationManager.language))
            return
        }
        
        guard !email.isEmpty, isValidEmail(email) else {
            ErrorModalManager.showErrorModal(router: router, errorText: "please_enter_a_valid_email_address".localized(localizationManager.language))
            return
        }
        
        guard !message.isEmpty else {
            ErrorModalManager.showErrorModal(router: router, errorText: "please_write_a_brief_message".localized(localizationManager.language))
            return
        }
        
        let parameters: [String: Any] = [
            "name" : name,
            "email" : email,
            "message" : message
        ]
        
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.contactUs(parameters: parameters)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        ErrorModalManager.showErrorModal(router: router, errorText: result.message)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) { [weak self] in
                            guard let self else { return }
                            dismissScreen()
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
