//
//  HeaderView.swift
//  HotelMedia
//
//  Created by MAC on 01/08/24.
//

import SwiftUI

struct HeaderView: View {
    
    private var onBellPressed: (() -> Void)?
    
    init(onBellPressed: (() -> Void)? = nil) {
        self.onBellPressed = onBellPressed
    }
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("hasReadNotifcation") var hasReadNotifcation: Bool = false
    
    var body: some View {
        HStack {
            Image(themeManager.currentTheme.Title)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 38)
            
            Spacer()
            
            Image(themeManager.currentTheme.BellIcon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(themeManager.currentTheme.label)
                .padding(.vertical, 8)
                .padding(.leading)
                .background(.black.opacity(0.001))
                .onTapGesture {
                    onBellPressed?()
                }
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .opacity(hasReadNotifcation ? 0 : 1.0)
                        .offset(x: -3, y: 5)
                }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(themeManager.currentTheme.backgroundColor)
    }
}

// MARK: - Preview
struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView()
            .environmentObject(LocalizationManager.shared)
    }
}
