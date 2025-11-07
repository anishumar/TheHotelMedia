//
//  Double + Ext.swift
//  TheHotelMedia
//
//  Created by MAC on 13/02/25.
//

import SwiftUI


extension Double {
    
    func getStarColor() -> Color {
        if self == 5 {
            return .hmBrightGreen
        } else if self >= 4 && self < 5 {
            return .hmDarkGreen2
        } else if self >= 3 && self < 4 {
            return .yellow
        } else if self >= 2 && self < 3 {
            return .orange
        } else {
            return .red
        }
    }
    
}
