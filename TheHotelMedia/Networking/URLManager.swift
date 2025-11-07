//
//  URLManager.swift
//  TheHotelMedia
//
//  Created by MAC on 19/09/24.
//

import Foundation

// Base URLs
extension URL {
    
    static var baseURL: URL {
#if DEBUG
        URL(string: "https://staging.thehotelmedia.com")!
//        URL(string: "https://api.thehotelmedia.com")!

#else
        URL(string: "https://api.thehotelmedia.com")!
//        URL(string: "http://ec2-43-205-43-21.ap-south-1.compute.amazonaws.com")!

#endif
    }
    
    
    static var development: String {
        "https://staging.thehotelmedia.com/api/v1"
//        "https://api.thehotelmedia.com/api/v1"
    }
    
    
    static var production: String {
//        "http://ec2-43-205-43-21.ap-south-1.compute.amazonaws.com/api/v1"
        "https://api.thehotelmedia.com/api/v1"
    }
    
    
    static var `default`: String {
        #if DEBUG
        return development
        
        #else
        return production
        
        #endif
    }
}


// RefreshToken URL
extension URL {
    static var refreshToken: URL {
        URL(string: "\(URL.default)/auth/refresh-token")!
    }
}


// Authrization URLs
extension URL {
    
    static var signup: URL {
        URL(string: "\(URL.default)/auth/signup")!
    }
    
    
    static var signin: URL {
        URL(string: "\(URL.default)/auth/login")!
    }
    
    
    static var emailVerify: URL {
        URL(string: "\(URL.default)/auth/email-verify")!
    }
    
    static var profilePic: URL {
        URL(string: "\(URL.default)/user/edit-profile-pic")!
    }
    
    static var editProfile: URL {
        URL(string: "\(URL.default)/user/edit-profile")!
    }
    
    static var getBusinessTypes: URL {
        URL(string: "\(URL.default)/business/types")!
    }
    
    static var getBusinessSubTypes: URL {
        URL(string: "\(URL.default)/business/subtypes")!
    }
    
    static var businessQuestions: URL {
        URL(string: "\(URL.default)/business/questions")!
    }
    
    static var businessAnswers: URL {
        URL(string: "\(URL.default)/business/questions/answers")!
    }
    
    static var resendOTP: URL {
        URL(string: "\(URL.default)/auth/resend-otp")!
    }
    
    static var businessDocuments: URL {
        URL(string: "\(URL.default)/user/business-profile/documents")!
    }
    
    static var getPlans: URL {
        URL(string: "\(URL.default)/user/subscription/plans")!
    }
    
    static var checkout: URL {
        URL(string: "\(URL.default)/user/subscription/checkout")!
    }
    
    static var buySubscription: URL {
        URL(string: "\(URL.default)/user/subscription")!
    }
    
    static var forgotPassword: URL {
        URL(string: "\(URL.default)/auth/forgot-password")!
    }
    
    static var forgotPasswordOtpVerify: URL {
        URL(string: "\(URL.default)/auth/forgot-password/verify-otp")!
    }
    
    static var changePassword: URL {
        URL(string: "\(URL.default)/auth/reset-password")!
    }
    
    static var getProfile: URL {
        URL(string: "\(URL.default)/user/profile")!
    }
    
    static var editProfilePic: URL {
        URL(string: "\(URL.default)/user/edit-profile-pic")!
    }
    
    static var getPlaces: URL {
        URL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")!
    }
    
    static var getBusinessProfile: URL {
        URL(string: "\(URL.default)/business/get-by-place/")!
    }
    
    static var createPost: URL {
        URL(string: "\(URL.default)/posts")!
    }
    
    static var createReview: URL {
        URL(string: "\(URL.default)/reviews")!
    }
    
    
    static var getHome: URL {
        URL(string: "\(URL.default)/feed")!
    }
    
    static var createEvent: URL {
        URL(string: "\(URL.default)/events")!
    }
    
    static var likeAPost: URL {
        URL(string: "\(URL.default)/posts/likes/")!
    }
    
    static var saveAPost: URL {
        URL(string: "\(URL.default)/posts/saved-posts/")!
    }
    
    static var getComments: URL {
        URL(string: "\(URL.default)/posts/comments/")!
    }
    
    static var postComment: URL {
        URL(string: "\(URL.default)/posts/comments")!
    }
    
    static var likeAComment: URL {
        URL(string: "\(URL.default)/posts/comments/likes/")!
    }
    
    static var deleteComment: URL {
        URL(string: "\(URL.default)/posts/comments/")!
    }
    
    static var uploadPropertyImages: URL {
        URL(string: "\(URL.default)/user/business-profile/property-picture")!
    }
    
    static var getUserPosts: URL {
        URL(string: "\(URL.default)/user/posts/")!
    }
    
    static var getUserImages: URL {
        URL(string: "\(URL.default)/user/images/")!
    }
    
    static var getUserVideos: URL {
        URL(string: "\(URL.default)/user/videos/")!
    }
    
    static var getTagPeople: URL {
        URL(string: "\(URL.default)/user/tag-people")!
    }
    
    static var getBusinessReviews: URL {
        URL(string: "\(URL.default)/user/reviews/")!
    }
    
    static var savedPosts: URL {
        URL(string: "\(URL.default)/posts/saved-posts")!
    }
    
    static var search: URL {
        URL(string: "\(URL.default)/search")!
    }
    
    static var getTransactions: URL {
        URL(string: "\(URL.default)/transactions")!
    }
    
    static var getFollowers: URL {
        URL(string: "\(URL.default)/user/follower/")!
    }
    
    static var getFollowing: URL {
        URL(string: "\(URL.default)/user/following/")!
    }
    
    static var getNotifications: URL {
        URL(string: "\(URL.default)/notifications")!
    }
    
    static var follow: URL {
        URL(string: "\(URL.default)/user/follow/")!
    }
    
    static var unfollow: URL {
        URL(string: "\(URL.default)/user/unfollow/")!
    }
    
    static var acceptFollowRequest: URL {
        URL(string: "\(URL.default)/user/accept-follow/")!
    }
    
    static var rejectFollowRequest: URL {
        URL(string: "\(URL.default)/user/reject-follow/")!
    }
    
    static var followback: URL {
        URL(string: "\(URL.default)/user/follow-back/")!
    }
    
    static var getFaqs: URL {
        URL(string: "\(URL.default)/faqs")!
    }
    
    static var disableAccount: URL {
        URL(string: "\(URL.default)/user/account/disable")!
    }
    
    static var deleteAccount: URL {
        URL(string: "\(URL.default)/user/account")!
    }
    
    static var logout: URL {
        URL(string: "\(URL.default)/auth/logout")!
    }
    
    static var contactUs: URL {
        URL(string: "\(URL.default)/contact-us")!
    }
    
    static var blockUser: URL {
        URL(string: "\(URL.default)/user/blocks/")!
    }
    
    static var getSinglePost: URL {
        URL(string: "\(URL.default)/posts/")!
    }
    
    static var joinEvent: URL {
        URL(string: "\(URL.default)/events/join")!
    }
    
    static var getBlockedUsers: URL {
        URL(string: "\(URL.default)/user/blocks")!
    }
    
    static var createStory: URL {
        URL(string: "\(URL.default)/story")!
    }
    
    static var getStories: URL {
        URL(string: "\(URL.default)/story")!
    }
    
    static var deleteStory: URL {
        URL(string: "\(URL.default)/story/")!
    }
    
    static var viewedStory: URL {
        URL(string: "\(URL.default)/story/views/")!
    }
    
    static var likeStory: URL {
        URL(string: "\(URL.default)/story/likes/")!
    }
    
    static var getStoryViews: URL {
        URL(string: "\(URL.default)/story/views/")!
    }
    
    static var getStoryLikes: URL {
        URL(string: "\(URL.default)/story/likes/")!
    }
    
    static var getActiveSubscription: URL {
        URL(string: "\(URL.default)/user/subscription")!
    }
    
    static var cancelSubscription: URL {
        URL(string: "\(URL.default)/user/subscription")!
    }
    
    static var getInsight: URL {
        URL(string: "\(URL.default)/business/insights")!
    }
    
    static var uploadBillingAddress: URL {
        URL(string: "\(URL.default)/user/address")!
    }
    
    static var collectData: URL {
        URL(string: "\(URL.default)/business/insights")!
    }
    
    static var reportPost: URL {
        URL(string: "\(URL.default)/posts/reports/")!
    }
    
    static var sendMessageMedia: URL {
        URL(string: "\(URL.default)/user/messaging/media-message")!
    }
    
    static var profileShared: URL {
        URL(string: "\(URL.default)/share/users")!
    }
    
    static var reportUser: URL {
        URL(string: "\(URL.default)/user/report/")!
    }
    
    static var postShared: URL {
        URL(string: "\(URL.default)/share/posts")!
    }
    
    static var getBusinessDocuments: URL {
        URL(string: "\(URL.default)/user/business-profile/documents")!
    }
    
    static var socialLogin: URL {
        URL(string: "\(URL.default)/auth/social/login")!
    }
    
    static var getProfessions: URL {
        URL(string: "\(URL.default)/professions")!
    }
    
    static var deletePost: URL {
        URL(string: "\(URL.default)/posts/")!
    }
    
    static var notificationStatus: URL {
        URL(string: "\(URL.default)/notifications/status")!
    }
    
    static var deleteChat: URL {
        URL(string: "\(URL.default)/user/messaging/chat/")!
    }
    
    static var exportChat: URL {
        URL(string: "\(URL.default)/user/messaging/export-chat/")!
    }
    
    static var reportComment: URL {
        URL(string: "\(URL.default)/posts/comments/reports/")!
    }
    
    static var viewMedia: URL {
        URL(string: "\(URL.default)/posts/media/views")!
    }
    
    static var getSuggestions: URL {
        URL(string: "\(URL.default)/suggestions")!
    }
    
    static var increasePostViews: URL {
        URL(string: "\(URL.default)/posts/views")!
    }
    
    static var getSubscriptionMeta: URL {
        URL(string: "\(URL.default)/user/subscription/meta")!
    }
    
    static var verifyIAPTransaction: URL {
        URL(string: "\(URL.default)/apple/purchases/subscriptions/verify")!
    }
    
    static var allRooms: URL {
        URL(string: "\(URL.default)/rooms")!
    }
    
    static var bookingCheckIn: URL {
        URL(string: "\(URL.default)/bookings/check-in")!
    }
    
    static var fetchRoomData: URL {
        URL(string: "\(URL.default)/rooms/")!
    }
    
    static var bookingCheckOut: URL {
        URL(string: "\(URL.default)/bookings/checkout")!
    }
    
    static var confirmBooking: URL {
        URL(string: "\(URL.default)/bookings/checkout/confirm")!
    }
    
    static var bookingHistory: URL {
        URL(string: "\(URL.default)/bookings")!
    }
    
    static var bookingSummary: URL {
        URL(string: "\(URL.default)/bookings/")!
    }
    
    static var bookingInvoice: URL {
        URL(string: "\(URL.default)/bookings/")!
    }
    
    static var cancelBooking: URL {
        URL(string: "\(URL.default)/bookings/")!
    }
    
    static var bookingAction: URL {
        URL(string: "\(URL.default)/bookings/")!
    }
    
    static var requestMobileNoVerifyOTP: URL {
        URL(string: "\(URL.default)/auth/mobile/request-otp")!
    }

    static var verifyMobileNoOTP: URL {
        URL(string: "\(URL.default)/auth/mobile/verify-otp")!
    }
    
    static var bookTable: URL {
        URL(string: "\(URL.default)/bookings/table")!
    }
    
    static var bookBanquet: URL {
        URL(string: "\(URL.default)/bookings/banquet")!
    }
    
    static var createJobPost: URL {
        URL(string: "\(URL.default)/jobs")!
    }
    
    static var getJobDetail: URL {
        URL(string: "\(URL.default)/jobs/")!
    }
}
