//
//  CustomCheckView.swift
//  TheHotelMedia
//
//  Created by MAC on 13/02/25.
//

import SwiftUI

struct CustomCheckView: View {
    
    @Binding var bool: Bool
    var icon: String
    var title: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            HStack {
                Image(icon)
                    .resizable()
                    .renderingMode(.template)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                
                Text(title)
                    .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
                
            }
            
            Spacer()
            
            Image(systemName: bool ? "checkmark.circle.fill" : "checkmark.circle")
                .font(.system(size: 22))
                .foregroundColor(themeManager.currentTheme.hmIndigo_hmIndigo05)
                .onTapGesture {
                    bool.toggle()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                Capsule()
                    .fill(themeManager.currentTheme.darkGray05_white)
                Capsule()
                    .stroke(lineWidth: 1)
                    .fill(.hmDarkerGray)
            }
        )
    }
}
