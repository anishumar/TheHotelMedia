//
//  PasswordView.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI

struct PasswordView: View {
    
    @StateObject var viewModel: PasswordViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            
            VStack(spacing: 20) {
                Text("Enter your full name below, and we'll use it to personalize your experience.")
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                PasswordTextField(
                    textfieldText: $viewModel.passwordFieldText,
                    title: "Password",
                    placeholder: "Password",
                    leftIcon: "PersonIcon2",
                    isDisabled: true,
                    rightIcon: $viewModel.rightIcon,
                    isSecure: $viewModel.isSecure) {
                        viewModel.isSecure.toggle()
                        viewModel.rightIcon = viewModel.isSecure ? "EyeSlash" : "Eye"
                        
                    }
                
                Button(action: {
                    viewModel.showEnterEmailScreen()
                    
                }, label: {
                    Text("Change Password")
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundColor(.hmIndigo)
                })
                .offset(y: -10)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Preview

struct PasswordView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        PasswordView(viewModel: PasswordViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension PasswordView {
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(.white)
                .fontWeight(.bold)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .onTapGesture {
                    viewModel.dismissScreen()
                }
            
            Text("Password")
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(.white)
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
            .disabled(true)
        }
        .padding(.top, 16)
    }
}

