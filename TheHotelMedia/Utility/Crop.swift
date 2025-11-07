//
//  Crop.swift
//  HotelMedia
//
//  Created by MAC on 03/09/24.
//

import SwiftUI


enum Crop: Equatable {
    case circle
    case portrait
    case landscape
    case square
    case custom(CGSize)
    
    func name() -> String {
        switch self {
        case .circle:
            return "Circle"
        case .square:
            return "Square"
        case .portrait:
            return "Portrait"
        case .landscape:
            return "Landscape"
        case .custom(let cGSize):
            return "Custom\(Int(cGSize.width))X\(Int(cGSize.height))"
        }
    }
    
    func size() -> CGSize {
        let width = UIScreen.main.bounds.width - 100
        let ratioFour = width / 4
        let ratioThree = width / 3
        switch self {
        case .circle:
            return .init(width: width, height: width)
        case .square:
            return .init(width: width, height: width)
        case .portrait:
            return .init(width: width, height: ratioThree * 4)
        case .landscape:
            return .init(width: width, height: ratioFour * 3)
        case .custom(let cGSize):
            return cGSize
        }
    }
}
