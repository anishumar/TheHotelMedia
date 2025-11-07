//
//  THMProgressBarView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import SwiftUI

struct THMProgressBarView: View {
    var timerProgress: CGFloat
    var index: Int
    
    var body: some View {
        GeometryReader { proxy in
            
            let width = proxy.size.width
            let progress = timerProgress - CGFloat(index)
            let perfectProgress = min(max(progress, 0), 1)
            
            Capsule()
                .fill(.gray.opacity(0.5))
                .overlay (
                    Capsule()
                        .fill(.hmIndigo)
                        .frame(width: width * perfectProgress)
                    
                    ,alignment: .leading
                )
        }.frame(height: Constants.progressBarHeight)
    }
}
