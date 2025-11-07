//
//  ConfirmEmailView.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//


import SwiftUI

struct ConfirmEmailView: View {
    
    @StateObject var viewModel: ConfirmEmailViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            
            VStack(spacing: 20) {
                
                VStack(spacing: 10) {
                    Text("sent_verfication_code".localized(localizationManager.language))
                    +
                    Text(viewModel.email)
                        .foregroundColor(.hmIndigo)
                }
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                
                otpFieldSection
                nextButton
            }
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}

// MARK: - Preview

struct ConfirmEmailView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        ConfirmEmailView(viewModel: ConfirmEmailViewModel(router: router, email: ""))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension ConfirmEmailView {
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
                    .opacity(0.5)
            })
        }
        .padding(.top, 16)
    }
    
    
    private var nextButton: some View {
        HStack {
            CircleProgressButton(progress: .constant(100))
                .opacity(viewModel.nextButtonDisabled ? 0.7 : 1.0)
                .onTapGesture {
                    if !viewModel.nextButtonDisabled {
                        endEditing()
                        viewModel.verifyForgotPasswordOtp()
                    }
                }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
    
    
    private var otpFieldSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("enter_verification_code".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            
            HStack {
                otpField
                if viewModel.countDownEnded {
                    resendButton
                } else {
                    countDownTimer
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                CapsuleBackground(
                    height: 48,
                    borderWidth: 1,
                    borderColor: themeManager.currentTheme.mediumGray_mediumGray03,
                    backgroundColor: themeManager.currentTheme.darkGray05_white
                )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    private var otpField: some View {
        TextField(
            "",
            text: $viewModel.otpFieldText,
            prompt: Text("enter_your_otp".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        )
        .onChange(of: viewModel.otpFieldText) { newValue in
            if newValue.count > 5 {
                viewModel.otpFieldText = String(newValue.prefix(5))
            }
        }
        .keyboardType(.numberPad)
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.label)
        .padding(.leading, 16)
        .frame(maxWidth: .infinity)
    }
    
    
    private var countDownTimer: some View {
        Text("resend_in".localized(localizationManager.language) + "\(viewModel.counter)sec")
            .font(.custom(Constants.comicFont, size: 14))
            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            .padding(.trailing, 16)
    }
    
    
    private var resendButton: some View {
        Button(action: {
            viewModel.startTimer()
            viewModel.resendOtp()
        }, label: {
            Text("resend".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 14))
                .foregroundColor(.hmIndigo)
        })
        .padding(.trailing, 16)
    }
}


