//
//  EnterEmailScreen.swift
//  TheHotelMedia
//
//  Created by MAC on 26/09/24.
//

import SwiftUI
import ActivityIndicatorView

struct EnterEmailScreen: View {
    
    @StateObject var viewModel: EnterEmailScreenViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let height = UIScreen.main.bounds.height/3
        ScrollView(.vertical) {
            VStack {
                VStack {
                    logo
                }
                .frame(height: height)
                VStack(spacing: 20) {
                    titleSection
                    GrayTextField(
                        textfieldText: $viewModel.emailFieldText,
                        title: "email_address".localized(localizationManager.language),
                        placeholder: "enter_email_address".localized(localizationManager.language),
                        leftIcon: "MessageIcon2",
                        keyboardtype: .emailAddress,
                        textInputCapitalization: .never,
                        rightIcon: .constant(nil)
                    )
                }
                .padding(.horizontal, 16)
                .frame(height: height)
                VStack {
                    bottomButtonSection
                        .padding(.bottom, 30)
                }
                .frame(height: height)
            }
            .background(
                BackgroundImageView()
            )
        }
        .scrollDisabled(true)
        .ignoresSafeArea()
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
struct EnterEmailScreen_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EnterEmailScreen(viewModel: EnterEmailScreenViewModel(router: router))
    }
}



// MARK: - Components
extension EnterEmailScreen {
    
    private var logo: some View {
        HStack {
            Image("Logo")
                .resizable()
                .frame(width: 92, height: 92)
        }
    }
    
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("reset_your_password".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 20))
                .foregroundColor(themeManager.currentTheme.label)
            
            HStack {
                Text("enter_your_email_address_below_and_we’ll_send_you_a_link_with_instructions".localized(localizationManager.language))
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
                            viewModel.forgotPassword()
                        } else {
                            viewModel.errorText = "please_enter_a_valid_email_address".localized(localizationManager.language)
                            ErrorModalManager.showErrorModal(router: viewModel.router, errorText: viewModel.errorText)
                        }
                    }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
    
}
