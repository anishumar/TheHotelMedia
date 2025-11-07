//
//  HMCustomButton.swift
//  HotelMedia
//
//  Created by MAC on 31/07/24.
//

import SwiftUI

struct HMCustomButton: View {
    
    @Binding var icon: String
    @Binding var count: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 6) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
            
            Text("\(count)")
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundStyle(themeManager.currentTheme.label)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .stroke(lineWidth: 1)
                .fill(.hmIndigo.opacity(0.6))
        )
    }
}


struct HMCustomButton2: View {
    
    var icon: String
    var count: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 6) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
            
            Text("\(count)")
                .font(.custom(Constants.comicFont, size: 12))
                .foregroundStyle(themeManager.currentTheme.label)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .stroke(lineWidth: 1)
                .fill(.hmIndigo.opacity(0.6))
        )
    }
}

#Preview {
    HMCustomButton(icon: .constant("share"), count: .constant("10"))
}
