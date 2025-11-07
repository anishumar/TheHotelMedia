//
//  GIFView.swift
//  TheHotelMedia
//
//  Created by MAC on 08/01/25.
//

import SwiftUI
import UIKit

struct GIFView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.loadGif(named: gifName)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

extension UIImageView {
    func loadGif(named: String) {
        guard let path = Bundle.main.path(forResource: named, ofType: "gif"),
              let data = NSData(contentsOfFile: path),
              let source = CGImageSourceCreateWithData(data, nil) else { return }

        var images = [UIImage]()
        let count = CGImageSourceGetCount(source)
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
            }
        }
        self.animationImages = images
        self.animationDuration = Double(images.count) / 24.0
        self.startAnimating()
    }
}

