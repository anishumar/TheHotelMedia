//
//  SocialLoginButton.swift
//  HotelMedia
//
//  Created by MAC on 26/07/24.
//

import SwiftUI

struct SocialLoginButton: View {
    
    var icon: String = "Logo"
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.darkGray_hmIndigo03)
                .frame(width: 48)
            
            Circle()
                .stroke(lineWidth: 1)
                .fill(.hmIndigo)
                .frame(width: 48)
            
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 27, height: 27)
                .clipShape(Circle())
        }
    }
}

#Preview {
    SocialLoginButton()
}
