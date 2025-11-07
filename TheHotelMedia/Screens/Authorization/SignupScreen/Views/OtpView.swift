//
//  OtpView.swift
//  HotelMedia
//
//  Created by MAC on 14/08/24.
//

import SwiftUI
import ActivityIndicatorView

struct OtpView: View {
    
    @StateObject var viewModel: OtpViewModel
    @AppStorage("isIndividual") var isIndividual: Bool = true
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
                .frame(maxWidth: .infinity)
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.001))
                        .onTapGesture {
                            endEditing()
                        }
                }
                VStack(spacing: 20) {
                    titleSection
                        .onTapGesture {
                            endEditing()
                        }
                    otpFieldSection
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
    }
}


// MARK: - Preview
struct OtpView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        OtpView(viewModel: OtpViewModel(router: router, emailID: "", otpType: ""))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension OtpView {
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("confirm_your_email".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 20))
                .foregroundColor(themeManager.currentTheme.label)
            
            HStack {
                Text("we_have_sent_5_digits".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                +
                Text(viewModel.emailID)
                    .font(.custom(Constants.comicBold, size: 14))
                    .foregroundColor(.hmIndigo)
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard ) {
                keyboardButtons
            }
        }
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
    
    
    private var logo: some View {
        HStack {
            Image("Logo")
                .resizable()
                .frame(width: 92, height: 92)
        }
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
                            if viewModel.otpType == "email-verification" {
                                viewModel.verifyOtp()
                            } else {
                                viewModel.verifyForgotPasswordOtp()
                            }
                            
                        }
                    }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
}
