//
//  iPhoneModel.swift
//  HotelMedia
//
//  Created by MAC on 29/07/24.
//

import Foundation
import SwiftUI

enum iPhoneModel {
    case iPhoneSE
    case iPhone8
    case iPhone8Plus
    case iPhoneX
    case iPhoneXR
    case iPhoneXSMax
    case iPhone11Pro
    case iPhone11ProMax
    case iPhone12Mini
    case iPhone12
    case iPhone12ProMax
    case unknown
}


func getiPhoneModel() -> iPhoneModel {
    let screenSize = UIScreen.main.bounds.size
    let height = screenSize.height
    let width = screenSize.width

    if width == 320 && height == 568 {
        return .iPhoneSE
    } else if width == 375 && height == 667 {
        return .iPhone8
    } else if width == 414 && height == 736 {
        return .iPhone8Plus
    } else if width == 375 && height == 812 {
        return .iPhoneX
    } else if width == 414 && height == 896 {
        return .iPhoneXR
    } else if width == 414 && height == 896 {
        return .iPhoneXSMax
    } else if width == 375 && height == 812 {
        return .iPhone11Pro
    } else if width == 414 && height == 896 {
        return .iPhone11ProMax
    } else if width == 360 && height == 780 {
        return .iPhone12Mini
    } else if width == 390 && height == 844 {
        return .iPhone12
    } else if width == 428 && height == 926 {
        return .iPhone12ProMax
    } else {
        return .unknown
    }
}

