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
    public var mentions: [String]? = nil
    public var duration: Double = Constants.storySecond
    public var config: THMStoryConfiguration
    
    // New tagging fields
    public var location: Location? = nil
    public var locationPositionX: Double? = nil
    public var locationPositionY: Double? = nil
    public var userTagged: String? = nil
    public var userTaggedId: String? = nil
    public var userTaggedPositionX: Double? = nil
    public var userTaggedPositionY: Double? = nil
    
    public init(id: String = UUID().uuidString,
                mediaID: String,
                mediaURL: String,
                date: String,
                isLiked: Bool = false,
                isViewed: Bool = false,
                likesRef: [StoryLikeRef]? = nil,
                viewsRef: [StoryLikeRef]? = nil,
                mentions: [String]? = nil,
                duration: Double = 5,
                config: THMStoryConfiguration,
                location: Location? = nil,
                locationPositionX: Double? = nil,
                locationPositionY: Double? = nil,
                userTagged: String? = nil,
                userTaggedId: String? = nil,
                userTaggedPositionX: Double? = nil,
                userTaggedPositionY: Double? = nil) {
        
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
        self.mentions = mentions
        self.location = location
        self.locationPositionX = locationPositionX
        self.locationPositionY = locationPositionY
        self.userTagged = userTagged
        self.userTaggedId = userTaggedId
        self.userTaggedPositionX = userTaggedPositionX
        self.userTaggedPositionY = userTaggedPositionY
        Constants.storySecond = duration
    }
}
