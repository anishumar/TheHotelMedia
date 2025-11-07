//
//  CustomShape2.swift
//  HotelMedia
//
//  Created by MAC on 01/08/24.
//

import Foundation
import SwiftUI


struct CustomShape2: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + 25, y: rect.minY))
            
            path.addLine(to: CGPoint(x: rect.midX - 48, y: rect.minY))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.midX - 24, y: rect.minY + 10 ),
                control: CGPoint(x: rect.midX - 36, y: rect.minY)
            )
            
            path.addLine(to: CGPoint(x: rect.midX - 10, y: rect.minY + 20))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.midX + 10, y: rect.minY + 20),
                control: CGPoint(x: rect.midX, y: rect.minY + 25)
            )
            
            path.addLine(to: CGPoint(x: rect.midX + 24, y: rect.minY + 10))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.midX + 48, y: rect.minY),
                control: CGPoint(x: rect.midX + 36, y: rect.minY)
            )
            
            path.addLine(to: CGPoint(x: rect.maxX - 25, y: rect.minY))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + 25),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 25))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - 25, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            
            path.addLine(to: CGPoint(x: rect.minX + 25, y: rect.maxY))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - 25),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 25))
            
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + 25, y: rect.minY),
                control: .zero
            )
            
        }
    }
    
    
}
