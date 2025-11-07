//
//  Publishers + Ext.swift
//  HotelMedia
//
//  Created by MAC on 07/08/24.
//

import UIKit
import Combine


extension Publishers {
    // 1.
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        // 2.
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        // 3.
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}


//extension Publishers {
//    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
//        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
//            .map { notification -> CGFloat in
//                guard let userInfo = notification.userInfo,
//                      let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
//                    return 0
//                }
//                return keyboardFrame.height
//            }
//            .eraseToAnyPublisher()
//    }
//}
