//
//  IndividualProfilePicView.swift
//  TheHotelMedia
//
//  Created by MAC on 20/12/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct IndividualProfilePicView: View {
    
    var urlString: String
    var dimension: CGFloat = 46
    
    var body: some View {
        
        Circle()
            .fill(.black)
            .frame(width: dimension, height: dimension)
            .overlay(
                WebImage(url: URL(string: urlString), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                }, placeholder: {
                    Image("NoProfilePic")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                })
            )
    }
}

#Preview {
    IndividualProfilePicView(urlString: "")
}
