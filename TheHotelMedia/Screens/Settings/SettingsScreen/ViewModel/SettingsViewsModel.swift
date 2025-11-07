//
//  SettingsViewsModel.swift
//  HotelMedia
//
//  Created by MAC on 16/08/24.
//

import SwiftUI
import SwiftfulRouting
import Combine


final class SettingsViewsModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = SettingDataManager()
    let profileDataManger = ProfileDataManager()
    var cancellables = Set<AnyCancellable>()
    @Published var showLoadingIndicator: Bool = false
    @Published var isPrivate: Bool = false
    @Published var allowNotification: Bool = false
    
    @AppStorage("hasLoggedIn") var hasLoggedIn: Bool = false
    @AppStorage("privateAccount") var privateAccount: Bool = false
    @AppStorage("notificationEnabled") var notificationEnabled: Bool = true
    @AppStorage("username") var username: String = ""
    @AppStorage("name") var name: String = ""
    @AppStorage("profilePic") var profilePic: String = ""
    @AppStorage("locationString") var locationString: String = ""
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("ownUserID") var ownUserID: String = ""
    
    init(router: AnyRouter) {
        self.router = router
    }
    
    
    func resetUserData() {
        name = ""
        username = ""
        isIndividual = true
        ownUserID = ""
        locationString = ""
        profilePic = ""
    }
    
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    func rootScreen() {
    }
    
    
    func showLanguageScreen() {
        router.showScreen(.push) { router in
            SelectLanguageView(viewModel: SelectLanguageViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showSignInScreen() {
        router.showScreen(.push) { router in
            SignInView(viewModel: SignInViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showCustomerSupportScreen() {
        router.showScreen(.push) { router in
            HelpAndSupportView(viewModel: HelpAndSupportViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showTransactionsScreen() {
        router.showScreen(.push) { router in
            TransactionsView(viewModel: TransactionsViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showAboutUsScreen() {
        router.showScreen(.push) { router in
            AboutUsView(viewModel: AboutUsViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
        
//        router.showScreen(.push) { router in
//            TermsAndConditionView(viewModel: TermsAndConditionViewModel(router: router))
//                .navigationBarBackButtonHidden()
//        }
    }
    
    
    func showTermsConditionScreen() {
        router.showScreen(.push) { router in
            SettingTermsConditionView(viewModel: SettingTermsConditionViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showSavedPostScreen() {
        router.showScreen(.push) { router in
            SavedPostView(viewModel: SavedPostViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showBookingHistoryScreen() {
        router.showScreen(.push) { router in
            BookingHistoryView(viewModel: BookingHistoryViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showCreateJobPostScreen() {
        router.showScreen(.push) { router in
            CreateJobPostView(viewModel: CreateJobPostViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    func showJobDetailScreen() {
        router.showScreen(.push) { router in
            JobDetailView(viewModel: JobDetailViewModel(router: router, jobID: ""))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showDocumentsView() {
        router.showScreen(.push) { router in
            DocumentsView(viewModel: DocumentsViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showBlockedUsersScreen() {
        router.showScreen(.push) { router in
            BlockedUsersView(viewModel: BlockedUsersViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showSubscriptionScreen() {
        router.showScreen(.push) { router in
            SubscriptionView(viewModel: SubscriptionViewModel(router: router))
                .environmentObject(ThemeManager.shared)
                .navigationBarBackButtonHidden()
        }
    }
    
    
    func showLogoutModal(message: String, rightButtonTitle: String, leftButtonTitle: String) {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: message,
            rightButtonTitle: rightButtonTitle,
            leftButtonTitle: leftButtonTitle) { [weak self] in
                guard let self else { return }
                logoutAccount()
            } onRightButtonPressed: {
                
            } onDismiss: {
                
            }
    }
    
    
    func showDeleteAccountModal(message: String, rightButtonTitle: String, leftButtonTitle: String) {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: message,
            rightButtonTitle: rightButtonTitle,
            leftButtonTitle: leftButtonTitle) { [weak self] in
                guard let self else { return }
                deleteAccount()
            } onRightButtonPressed: {
                
            } onDismiss: {
                
            }
    }
    
    
    func showDeactivateAccountModal(message: String, rightButtonTitle: String, leftButtonTitle: String) {
        BottomModalManager.horizontalStyleModal(
            router: router,
            title: message,
            rightButtonTitle: rightButtonTitle,
            leftButtonTitle: leftButtonTitle) { [weak self] in
                guard let self else { return }
                deactivateAccount()
                
            } onRightButtonPressed: {
                
            } onDismiss: {
                
            }
    }
}


// MARK: - Networking
extension SettingsViewsModel {
    
    func deleteAccount() {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.deleteAccount()
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        resetUserData()
                        SocketIOViewModel.shared.disconnectSocket()
                        hasLoggedIn = false
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func deactivateAccount() {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.deactivateAccount()
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        resetUserData()
                        SocketIOViewModel.shared.disconnectSocket()
                        hasLoggedIn = false
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func logoutAccount() {
        showLoadingIndicator = true
        
        Task {
            do {
                let result = try await dataManager.logoutAccount()
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        resetUserData()
                        SocketIOViewModel.shared.disconnectSocket()
                        hasLoggedIn = false
                        
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func privateAccount(enable: Bool) {
        let paramater = ["privateAccount" : enable]
        
        Task {
            do {
                let result = try await profileDataManger.editProfileData(parameters: paramater)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        privateAccount = enable
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func enableNotification(enable: Bool) {
        let paramater = ["notificationEnabled" : enable]
        
        Task {
            do {
                let result = try await profileDataManger.editProfileData(parameters: paramater)
                
                await MainActor.run {
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        notificationEnabled = enable
                    }
                }
                
            } catch {
                print(error)
            }
        }
    }
}
