//
//  GetInsightResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 19/11/24.
//

import Foundation

// MARK: - Welcome
struct GetInsightResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: InsightData?
}

// MARK: - WelcomeData
struct InsightData: Codable {
    let dashboard: Dashboard?
    let data: ChartData?
    let stories: [MyStory]?
    let posts: [PostData]?
}

// MARK: - Dashboard
struct Dashboard: Codable {
    let accountReached, websiteRedirection, totalFollowers, engaged: Int?
}

// MARK: - ChartData
struct ChartData: Codable, Equatable {
    let accountReached: [AccountReached]?
    let websiteRedirection: [WebsiteRedirection]?
    let totalFollowers: [TotalFollower]?
//    let engaged: [Any?]?
}

// MARK: - AccountReached
struct AccountReached: Codable, Equatable {
    let accountReach: Int?
    let labelName: String?
}

// MARK: - TotalFollower
struct TotalFollower: Codable, Equatable {
    let followers: Int?
    let labelName: String?
}

// MARK: - WebsiteRedirection
struct WebsiteRedirection: Codable, Equatable {
    let redirection: Int?
    let labelName: String?
}

