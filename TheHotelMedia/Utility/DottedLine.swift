//
//  DottedLine.swift
//  HotelMedia
//
//  Created by MAC on 30/07/24.
//

import SwiftUI


struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
    }
    
}
