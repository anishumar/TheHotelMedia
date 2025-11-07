//
//  JobDetailResponse.swift
//  TheHotelMedia
//
//  Created by MAC on 08/04/25.
//

import Foundation

// MARK: - JobDetailResponse
struct JobDetailResponse: Codable, Refreshable {
    let status: Bool
    let statusCode: Int
    let message: String
    let data: JobData?
}

// MARK: - JobData
struct JobData: Codable {
    let id, userID, businessProfileID, title: String?
    let designation, description, jobType, salary: String?
    let joiningDate, numberOfVacancies, experience, createdAt: String?
    let updatedAt: String?
    let v: Int?
    let dataID: String?
    let postedBy: PostedBy?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userID, businessProfileID, title, designation, description, jobType, salary, joiningDate, numberOfVacancies, experience, createdAt, updatedAt, postedBy
        case v = "__v"
        case dataID = "id"
    }
}
