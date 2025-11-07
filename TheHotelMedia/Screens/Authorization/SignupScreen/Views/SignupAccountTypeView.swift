//
//  SignupAccountTypeView.swift
//  HotelMedia
//
//  Created by MAC on 29/07/24.
//

import SwiftUI

struct SignupAccountTypeView: View {
    // MARK: - Properties
    
    @StateObject var viewModel: SignupAccountTypeViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("isIndividual") var isIndividual: Bool = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // background
            BackgroundImageView()
            
            // content
            logo
            VStack(spacing: 20) {
                titleSection
                selectTypeSection
            }
            
            nextButton
        }
        .onAppear {
            viewModel.addSubscribers()
        }
        .onDisappear {
            viewModel.cancelSubcriptions()
        }
    }
}

// MARK: - Preview

struct SignupAccountTypeView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        SignupAccountTypeView(viewModel: SignupAccountTypeViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
        
    }
}


// MARK: - Components
extension SignupAccountTypeView {
    
    private var selectTypeSection: some View {
        HStack(spacing: 36) {
            VStack {
                Image(viewModel.accountType == .individual ? themeManager.currentTheme.IndividualSelected2 : themeManager.currentTheme.IndividualType2)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .onTapGesture {
                        viewModel.accountType = .individual
                    }
                
                Text("individual".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(viewModel.accountType == .individual ? .hmIndigo : themeManager.currentTheme.white06_darkGray06)
            }
            
            VStack {
                Image(viewModel.accountType == .business ? themeManager.currentTheme.BusinessSelected2 : themeManager.currentTheme.BusinessType2)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .onTapGesture {
                        viewModel.accountType = .business
                    }
                
                Text("business".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(viewModel.accountType == .business ? .hmIndigo : themeManager.currentTheme.white06_darkGray06)
            }
        }
    }
    
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("signup".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 20))
                .foregroundStyle(themeManager.currentTheme.label)
                
            Text("select_type".localized(localizationManager.language))
                .foregroundStyle(themeManager.currentTheme.white06_darkGray06)
                .font(.custom(Constants.comicFont, size: 14))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    
    private var nextButton: some View {
        HStack {
            CircleProgressButton(progress: .constant(100))
                .opacity(viewModel.nextButtonDisabled ? 0.7 : 1.0)
                .onTapGesture {
                    if !viewModel.nextButtonDisabled {
                        if let accountType = viewModel.accountType {
                            if accountType == .business {
                                isIndividual = false
                                viewModel.showBusinessSignupScreen()
                            } else {
                                isIndividual = true
                                viewModel.showIndividualSignupScreen()
                            }
                        }
                    }
                }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
    
    
    private var logo: some View {
        HStack {
            Image("Logo")
                .resizable()
                .frame(width: 92, height: 92)
                .padding(.top, UIScreen.main.bounds.height < 670 ? 20 : 100)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
