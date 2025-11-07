//
//  CustomShape3.swift
//  HotelMedia
//
//  Created by MAC on 22/08/24.
//

import SwiftUI

struct CustomShape3: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + 14, y: rect.minY))
            
            path.addLine(to: CGPoint(x: rect.maxX - 48, y: rect.minY))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - 34, y: rect.minY + 14),
                control: CGPoint(x: rect.maxX - 34, y: rect.minY)
            )
            
            path.addLine(to: CGPoint(x: rect.maxX - 34, y: rect.minY + 20))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - 20, y: rect.minY + 34),
                control: CGPoint(x: rect.maxX - 34, y: rect.minY + 34)
            )
            
            path.addLine(to: CGPoint(x: rect.maxX - 14, y: rect.minY + 34))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + 48),
                control: CGPoint(x: rect.maxX, y: rect.minY + 34)
            )
            
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 14))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX  - 14, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            
            path.addLine(to: CGPoint(x: rect.minX + 14, y: rect.maxY))
            
            path.addQuadCurve(
                to: CGPoint(
                    x: rect.minX,
                    y: rect.maxY - 14
                ),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 14))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + 14, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        }
    }
}
