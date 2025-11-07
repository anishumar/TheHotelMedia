//
//  AboutUsView.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI

struct AboutUsView: View {
    @StateObject var viewModel: AboutUsViewModel
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                Text("about_us_text".localized(localizationManager.language))
                    .font(.custom(Constants.comicFont, size: 14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.top, 50)
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(
            header
            , alignment: .top
        )
    }
}

// MARK: - Preview
struct AboutUsView_Previews: PreviewProvider {
    static var previews: some View {
        @Environment(\.router) var router
        AboutUsView(viewModel: AboutUsViewModel(router: router))
            .environmentObject(LocalizationManager.shared)
    }
}


// MARK: - Components

extension AboutUsView {
    
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
            
            Text("About Us")
                .font(.custom(Constants.comicBold, size: 18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .background(.black)
    }
}
