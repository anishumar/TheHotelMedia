//
//  BusinessProfilePicView.swift
//  TheHotelMedia
//
//  Created by MAC on 20/12/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct BusinessProfilePicView: View {
    
    var stringURL: String
    var dimension: CGFloat = 46
    var border: CGFloat = 3
    var blackCircleDimension: CGFloat {
        dimension - border
    }
    var imageCircleDimension: CGFloat {
        dimension - (border * 2)
    }
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Circle()
            .fill(.hmPeach)
            .frame(width: dimension, height: dimension)
            .overlay(
                Circle()
                    .fill(themeManager.currentTheme.backgroundColor)
                    .frame(width: blackCircleDimension)
            )
            .overlay(
                WebImage(url: URL(string: stringURL), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: imageCircleDimension, height: imageCircleDimension)
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: imageCircleDimension, height: imageCircleDimension)
                })
            )
    }
}

#Preview {
    BusinessProfilePicView(stringURL: "")
}
