//
//  CustomRadiusRectangle.swift
//  TheHotelMedia
//
//  Created by MAC on 14/02/25.
//

import SwiftUI


struct CustomRadiusRectangle: Shape {
    
    let topLeadingRadius: CGFloat
    let topTrailingRadius: CGFloat
    let bottomTrailingRadius: CGFloat
    let bottomLeadingRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + topLeadingRadius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - topTrailingRadius, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + topTrailingRadius), control: CGPoint(x: rect.maxX, y: rect.minY))
            
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomTrailingRadius))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - bottomTrailingRadius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
            
            path.addLine(to: CGPoint(x: rect.minX + bottomLeadingRadius, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - bottomLeadingRadius), control: CGPoint(x: rect.minX, y: rect.maxY))
            
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeadingRadius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + topLeadingRadius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        }
    }
}
