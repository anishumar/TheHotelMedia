//
//  CustomCounterView.swift
//  TheHotelMedia
//
//  Created by MAC on 13/02/25.
//

import SwiftUI

struct CustomCounterView: View {
    
    @Binding var count: Int
    var icon: String? = nil
    var title: String
    var backgroundColor: Color? = nil
    var allowBorder: Bool = true
    var minCount: Int = 0
    var maxCount: Int = 1000
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            HStack {
                if let icon {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .font(.system(size: 22))
                        .foregroundColor(themeManager.currentTheme.white08_darkGray08)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                }
                
                
                Text(title)
                    .withComicFont(14, color: themeManager.currentTheme.white06_darkGray06)
                
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Button {
                    count -= 1
                } label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                        Image("Minus")
                            .resizable()
                            .scaledToFit()
                            .padding(4.5)
                    }
                    .frame(width: 22, height: 22)
                }
                .opacity(count <= minCount ? 0.5 : 1.0)
                .disabled(count <= minCount)
                
                Text("\(count)")
                    .withComicFont(14, color: themeManager.currentTheme.label)
                
                Button {
                    count += 1
                } label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.hmIndigo_hmIndigo05)
                        Image("Plus")
                            .resizable()
                            .scaledToFit()
                            .padding(4.5)
                    }
                    .frame(width: 22, height: 22)
                }
                .opacity(count >= maxCount ? 0.5 : 1.0)
                .disabled(count >= maxCount)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                Capsule()
                    .fill(backgroundColor == nil ? themeManager.currentTheme.darkGray05_white : backgroundColor!)
                
                if allowBorder {
                    Capsule()
                        .stroke(lineWidth: 1)
                        .fill(.hmDarkerGray)
                }
            }
        )
    }
}
