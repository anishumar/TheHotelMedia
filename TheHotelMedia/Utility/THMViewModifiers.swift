//
//  THMViewModifiers.swift
//  TheHotelMedia
//
//  Created by MAC on 13/11/24.
//


import SwiftUI


struct ComicFontViewModifier: ViewModifier {
    
    var size: CGFloat
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .font(.custom(Constants.comicFont, size: size))
            .foregroundColor(color)
    }
}

extension View {
    
    func withComicFont(_ size: CGFloat, color: Color) -> some View {
        self
            .modifier(ComicFontViewModifier(size: size, color: color))
    }
}
