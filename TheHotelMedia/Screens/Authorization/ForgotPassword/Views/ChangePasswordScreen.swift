//
//  ChangePasswordScreen.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import SwiftUI
import ActivityIndicatorView

struct ChangePasswordScreen: View {
    
    @StateObject var viewModel: ChangePasswordScreenViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    
    var body: some View {
        let height = Constants.screenHeight
        
        ZStack {
            BackgroundImageView()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    VStack {
                        logo
                    }
                    .frame(height: height > 667 ? height/3 : height/3.5)
                    VStack(spacing: 20) {
                        titleSection
                        
                        PasswordTextField(
                            textfieldText: $viewModel.passwordFieldText,
                            title: "password".localized(localizationManager.language),
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
                            placeholder: "enter_new_password_again".localized(localizationManager.language),
                            leftIcon: "LockIcon2",
                            rightIcon: $viewModel.rightIcon2,
                            isSecure: $viewModel.isSecure2) {
                                viewModel.isSecure2.toggle()
                                viewModel.rightIcon2 = viewModel.isSecure2 ? "EyeSlash" : "Eye"
                            }
                    }
                    .padding(.horizontal, 16)
                    VStack {
                        bottomButtonSection
                            .padding(.bottom, 30)
                    }
                    .frame(height: height > 667 ? height/3 : height/3.5)
                }
            }
            .clipped()
        }
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
        .onAppear {
            viewModel.addSubscribers()
        }
        .onDisappear {
            viewModel.cancelSubscriptions()
        }
    }
}


// MARK: - Preview
struct ChangePasswordScreen_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        ChangePasswordScreen(viewModel: ChangePasswordScreenViewModel(router: router, email: "", resetToken: ""))
            .environmentObject(LocalizationManager.shared)
    }
}



// MARK: - Components
extension ChangePasswordScreen {
    
    private var logo: some View {
        HStack {
            Image("Logo")
                .resizable()
                .frame(width: 92, height: 92)
        }
    }
    
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("enter_new_password".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 20))
                .foregroundColor(themeManager.currentTheme.label)
            
            HStack {
                Text("your_password_must_be_different_from_previous\n_used_password".localized(localizationManager.language))
                    .multilineTextAlignment(.leading)
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var bottomButtonSection: some View {
        ZStack {
            VStack {
                Button(action: {
                    viewModel.dismissScreen()
                }, label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.hmIndigo04_hmIndigo08)
                            .frame(width: 48)
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                            .tint(.white)
                    }
                })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            
            VStack {
                CircleProgressButton(progress: .constant(100))
                    .opacity(viewModel.nextButtonDisabled ? 0.7 : 1.0)
                    .onTapGesture {
                        if !viewModel.nextButtonDisabled {
                            viewModel.changePassword()
                        } else {
                            viewModel.errorText = "please_enter_the_same_password_in_both_the_fields".localized(localizationManager.language)
                            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: viewModel.errorText)
                        }
                    }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
    
    
    private var keyboardButtons: some View {
        HStack {
            Spacer()
            Button(action: {
                endEditing()
            }, label: {
                Text("done".localized(localizationManager.language))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.label)
                
            })
        }
    }
}
