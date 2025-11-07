//
//  EditAddressView.swift
//  TheHotelMedia
//
//  Created by MAC on 19/11/24.
//

import SwiftUI

struct EditAddressView: View {
    
    @StateObject var viewModel: EditAddressViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            header
            
            VStack(spacing: 20) {
                Text("edit_billing_address_headline".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                GrayTextField(
                    textfieldText: $viewModel.addressFieldText,
                    title: "address".localized(localizationManager.language),
                    placeholder: "address".localized(localizationManager.language),
                    leftIcon: "PinWithMap",
                    rightIcon: .constant(nil)
                )
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.001))
                        .onTapGesture {
                            viewModel.showPlaceSearch.toggle()
                        }
                }
                .fullScreenCover(isPresented: $viewModel.showPlaceSearch) {
                    PlacesSearchRepresentable(selectedPlace: $viewModel.selectedPlace, isPresented: $viewModel.showPlaceSearch)
                        .environmentObject(themeManager)
                        .edgesIgnoringSafeArea(.all) // Make the autocomplete view full-screen
                }
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

struct EditAddressView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        EditAddressView(viewModel: EditAddressViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}



// MARK: - Components

extension EditAddressView {
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
            
            Text("billing_address".localized(localizationManager.language))
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(themeManager.currentTheme.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
            Button(action: {
                if let address = viewModel.selectedAddress {
                    viewModel.uploadBillingAddress(address: address)
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
                    .opacity(viewModel.addressFieldText == viewModel.currentAddress || viewModel.addressFieldText.isEmpty ? 0.5 : 1.0)
            })
            .disabled(viewModel.addressFieldText.isEmpty || viewModel.addressFieldText == viewModel.currentAddress)
        }
        .padding(.top, 16)
    }
}
