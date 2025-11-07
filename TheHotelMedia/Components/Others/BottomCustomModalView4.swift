//
//  BottomCustomModalView4.swift
//  TheHotelMedia
//
//  Created by MAC on 13/11/24.
//

import SwiftUI

struct BottomCustomModalView4: View {
    
    var title: String? = nil
    var topButtonTitle: String
    var bottomButtonTitle: String
    var backgroundColor: Color = .black.opacity(0.001)
    var onTopButtonPressed: (() -> Void)?
    var onBottomButtonPressed: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    @StateObject var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(backgroundColor)
                .onTapGesture {
                    onDismiss?()
                }
            
            VStack(spacing: 12) {
                
                if let title {
                    Text(title)
                        .font(.custom(Constants.comicFont, size: 14))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(themeManager.currentTheme.label)
                    
                    Rectangle()
                        .fill(.hmDarkerGray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 1)
                }
                
                VStack {
                    Button(action: {
                        onTopButtonPressed?()
                    }, label: {
                        ZStack {
                            CapsuleBackground(borderColor: themeManager.currentTheme.mediumGray_black, backgroundColor: themeManager.currentTheme.darkGray05_white)
                            Text(topButtonTitle)
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    })
                    
                    Button(action: {
                        onBottomButtonPressed?()
                    }, label: {
                        ZStack {
                            CapsuleBackground(borderColor: themeManager.currentTheme.mediumGray_black, backgroundColor: themeManager.currentTheme.darkGray05_white)
                            Text(bottomButtonTitle)
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    })
                }
            }
            .padding(.bottom, 16)
            .padding(.top, 26)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 130)
            .background(
                CustomShape2()
                    .fill(themeManager.currentTheme.darkGray_white)
                    .overlay(
                        Image(themeManager.currentTheme.SheetIndicator)
                            .offset(y: -3)
                        , alignment: .top
                    )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    BottomCustomModalView4(topButtonTitle: "View Profile", bottomButtonTitle: "Block Profile")
}
