//
//  EditContactView.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI

struct EditContactView: View {
    
    @StateObject var viewModel: EditContactViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 32) {
            header
            
            Text("edit_contact_heading".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            
            contactField
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.001))
                        .allowsHitTesting(true)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                viewModel.setVerificationDetails()
                                viewModel.showContactModal = true
                            }
                        }
                }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
        .overlay(content: {
            ZStack {
                if viewModel.showContactModal || viewModel.showVerifyModal {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                viewModel.showContactModal = false
                            }
                        }
                }
                
                phoneNumberModal
                verifyModal
            }
        })
        .overlay {
            CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
        }
    }
}

// MARK: - Preview
struct EditContactView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EditContactView(viewModel: EditContactViewModel(router: router, currentDialCode: "", currentPhoneNumber: "9595959595"))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension EditContactView {
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
            
            Text("contact_number".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                viewModel.dismissScreen()
//                onChangedName?(viewModel.nameFieldText)
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
                    .opacity(viewModel.contactFieldText == viewModel.currentPhoneNumber || viewModel.contactFieldText.isEmpty ? 0.5 : 1.0)
            })
            .disabled(viewModel.contactFieldText.isEmpty || viewModel.contactFieldText == viewModel.currentPhoneNumber)
        }
        .padding(.top, 16)
    }
    
    
    private var contactField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("contact_number".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            
            HStack(spacing: 5) {
                if let image = viewModel.selectedCountry?.flag {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                        .overlay(
                            SUCountryPickerView(selectedCountry: $viewModel.selectedCountry)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        )
                } else {
                    Image("IndiaFlag")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 18, height: 18)
                        .overlay(
                            SUCountryPickerView(selectedCountry: $viewModel.selectedCountry)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        )
                    
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.label)
                
                TextField(
                    "",
                    text: $viewModel.contactFieldText,
                    prompt:
                        Text("contact_number".localized(localizationManager.language))
                        .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        .font(.custom(Constants.comicFont, size: 14))
                )
                .font(.custom(Constants.comicFont, size: 16))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .autocorrectionDisabled()
                .frame(maxWidth: .infinity)
                
            }
            .padding(.leading, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                CapsuleBackground(height: 46, borderColor: viewModel.contactFieldText.isEmpty ? .hmDarkerGray : .hmIndigo, backgroundColor: themeManager.currentTheme.darkGray05_white)
            )
            
        }
    }
    
    
    private var phoneNumberModal: some View {
        ZStack {
            if viewModel.showContactModal {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Phone number!")
                        .withComicFont(16, color: themeManager.currentTheme.label)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ContactTextField(contactText: $viewModel.toVerifyPhoneNumber, selectedCountry: $viewModel.toVerifyCountry, isBold: true, title: "Phone number", placeholder: "Phone number")
                        Text("A 5 digit OTP will be sent via SMS to verify your mobile number.")
                            .withComicFont(10, color: themeManager.currentTheme.white06_darkGray06)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Button {
                        viewModel.requestOtp()
                        endEditing()
                    } label: {
                        Text("Proceed".localized(localizationManager.language))
                            .withComicFont(16, color: .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                            )
                    }
                    .padding(.bottom, 16)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            keyboardButton
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentTheme.darkGray_white)
//                        .fill(.ultraThinMaterial)
                )
                .padding()
                .transition(AnyTransition.push(from: .trailing))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
    private var verifyModal: some View {
        ZStack {
            if viewModel.showVerifyModal {
                VStack(alignment: .leading, spacing: 12) {
                    Text("OTP Verification")
                        .withComicFont(16, color: themeManager.currentTheme.label)
                    
                    otpFieldSection
                    
                    Button {
                        endEditing()
                        viewModel.verifyOtp()
                    } label: {
                        Text("Next".localized(localizationManager.language))
                            .withComicFont(16, color: .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                            )
                    }
                    .padding(.bottom, 16)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            keyboardButton
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme.darkGray_white)
//                        .fill(.ultraThinMaterial)
                )
                .padding()
                .transition(AnyTransition.push(from: .trailing))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
    private var otpFieldSection: some View {
        var phoneNumber: String = viewModel.toVerifyDialCode + " "
        for _ in 0..<5 {
            phoneNumber.append("X")
        }
        
        return VStack(alignment: .leading, spacing: 5) {
            Text("Enter the OTP you received to \(phoneNumber)")
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                .onAppear {
                    
                }
            
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
    
    
    private var countDownTimer: some View {
        Text("resend_in".localized(localizationManager.language) + "\(viewModel.counter)sec")
            .font(.custom(Constants.comicFont, size: 14))
            .foregroundColor(themeManager.currentTheme.white06_darkGray06)
            .padding(.trailing, 16)
    }
    
    
    private var otpField: some View {
        TextField(
            "",
            text: $viewModel.otpFieldText,
            prompt: Text("Enter verification code".localized(localizationManager.language))
                .font(.custom(Constants.comicFont, size: 14))
                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
        )
        .keyboardType(.numberPad)
        .font(.custom(Constants.comicFont, size: 14))
        .foregroundColor(themeManager.currentTheme.label)
        .padding(.leading, 16)
        .frame(maxWidth: .infinity)
//        .toolbar {
//            ToolbarItemGroup(placement: .keyboard ) {
//                keyboardButtons
//            }
//        }
    }
    
    
    private var resendButton: some View {
        Button(action: {
            viewModel.startTimer()
            viewModel.requestOtp(resend: true)
        }, label: {
            Text("Resend OTP".localized(localizationManager.language))
                .withComicFont(14, color: themeManager.currentTheme.label)
        })
        .padding(.trailing, 16)
    }
    
    
    private var keyboardButton: some View {
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
