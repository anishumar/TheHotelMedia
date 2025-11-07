//
//  CustomShape4.swift
//  TheHotelMedia
//
//  Created by MAC on 17/10/24.
//

import SwiftUI


import SwiftUI

struct CustomShape4: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + 20, y: rect.minY))
            
            path.addLine(to: CGPoint(x: rect.maxX - 62, y: rect.minY))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - 42, y: rect.minY + 14),
                control: CGPoint(x: rect.maxX - 42, y: rect.minY)
            )
            
            path.addLine(to: CGPoint(x: rect.maxX - 42, y: rect.minY + 24))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - 22, y: rect.minY + 42),
                control: CGPoint(x: rect.maxX - 42, y: rect.minY + 42)
            )
            
            path.addLine(to: CGPoint(x: rect.maxX - 14, y: rect.minY + 42))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + 62),
                control: CGPoint(x: rect.maxX, y: rect.minY + 42)
            )
            
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 20))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX  - 20, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            
            path.addLine(to: CGPoint(x: rect.minX + 20, y: rect.maxY))
            
            path.addQuadCurve(
                to: CGPoint(
                    x: rect.minX,
                    y: rect.maxY - 20
                ),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 20))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + 20, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        }
    }
}
