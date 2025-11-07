//
//  Constants.swift
//  HotelMedia
//
//  Created by MAC on 29/07/24.
//

import SwiftfulRouting
import SwiftUI

class Constants {
    
//    static let comicFont = "Comic Sans MS"
//    static let comicBold = "ComicSansMS-Bold"
    static let comicFont = "Roboto-Regular"
    static let comicBold = "Roboto-Bold"
    static let rubikLight = "Rubik-Light"
    static let fascinateFont = "Fascinate-Regular"
    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
    static let scale = UIScreen.main.scale
    static let domainURL = "thehotelmedia.com"
    
    static let progressBarHeight: CGFloat = 3
    static var storySecond: Double = 5.0
    static let progressBarSpacing: CGFloat = 5
    
    static var domainName: String {
#if DEBUG
//        return "ec2-43-205-43-21.ap-south-1.compute.amazonaws.com"
        return "thehotelmedia.com"
#else
        return "thehotelmedia.com"
#endif
    }
    
    static var razorpayKey: String {
#if DEBUG
        return "rzp_test_IXF6sTTP8dPZXN"
//        return "rzp_live_oItyf902ER4IXW"
#else
        return "rzp_live_oItyf902ER4IXW"
//        return "rzp_test_IXF6sTTP8dPZXN"
#endif
    }
    
    static var baseShareUrl: String {
#if DEBUG
//        return "https://ec2-43-205-43-21.ap-south-1.compute.amazonaws.com"
        return "https://thehotelmedia.com"
#else
        return "https://thehotelmedia.com"
#endif
    }
    
    enum UserView {
        static let hStackSpace: CGFloat = 13
        static let textSize: CGFloat = 16
        static let closeImage: String = "xmark"
    }
    
    enum MessageView {
        static let height: CGFloat = 48
        static let padding = EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        static let cornerRadius: CGFloat = 24
        static let likeImage: String = "heart"
        static let likeImageTapped: String = "heart.fill"
        static let shareImage: String = "paperplane"
    }
    
    
    static func getReportSheetHeight() -> CGFloat {
        if screenHeight < 750 {
            return 0.9
        } else if screenHeight < 850 {
            return 0.8
        } else {
            return 0.7
        }
    }
    
    
    static let individualPlan = SubscriptionPlan(
        id: "671f3d67246e34183d59ee44",
        features: [
            "Upload unlimited photos",
            "Unlimited video upload (05 min video)",
            "Unlimited posts",
            "Can follow anyone",
            "Unlimited followers",
            "* Rs 99+ gst after 10k followers"
        ],
        businessSubtypeID: [],
        businessTypeID: [],
        name: "Premium",
        description: "The Premium Plan is aimed at users who want an enhanced experience with additional features and no advertisements. This plan is ideal for frequent travelers and those who want to make the most of the app's capabilities.",
        appleSubscriptionID: "",
        price: 199,
        duration: "monthly",
        image: "https://thehotelmedia.com/public/files/premium-subscription-plan.png",
        type: "individual",
        level: "premium",
        currency: "INR",
        createdAt: "2024-10-28T07:29:43.963Z",
        updatedAt: "2025-01-24T10:38:45.708Z"
    )
    
    
    static func printNamesOfFont() {
        for family in UIFont.familyNames {
            for fontName in UIFont.fontNames(forFamilyName: family) {
                print(fontName)
            }
        }
    }
    
    static func getRandomColor() -> Color {
        let red = Double.random(in: 0...1)
        let green = Double.random(in: 0...1)
        let blue = Double.random(in: 0...1)
        return Color(red: red, green: green, blue: blue)
    }
}
