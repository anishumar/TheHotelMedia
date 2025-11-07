//
//  CustomSwitch.swift
//  HotelMedia
//
//  Created by MAC on 16/08/24.
//

import SwiftUI

struct CustomSwitch: View {
    
    @Binding var isActive: Bool
    var onPressed: ((Bool) -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Capsule()
            .fill(isActive ? .white : themeManager.currentTheme.darkGray_mediumGray03)
            .frame(width: 34, height: 22)
            .overlay(
                Circle()
                    .fill(isActive ? .hmIndigo : .white)
                    .frame(width: 18)
                    .padding(.horizontal, 2)
                    
                ,alignment: isActive ? .trailing : .leading
            )
            .onTapGesture {
                isActive.toggle()
                onPressed?(isActive)
            }
            .animation(.linear(duration: 0.2), value: isActive)
    }
}

#Preview {
    CustomSwitch(isActive: .constant(true))
}
