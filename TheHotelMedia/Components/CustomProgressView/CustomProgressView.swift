//
//  RingProgressView.swift
//  TheHotelMedia
//
//  Created by MAC on 27/09/24.
//

import SwiftUI
import ActivityIndicatorView
import Lottie

struct CustomProgressView: View {
    
    @Binding var showIndicator: Bool
    var dimension: CGFloat = 50
    var lineWidth: CGFloat = 8
    var backgroundColor: Color = Color.black.opacity(0.5)
    var type: String = "normal"
    
    @StateObject var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            if showIndicator && type != "growingArc"{
                themeManager.currentTheme.backgroundColor.opacity(0.5).ignoresSafeArea()
            }
//            if type == "normal" {
//                ActivityIndicatorView(isVisible: $showIndicator, type: .gradient([.hmIndigo, .black.opacity(0.4)], .butt, lineWidth: lineWidth))
//                    .frame(width: dimension , height: dimension)
//            } else if type == "growingArc" {
//                ActivityIndicatorView(isVisible: $showIndicator, type: .growingArc(.hmIndigo, lineWidth: lineWidth))
//                    .frame(width: dimension , height: dimension)
//            }
            
            if showIndicator {
                if type == "normal" {
                    LottieView(animation: .named("MainScene"))
                        .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
                        .scaleEffect(0.2)
                } else if type == "growingArc" {
                    ActivityIndicatorView(isVisible: $showIndicator, type: .growingArc(.hmIndigo, lineWidth: lineWidth))
                        .frame(width: dimension , height: dimension)
                }
                
            }
        }
    }
}

#Preview {
    
    VStack {
        CustomProgressView(showIndicator: .constant(true))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
}
