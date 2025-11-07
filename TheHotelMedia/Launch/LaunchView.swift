//
//  LaunchView.swift
//  HotelMedia
//
//  Created by MAC on 26/07/24.
//

import SwiftUI

struct LaunchView: View {
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
            
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LaunchView()
}
