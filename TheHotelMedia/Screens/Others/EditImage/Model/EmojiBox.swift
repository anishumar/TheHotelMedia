//
//  EmojiBox.swift
//  HotelMedia
//
//  Created by MAC on 10/09/24.
//

import SwiftUI


struct EmojiBox: Identifiable {
    var id = UUID().uuidString
    var emoji: Emoji
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    var fontSize: CGFloat = 60  // Initial font size
    var lastFontSize: CGFloat = 60  // Keep track of the last font size
    var angle: Angle = Angle(degrees: 0)
    var lastAngle: Angle = Angle(degrees: 0)
}

