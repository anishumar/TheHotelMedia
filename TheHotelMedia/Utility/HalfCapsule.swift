//
//  HalfCapsule.swift
//  HotelMedia
//
//  Created by MAC on 29/07/24.
//

import Foundation
import SwiftUI


struct HalfCapsule: Shape {
    func path(in rect: CGRect) -> Path {
        Path{ path in
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: rect.maxX - (rect.height / 2), y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.maxX - (rect.height / 2), y: rect.midY),
                radius: rect.height / 2,
                startAngle: Angle(degrees: 270),
                endAngle: Angle(degrees: 90),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: .zero)
            
        }
    }
    
    
    
}
