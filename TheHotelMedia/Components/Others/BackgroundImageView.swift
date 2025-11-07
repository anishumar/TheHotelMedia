//
//  BackgroundImageView.swift
//  TheHotelMedia
//
//  Created by MAC on 17/12/24.
//

import SwiftUI

struct BackgroundImageView: View {
    
    var image: String = "SignInBackground"
    var isDefaultImage: Bool = true
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Rectangle()
            .fill(themeManager.currentTheme.backgroundColor)
            .overlay(
                Image(isDefaultImage ? themeManager.currentTheme.SignInBackground : image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    
            )
            .clipped()
            .ignoresSafeArea()
    }
}

#Preview {
    BackgroundImageView()
}
