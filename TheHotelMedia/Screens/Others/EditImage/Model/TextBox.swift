//
//  TextBox.swift
//  HotelMedia
//
//  Created by MAC on 10/09/24.
//

import SwiftUI
import PencilKit


struct TextBox: Identifiable {
    var id = UUID().uuidString
    var text: String = ""
    var isBold: Bool = false
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    var textColor: Color = ThemeManager.shared.currentTheme.label
    var backgroundColor: Color = .black
    var scale: CGFloat = 1
    var lastScale: CGFloat = 1
    var angle: Angle = Angle(degrees: 0)
    var lastAngle: Angle = Angle(degrees: 0)
    
    // New properties for font size
    var fontSize: CGFloat = 20
    var lastFontSize: CGFloat = 20
}

