//
//  EnterEmailView.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//


import SwiftUI

struct EnterEmailView: View {
    
    @StateObject var viewModel: EnterEmailViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text("Reset Your Password")
                        .font(.custom(Constants.comicFont, size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Enter your email address below and we’ll send you a link with instructions.")
                        .font(.custom(Constants.comicFont, size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GrayTextField(textfieldText: $viewModel.emailFieldText, title: "Email Address", placeholder: "Enter Email Address", leftIcon: "PersonIcon2", rightIcon: .constant(nil))
                
                nextButton
            }
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Preview

struct EnterEmailView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EnterEmailView(viewModel: EnterEmailViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension EnterEmailView {
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
            
            Text("Change Passoword")
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
        }
        .padding(.top, 16)
    }
    
    
    private var nextButton: some View {
        HStack {
            CircleProgressButton(progress: .constant(100))
                .opacity(viewModel.nextButtonDisabled ? 0.7 : 1.0)
                .onTapGesture {
                    if !viewModel.nextButtonDisabled {
                        viewModel.showConfirmEmailscreen()
                    }
                }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, UIScreen.main.bounds.height < 670 ? 20 : 30)
    }
}

