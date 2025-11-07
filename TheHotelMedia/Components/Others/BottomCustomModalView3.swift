//
//  BottomCustomModalView3.swift
//  TheHotelMedia
//
//  Created by MAC on 11/11/24.
//

import SwiftUI

struct BottomCustomModalView3: View {
    
    var title: String = ""
    var rightButtonTitle: String = "No"
    var leftButtonTitle: String = "Yes"
    var backgroundColor: Color = .black.opacity(0.001)
    var onLeftButtonPressed: (() -> Void)? = nil
    var onRightButtonPressed: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    
    @StateObject var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(backgroundColor)
                .onTapGesture {
                    onDismiss?()
                }
            VStack(spacing: 12) {
                Text(title)
                    .font(.custom(Constants.comicFont, size: 14))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(themeManager.currentTheme.label)
                
                Rectangle()
                    .fill(.hmDarkerGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                
                HStack {
                    Button(action: {
                        onLeftButtonPressed?()
                    }, label: {
                        ZStack {
                            CapsuleBackground(borderColor: themeManager.currentTheme.mediumGray_black, backgroundColor: themeManager.currentTheme.darkGray05_white)
                            Text(leftButtonTitle)
                                .font(.custom(Constants.comicFont, size: 14))
                                .foregroundColor(themeManager.currentTheme.white06_darkGray06)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    })
                    
                    Button(action: {
                        onRightButtonPressed?()
                    }, label: {
                        ZStack {
                            CapsuleBackground(borderColor: themeManager.currentTheme.mediumGray_black, backgroundColor: themeManager.currentTheme.darkGray05_white)
                            Text(rightButtonTitle)
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
    BottomCustomModalView3()
}
