//
//  ShareToChatActivity.swift
//  TheHotelMedia
//
//  Created by MAC on 26/11/25.
//

import UIKit

class ShareToChatActivity: UIActivity {
    var shareToChatAction: (() -> Void)?
    
    override var activityTitle: String? {
        return "Share to Chat"
    }
    
    override var activityImage: UIImage? {
        if #available(iOS 13.0, *) {
            return UIImage(systemName: "message.fill")
        } else {
            return UIImage(named: "message")
        }
    }
    
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType("com.thehotelmedia.shareToChat")
    }
    
    override class var activityCategory: UIActivity.Category {
        return .action
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        // No preparation needed
    }
    
    override func perform() {
        shareToChatAction?()
        activityDidFinish(true)
    }
}

