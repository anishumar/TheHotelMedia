//
//  View + Ext.swift
//  HotelMedia
//
//  Created by MAC on 06/08/24.
//

import SwiftUI

extension View {
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}


extension View {
    func keyboardAdaptive() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAdaptive())
    }
}


extension View {
    
    func modifyOrientation(_ mask: UIInterfaceOrientationMask) {
        if let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene) {
            AppDelegate.orientationLock = mask
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
            
            windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
    
    
    func updateBookingStatusColor(status: String) -> Color {
        let color: Color
        
        switch status {
        case "created":
            color = .purple
        case "pending":
            color = .yellow
        case "confirmed":
            color = .green
        case "checked in":
            color = .blue
        case "completed":
            color = .green
        case "canceled", "canceled by business", "canceled by user":
            color = .hmRed
        case "no show":
            color = .gray
        default:
            color = .hmLightGray
        }
        
        return color
    }
}


