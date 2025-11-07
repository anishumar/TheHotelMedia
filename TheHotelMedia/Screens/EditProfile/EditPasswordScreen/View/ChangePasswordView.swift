//
//  ChangePasswordView.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI


struct ChangePasswordView: View {
    
    @StateObject var viewModel: ChangePasswordViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text("enter_new_password_heading".localized(localizationManager.language))
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                PasswordTextField(
                    textfieldText: $viewModel.passwordFieldText,
                    title: "enter_new_password".localized(localizationManager.language),
                    placeholder: "enter_new_password".localized(localizationManager.language),
                    leftIcon: "LockIcon2",
                    rightIcon: $viewModel.rightIcon,
                    isSecure: $viewModel.isSecure) {
                        viewModel.isSecure.toggle()
                        viewModel.rightIcon = viewModel.isSecure ? "EyeSlash" : "Eye"
                        
                    }
                
                PasswordTextField(
                    textfieldText: $viewModel.passwordFieldText2,
                    title: "retype_password".localized(localizationManager.language),
                    placeholder: "retype_password".localized(localizationManager.language),
                    leftIcon: "LockIcon2",
                    rightIcon: $viewModel.rightIcon2,
                    isSecure: $viewModel.isSecure2) {
                        viewModel.isSecure2.toggle()
                        viewModel.rightIcon2 = viewModel.isSecure2 ? "EyeSlash" : "Eye"
                        
                    }
            }
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Preview

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        ChangePasswordView(viewModel: ChangePasswordViewModel(router: router, email: "", resetToken: ""))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension ChangePasswordView {
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.label)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    viewModel.dismissScreen()
                }
            
            Text("change_password".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                if viewModel.nextButtonDisabled {
                    viewModel.showErrorMessage()
                } else {
                    viewModel.changePassword()
                }
                
            }, label: {
                Circle()
                    .fill(.hmIndigo.opacity(0.5))
                    .frame(width: 28)
                    .overlay(
                        Image("Tick")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    )
                    .opacity(viewModel.nextButtonDisabled ? 0.5 : 1.0)
            })
        }
        .padding(.top, 16)
    }
}


