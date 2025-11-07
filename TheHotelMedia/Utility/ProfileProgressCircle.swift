//
//  ProfileProgressCircle.swift
//  HotelMedia
//
//  Created by MAC on 02/09/24.
//

import SwiftUI


struct ProfileProgressCircle: Shape {
    
    @Binding var progress: CGFloat
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.midY),
                radius: rect.height / 2,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 3.6 * progress),
                clockwise: false
            )
            
        }
    }
    
}
