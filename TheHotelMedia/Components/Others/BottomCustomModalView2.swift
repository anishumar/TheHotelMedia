//
//  BottomCustomModalView2.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import SwiftUI

struct BottomCustomModalView2: View {
    
    var topButtonTitle: String
    var bottomButtonTitle: String
    var onTopButtonPressed: (() -> Void)?
    var onBottomButtonPressed: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            VStack {
                Button(action: {
                    onTopButtonPressed?()
                }, label: {
                    ZStack {
                        CapsuleBackground()
                        Text(topButtonTitle)
                            .font(.custom(Constants.comicFont, size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                })
                
                Button(action: {
                    onBottomButtonPressed?()
                }, label: {
                    ZStack {
                        CapsuleBackground()
                        Text(bottomButtonTitle)
                            .font(.custom(Constants.comicFont, size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                })
            }
        }
        .padding(.bottom, 16)
        .padding(.top, 26)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 130)
        .background(
            CustomShape2()
                .fill(.hmDarkestGray)
                .overlay(
                    Image("SheetIndicator")
                        .offset(y: -3)
                    , alignment: .top
                )
        )
    }
}

#Preview {
    VStack {
        BottomCustomModalView2(topButtonTitle: "Block", bottomButtonTitle: "View Profile")
    }
    .frame(maxHeight: .infinity)
    .background(.black)
    
}
