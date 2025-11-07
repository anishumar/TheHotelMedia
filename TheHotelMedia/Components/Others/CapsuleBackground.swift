//
//  CapsuleBackground.swift
//  HotelMedia
//
//  Created by MAC on 01/08/24.
//

import SwiftUI

struct CapsuleBackground: View {
    
    var height: CGFloat = 46
    var borderWidth: CGFloat = 1
    var borderColor: Color = .hmDarkerGray
    var backgroundColor: Color = .hmDarkestGray.opacity(0.5)
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(backgroundColor)
            Capsule()
                .stroke(lineWidth: borderWidth)
                .fill(borderColor)
        }
        .frame(height: height)
    }
}

#Preview {
    CapsuleBackground()
}
