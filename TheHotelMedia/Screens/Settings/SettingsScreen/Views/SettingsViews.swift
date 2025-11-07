//
//  SettingsViews.swift
//  HotelMedia
//
//  Created by MAC on 16/08/24.
//

import SwiftUI

struct SettingsViews: View {
    
    @AppStorage("hasLoggedIn") var hasLoggedIn: Bool = false
    @AppStorage("isIndividual") var isIndividual: Bool = false
    @AppStorage("privateAccount") var privateAccount: Bool = false
    @AppStorage("notificationEnabled") var notificationEnabled: Bool = true
    @StateObject var viewModel: SettingsViewsModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @Environment(\.openURL) var openURL
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    Group {
                        generalSection
                        notificationSection
                        themeSection
                        moreSection
                    }
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.label_06)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 50)
                .padding(.bottom, 20)
            }
            .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
            .overlay(
                CustomHeaderView(title: "settings".localized(localizationManager.language)) {
                    viewModel.dismissScreen()
                }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                    .background(themeManager.currentTheme.backgroundColor)
                , alignment: .top
            )
            
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .onAppear {
            viewModel.allowNotification = notificationEnabled
            viewModel.isPrivate = privateAccount
        }
    }
}


// MARK: - Preview

struct SettingsViews_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SettingsViews(viewModel: SettingsViewsModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components
extension SettingsViews {
    private func option(title: String, icon: String) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .padding(.leading, 16)
                .padding(.trailing, 8)
            
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.001))
            
            Image(themeManager.currentTheme.Chevron_right)
                .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 42)
    }
    
    
    private func switchOption(title: String, icon: String, isActive: Binding<Bool>, onPressed: ((Bool) -> Void)? = nil) -> some View {
        HStack {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .padding(.leading, 16)
                .padding(.trailing, 8)
            
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.001))
            
            CustomSwitch(isActive: isActive, onPressed: { isActive in
                onPressed?(isActive)
            })
                .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 42)
    }
    
    
    private var divider: some View {
        Rectangle()
            .fill(.hmDarkerGray)
            .frame(maxWidth: .infinity)
            .frame(height: 1)
            .padding(.horizontal)
    }
    
    
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("general".localized(localizationManager.language))
            VStack(spacing: 2) {
                option(
                    title: "language".localized(localizationManager.language),
                    icon: themeManager.currentTheme.LanguageIcon
                )
                    .onTapGesture {
                        viewModel.showLanguageScreen()
                    }
                divider
                option(
                    title: "saved_posts".localized(localizationManager.language),
                    icon: themeManager.currentTheme.bookmark3
                )
                .onTapGesture {
                    viewModel.showSavedPostScreen()
                }

                
                if isIndividual {
                    divider
                    option(title: "Booking History".localized(localizationManager.language), icon: themeManager.currentTheme.BookingHistory)
                        .onTapGesture {
                            viewModel.showBookingHistoryScreen()
                        }
                }
                
                divider
                if !isIndividual {
                    option(
                        title: "documents".localized(localizationManager.language),
                        icon: themeManager.currentTheme.DocumentIcon2
                    )
                    .onTapGesture {
                        viewModel.showDocumentsView()
                    }
                    divider
                }
                option(
                    title: "blocked_users".localized(localizationManager.language),
                    icon: themeManager.currentTheme.BlockIcon
                )
                .onTapGesture {
                    viewModel.showBlockedUsersScreen()
                }
                
                if isIndividual {
                    divider
                    switchOption(
                        title: "private_account".localized(localizationManager.language),
                        icon: themeManager.currentTheme.EyeFill,
                        isActive: $viewModel.isPrivate) { isPrivate in
                            viewModel.privateAccount(enable: isPrivate)
                        }
                }
                
                if !isIndividual {
                    divider
                    option(title: "Post Job".localized(localizationManager.language), icon: themeManager.currentTheme.Briefcase)
                        .onTapGesture {
                            viewModel.showCreateJobPostScreen()
                        }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray06_black008)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
            )
        }
    }
    
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("notification".localized(localizationManager.language))
            VStack {
                switchOption(
                    title: "notification".localized(localizationManager.language),
                    icon: themeManager.currentTheme.BellIcon2,
                    isActive: $viewModel.allowNotification) { isActive in
                        viewModel.enableNotification(enable: isActive)
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray06_black008)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
            )
        }
    }
    
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Theme".localized(localizationManager.language))
            VStack {
                switchOption(
                    title: "Dark Mode".localized(localizationManager.language),
                    icon: themeManager.currentTheme.Moon2,
                    isActive: $themeManager.darkThemeActive) { isActive in
                        themeManager.toggleTheme()
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray06_black008)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
            )
        }
    }
    
    
    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("more".localized(localizationManager.language))
            VStack(spacing: 2) {
                option(
                    title: "transactions".localized(localizationManager.language).capitalized,
                    icon: themeManager.currentTheme.BillIcon3
                )
                .onTapGesture {
                    viewModel.showTransactionsScreen()
                }
                divider
                option(
                    title: "subscription".localized(localizationManager.language),
                    icon: themeManager.currentTheme.SignBoard2
                )
                .onTapGesture {
                    viewModel.showSubscriptionScreen()
                }
                divider
                option(
                    title: "privacy_policy".localized(localizationManager.language),
                    icon: themeManager.currentTheme.DocumentLock
                )
                .onTapGesture {
                    if let url = URL(string: "https://admin.thehotelmedia.com/privacy-policy") {
                        openURL(url)
                    }
                }
                divider
                option(
                    title: "about_us".localized(localizationManager.language),
                    icon: themeManager.currentTheme.AboutUs
                )
                .onTapGesture {
                    if let url = URL(string: "https://admin.thehotelmedia.com/about-us") {
                        openURL(url)
                    }
                }
                divider
                option(
                    title: "terms_and_conditions".localized(localizationManager.language),
                    icon: themeManager.currentTheme.DocumentPencil
                )
                .onTapGesture {
                    //                        viewModel.showTermsConditionScreen()
                    if let url = URL(string: "https://admin.thehotelmedia.com/terms-and-conditions") {
                        openURL(url)
                    }
                }
                divider
                option(
                    title: "help_and_support".localized(localizationManager.language),
                    icon: themeManager.currentTheme.CustomerSupport
                )
                .onTapGesture {
                    viewModel.showCustomerSupportScreen()
                }
                divider
                option(
                    title: "account_deactivate".localized(localizationManager.language),
                    icon: themeManager.currentTheme.RemoveAccount
                )
                .onTapGesture {
                    viewModel.showDeactivateAccountModal(message: "deactivate_modal_title".localized(localizationManager.language), rightButtonTitle: "no".localized(localizationManager.language), leftButtonTitle: "yes".localized(localizationManager.language))
                }
                divider
                option(
                    title: "delete_account".localized(localizationManager.language),
                    icon: themeManager.currentTheme.BinIcon
                )
                .onTapGesture {
                    viewModel.showDeleteAccountModal(message: "delete_account_modal_title".localized(localizationManager.language), rightButtonTitle: "no".localized(localizationManager.language), leftButtonTitle: "yes".localized(localizationManager.language))
                }
                divider
                option(
                    title: "logout".localized(localizationManager.language),
                    icon: themeManager.currentTheme.Logout
                )
                .onTapGesture {
                    viewModel.showLogoutModal(message: "logout_modal_title".localized(localizationManager.language), rightButtonTitle: "no".localized(localizationManager.language), leftButtonTitle: "yes".localized(localizationManager.language))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.currentTheme.darkGray06_black008)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
            )
        }
    }
}
