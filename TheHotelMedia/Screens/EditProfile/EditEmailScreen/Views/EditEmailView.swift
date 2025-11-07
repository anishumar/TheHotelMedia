//
//  EditEmailView.swift
//  HotelMedia
//
//  Created by MAC on 19/08/24.
//

import SwiftUI

struct EditEmailView: View {
    
    @StateObject var viewModel: EditEmailViewModel
    var onEmailChanged: ((String) -> Void)?
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            
            VStack(spacing: 20) {
                Text("edit_email_heading".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                GrayTextField(
                    textfieldText: $viewModel.emailFieldText,
                    title: "email".localized(localizationManager.language),
                    placeholder: "email".localized(localizationManager.language),
                    leftIcon: "MessageIcon2",
                    rightIcon: .constant(nil)
                )
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.001))
                        .allowsHitTesting(true)
                }
            }
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Preview

struct EditEmailView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EditEmailView(viewModel: EditEmailViewModel(router: router, currentEmail: "some@gmail.com"))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension EditEmailView {
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
            
            Text("email".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                viewModel.dismissScreen()
                onEmailChanged?(viewModel.emailFieldText)
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
                    .opacity(viewModel.emailFieldText == viewModel.currentEmail || viewModel.emailFieldText.isEmpty ? 0.5 : 1.0)
            })
            .disabled(viewModel.emailFieldText.isEmpty || viewModel.emailFieldText == viewModel.currentEmail)
        }
        .padding(.top, 16)
    }
}
