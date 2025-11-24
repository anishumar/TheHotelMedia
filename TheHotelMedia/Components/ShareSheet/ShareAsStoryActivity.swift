//
//  ShareAsStoryActivity.swift
//  TheHotelMedia
//
//  Created by MAC on 24/11/25.
//

import UIKit

class ShareAsStoryActivity: UIActivity {
    
    var onShareAsStory: (() -> Void)?
    
    override var activityTitle: String? {
        let language = LocalizationManager.shared.language
        return "share_as_story".localized(language)
    }
    
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType("com.thehotelmedia.shareAsStory")
    }
    
    override var activityImage: UIImage? {
        if let image = UIImage(named: "CreateStory") {
            return image
        }
        return UIImage(systemName: "photo.on.rectangle")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        // No preparation needed
    }
    
    override func perform() {
        onShareAsStory?()
        activityDidFinish(true)
    }
}

