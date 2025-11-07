//
//  CircleProgressButton.swift
//  HotelMedia
//
//  Created by MAC on 26/07/24.
//

import SwiftUI

struct CircleProgressButton: View {
    
    @Binding var progress: CGFloat
    var lineWidth: CGFloat = 3.5
    var applyTheme: Bool = true
    var hideProgress: Bool = false
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            IntroProgressCircle(progress: $progress)
                .stroke(lineWidth: lineWidth)
                .foregroundStyle(.hmIndigo)
                .rotationEffect(Angle(degrees: -90))
                .background(
                    Circle()
                        .stroke(lineWidth: lineWidth)
                        .foregroundStyle(.hmDarkGray)
                )
                .frame(width: 58, height: 58)
                .opacity(hideProgress ? 0.0 : 1.0)
            
            Circle()
                .fill(applyTheme ? themeManager.currentTheme.white_hmIndigo : .white)
                .frame(width: 44, height: 44)
            
            Image(systemName: "chevron.right")
                .fontWeight(.bold)
                .foregroundStyle(applyTheme ? themeManager.currentTheme.hmIndigo_white : .hmIndigo)
        }
    }
}

#Preview {
    CircleProgressButton(progress: .constant(25))
}
