//
//  UIImage + Ext.swift
//  TheHotelMedia
//
//  Created by MAC on 23/09/24.
//

import UIKit


extension UIImage {
    func convertedToColorDepth(_ colorDepth: Int) -> UIImage? {
        guard let cgImage else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)

        guard let context = CGContext(data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: colorDepth, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }

        let rect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        context.draw(cgImage, in: rect)

        guard let newCGImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: newCGImage)
    }
}
