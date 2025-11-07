//
//  BottomModalManager.swift
//  TheHotelMedia
//
//  Created by MAC on 11/11/24.
//

import SwiftfulRouting
import SwiftUI


class BottomModalManager {
    
    static func horizontalStyleModal(router: AnyRouter, title: String, rightButtonTitle: String, leftButtonTitle: String, onLeftButtonPressed: @escaping (() -> Void), onRightButtonPressed: @escaping (() -> Void), onDismiss: @escaping (() -> Void)) {
        router.showModal(transition: .move(edge: .bottom)) {
            BottomCustomModalView3(
                title: title,
                rightButtonTitle: rightButtonTitle,
                leftButtonTitle: leftButtonTitle) {
                    onLeftButtonPressed()
                    router.dismissModal()
                    
                } onRightButtonPressed: {
                    onRightButtonPressed()
                    router.dismissModal()
                    
                } onDismiss: {
                    router.dismissModal()
                    onDismiss()
                }
        }
    }
    
    
    static func verticalStyleModal(router: AnyRouter, topButtonTitle: String, bottomButtonTitle: String, onTopButtonPressed: @escaping (() -> Void), onBottomButtonPressed: @escaping (() -> Void), onDismiss: @escaping (() -> Void)) {
        router.showModal(transition: .move(edge: .bottom)) {
            BottomCustomModalView4(
                topButtonTitle: topButtonTitle,
                bottomButtonTitle: bottomButtonTitle) {
                    onTopButtonPressed()
                    router.dismissModal()
                    
                } onBottomButtonPressed: {
                    onBottomButtonPressed()
                    router.dismissModal()
                    
                } onDismiss: {
                    router.dismissModal()
                    onDismiss()
                }

        }
    }
}
