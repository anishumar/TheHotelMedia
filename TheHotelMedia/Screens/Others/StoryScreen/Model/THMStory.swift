//
//  StoryModel.swift
//  TheHotelMedia
//
//  Created by MAC on 05/11/24.
//

import Foundation


struct THMStory: Identifiable, Hashable {
    public var id: String
    public var mediaID: String
    public var mediaURL: String
    public var date: String
    public var isReady: Bool = false
    public var isLiked: Bool = false
    public var isViewed: Bool = false
    public var likesRef: [StoryLikeRef]? = nil
    public var viewsRef: [StoryLikeRef]? = nil
    public var duration: Double = Constants.storySecond
    public var config: THMStoryConfiguration
    
    public init(id: String = UUID().uuidString,
                mediaID: String,
                mediaURL: String,
                date: String,
                isLiked: Bool = false,
                isViewed: Bool = false,
                likesRef: [StoryLikeRef]? = nil,
                viewsRef: [StoryLikeRef]? = nil,
                duration: Double = 5,
                config: THMStoryConfiguration) {
        
        self.id = id
        self.mediaID = mediaID
        self.mediaURL = mediaURL
        self.date = date
        self.duration = duration
        self.config = config
        self.isLiked = isLiked
        self.isViewed = isViewed
        self.likesRef = likesRef
        self.viewsRef = viewsRef
        Constants.storySecond = duration
    }
}
