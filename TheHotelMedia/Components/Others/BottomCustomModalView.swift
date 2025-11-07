//
//  BottomCustomModalView.swift
//  HotelMedia
//
//  Created by MAC on 29/08/24.
//

import SwiftUI

struct BottomCustomModalView: View {
    
    var title: String
    var leftButtonTitle: String
    var rightButtonTitle: String
    var onLeftButtonPressed: (() -> Void)?
    var onRightButtonPressed: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.custom(Constants.comicFont, size: 14))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Rectangle()
                .fill(.hmDarkerGray)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
            
            HStack {
                Button(action: {
                    onLeftButtonPressed?()
                }, label: {
                    ZStack {
                        CapsuleBackground()
                        Text(leftButtonTitle)
                            .font(.custom(Constants.comicFont, size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                })
                
                Button(action: {
                    onRightButtonPressed?()
                }, label: {
                    ZStack {
                        CapsuleBackground()
                        Text(rightButtonTitle)
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
        BottomCustomModalView(
            title: "Do you really want to Log out your account ?",
            leftButtonTitle: "Yes",
            rightButtonTitle: "No"
        )
    }
    .frame(maxHeight: .infinity)
    .background(.black)
    
}
