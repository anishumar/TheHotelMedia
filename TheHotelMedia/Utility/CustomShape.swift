//
//  CustomShape.swift
//  HotelMedia
//
//  Created by MAC on 31/07/24.
//

import SwiftUI

struct CustomShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + 20, y: rect.minY))
            
            path.addLine(to: CGPoint(x: rect.maxX - 66, y: rect.minY))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - 46, y: rect.minY + 16),
                control: CGPoint(x: rect.maxX - 46, y: rect.minY)
            )
            
            path.addLine(to: CGPoint(x: rect.maxX - 46, y: rect.minY + 26))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - 26, y: rect.minY + 46),
                control: CGPoint(x: rect.maxX - 46, y: rect.minY + 46)
            )
            
            path.addLine(to: CGPoint(x: rect.maxX - 16, y: rect.minY + 46))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + 66),
                control: CGPoint(x: rect.maxX, y: rect.minY + 46)
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
