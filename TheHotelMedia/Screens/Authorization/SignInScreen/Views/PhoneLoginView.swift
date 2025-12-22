//
//  PhoneLoginView.swift
//  TheHotelMedia
//
//  Created by MAC on 25/03/25.
//

import SwiftUI
import SwiftfulRouting
import CountryPickerView

struct PhoneLoginView: View {
    
    @StateObject var viewModel: PhoneLoginViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    // Header
                    HStack {
                        Button {
                            viewModel.router.dismissScreen()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.label)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Sign in with phone")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.label)
                        
                        Text("Enter your mobile number to receive an OTP")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.currentTheme.label_06)
                    }
                    .padding(.top, 20)
                    
                    // Phone Input
                    HStack(spacing: 12) {
                        SUCountryPickerView(selectedCountry: $viewModel.selectedCountry)
                            .frame(width: 80, height: 50)
                        
                        Divider()
                            .frame(height: 24)
                            .background(Color.gray.opacity(0.3))
                        
                        // Number Field
                        TextField("Enter phone number", text: $viewModel.phoneNumber)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.currentTheme.label)
                            .frame(height: 50)
                    }
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .background(Color.white.opacity(0.05).cornerRadius(25))
                    )
                    .padding(.horizontal)
                    
                    Text("We'll send a verification code to this number.")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.label_06)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, -16)
                    
                    // Send OTP Button
                    Button {
                        viewModel.requestOtp()
                    } label: {
                        Text("Send OTP")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.hmIndigo)
                            .cornerRadius(28)
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    Spacer()
                }
                
                // OTP Modal Overlay
                if viewModel.showVerifyModal {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("Enter Verification Code")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.label)
                        
                        Text("Enter the OTP sent to \(viewModel.dialCode) \(viewModel.phoneNumber)")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.label_06)
                            .multilineTextAlignment(.center)
                        
                        TextField("OTP", text: $viewModel.otpFieldText)
                            .keyboardType(.numberPad)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        
                        if !viewModel.countDownEnded {
                            Text("Resend code in \(viewModel.counter)s")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Button("Resend Code") {
                                viewModel.requestOtp(resend: true)
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        Button {
                            viewModel.verifyOtpAndLogin()
                        } label: {
                            Text("Verify & Sign In")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Button("Cancel") {
                            withAnimation {
                                viewModel.showVerifyModal = false
                            }
                        }
                        .foregroundColor(.red)
                    }
                    .padding(24)
                    .background(themeManager.currentTheme.backgroundColor)
                    .cornerRadius(20)
                    .padding()
                    .transition(.scale)
                }
                
                if viewModel.showLoadingIndicator {
                    CustomProgressView(showIndicator: $viewModel.showLoadingIndicator)
                }
            }
            .navigationBarHidden(true)
    }
}
