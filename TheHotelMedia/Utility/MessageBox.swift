//
//  MessageBox.swift
//  TheHotelMedia
//
//  Created by MAC on 25/11/24.
//

import SwiftUI


struct MessageBox: Shape {
    
    let normalRadius: CGFloat
    let smallRadius: CGFloat
    let isMyMessage: Bool
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + normalRadius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - normalRadius, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + normalRadius), control: CGPoint(x: rect.maxX, y: rect.minY))
            
            if isMyMessage {
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - smallRadius))
                path.addQuadCurve(to: CGPoint(x: rect.maxX - smallRadius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
                
            } else {
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - normalRadius))
                path.addQuadCurve(to: CGPoint(x: rect.maxX - normalRadius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
            }
            
            if isMyMessage {
                path.addLine(to: CGPoint(x: rect.minX + normalRadius, y: rect.maxY))
                path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - normalRadius), control: CGPoint(x: rect.minX, y: rect.maxY))
            } else {
                path.addLine(to: CGPoint(x: rect.minX + smallRadius, y: rect.maxY))
                path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - smallRadius), control: CGPoint(x: rect.minX, y: rect.maxY))
            }
            
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + normalRadius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + normalRadius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        }
    }
}


