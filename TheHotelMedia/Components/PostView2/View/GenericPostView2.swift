//
//  GenericPostView2.swift
//  TheHotelMedia
//
//  Created by MAC on 06/05/25.
//

import SwiftUI
import SDWebImageSwiftUI


struct GenericPostView2: View {
    
    let post: PostData
    let index: Int
    @State var imageUrl: String = ""
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 14)
                .frame(maxWidth: .infinity)
                .frame(height: index % 2 == 0 ? 300 : 200)
                .overlay {
                    WebImage(url: URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 12)
            
            RoundedRectangle(cornerRadius: 14)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 12)
            
            RoundedRectangle(cornerRadius: 14)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 12)
        }
//        .frame(height: 500)
        .onAppear {
            if let mediaRef = post.mediaRef, mediaRef.isNotEmpty {
                imageUrl = mediaRef[0].thumbnailURL ?? ""
            } else if let coverImage = post.reviewedBusinessProfileRef?.coverImage {
                imageUrl = coverImage
            }
        }
    }
}
