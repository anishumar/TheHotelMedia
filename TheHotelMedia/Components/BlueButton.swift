//
//  BlueButton.swift
//  TheHotelMedia
//
//  Created by MAC on 16/01/25.
//

import SwiftUI

struct BlueButton: View {
    
    var title: String
    var icon: String
    var onPressed: (() -> Void)?
    
    var body: some View {
        Button(action: {
            haptics(.light)
            onPressed?()
        }, label: {
            VStack {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
//                    .overlay {
//                        ZStack {
//                            Circle()
//                                .stroke(lineWidth: 1)
//                                .fill(.black.opacity(0.1))
//                            Circle()
//                                .stroke(lineWidth: 1)
//                                .fill(.black.opacity(0.05))
//                            Circle()
//                                .stroke(lineWidth: 2)
//                                .fill(.black.opacity(0.05))
//                            Circle()
//                                .stroke(lineWidth: 3)
//                                .fill(.black.opacity(0.05))
//                            Circle()
//                                .stroke(lineWidth: 4)
//                                .fill(.black.opacity(0.05))
//                            Circle()
//                                .stroke(lineWidth: 5)
//                                .fill(.black.opacity(0.05))
//                            Circle()
//                                .stroke(lineWidth: 6)
//                                .fill(.black.opacity(0.05))
//                            Circle()
//                                .stroke(lineWidth: 7)
//                                .fill(.black.opacity(0.05))
//                            Circle()
//                                .stroke(lineWidth: 8)
//                                .fill(.black.opacity(0.05))
//                            Circle()
//                                .stroke(lineWidth: 9)
//                                .fill(.black.opacity(0.04))
//                            Circle()
//                                .stroke(lineWidth: 10)
//                                .fill(.black.opacity(0.03))
//                            Circle()
//                                .stroke(lineWidth: 11)
//                                .fill(.black.opacity(0.02))
//                            Circle()
//                                .stroke(lineWidth: 12)
//                                .fill(.black.opacity(0.01))
//                        }
//                        .frame(width: 52, height: 52)
//                        .clipShape(Circle())
//                    }
                Text(title)
            }
        })
    }
}

#Preview {
    BlueButton(title: "", icon: "")
}
