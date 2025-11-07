//
//  THMProgressBarView2.swift
//  TheHotelMedia
//
//  Created by MAC on 31/01/25.
//

import SwiftUI

struct THMProgressBarView2: View {
    
    var index: Int
    @Binding var currentIndex: Int
    @Binding var storyProgress: Float
    @State var progress: CGFloat = 0
    
    var body: some View {
        GeometryReader { proxy in
            
            let width = proxy.size.width/100
            
            Capsule()
                .fill(.gray.opacity(0.5))
                .overlay (
                    Capsule()
                        .fill(.hmIndigo)
                        .frame(width: width * progress)
                    
                    ,alignment: .leading
                )
                .onChange(of: storyProgress) { newValue in
                    if currentIndex == index {
                        progress = min(CGFloat(newValue), 100)
                        
                    } else if currentIndex < index {
                        progress = 0
                    } else {
                        progress = 100
                    }
                }
        }.frame(height: Constants.progressBarHeight)
    }
}


