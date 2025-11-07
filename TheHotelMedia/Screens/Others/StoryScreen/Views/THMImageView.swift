//
//  THMImageView.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import SwiftUI
import AVKit

struct THMImageView: UIViewRepresentable {
    
    var imageURL: String?
    let imageIsLoaded: () -> Void
   
    func makeUIView(context: UIViewRepresentableContext<THMImageView>) -> THMImageLoader {
        return THMImageLoader()
    }
    
    func updateUIView(_ uiView: THMImageLoader, context: Context) {
        uiView.loadImageWithUrl(imageURL, imageIsLoaded: imageIsLoaded)
    }
}

