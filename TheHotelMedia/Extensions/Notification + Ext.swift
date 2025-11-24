//
//  Notification + Ext.swift
//  HotelMedia
//
//  Created by MAC on 07/08/24.
//

import UIKit

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}

extension Notification.Name {
    static let readmore = Notification.Name("readmore")
    static let tags = Notification.Name("tags")
    static let shareAsStory = Notification.Name("shareAsStory")
}

