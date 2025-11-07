//
//  FractionalStar.swift
//  HotelMedia
//
//  Created by MAC on 31/07/24.
//

import SwiftUI

struct FractionalStar: View {
    
    var fraction: CGFloat
    
    var body: some View {
        ZStack {
            starView
                .overlay(
                    overlayView
                        .mask(starView)
                )
        }
    }
    
    
}

#Preview {
    FractionalStar(fraction: 0.3)
        .frame(width: 100, height: 100)
}


extension FractionalStar {
    private var starView: some View {
        Image("RatingStar")
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(.hmLightGray)
            .scaledToFit()
    }
    
    
    private var overlayView: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                ForEach(1..<11) { index in
                    Rectangle()
                        .fill(Int(fraction * 10) >= index ? .yellow : .black.opacity(0.001))
                        
                }
            }
        }
    }
}
