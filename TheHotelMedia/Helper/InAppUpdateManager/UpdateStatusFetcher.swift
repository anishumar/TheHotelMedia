//
//  UpdateStatusFetcher.swift
//  TheHotelMedia
//
//  Created by MAC on 08/01/25.
//

import Foundation
import Combine

public struct UpdateStatusFetcher {
    public enum Status: Equatable {
        case upToDate
        case updateAvailable(version: String, storeURL: URL)
    }

    let url: URL
    private let decoder: JSONDecoder = JSONDecoder()
    private let urlSession: URLSession

    var currentVersionProvider: () -> String? = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    public init(bundleIdentifier: String = Bundle.main.bundleIdentifier!,
                urlSession: URLSession = .shared) {
        url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)&country=in")!  
        self.urlSession = urlSession
    }

    private func updateStatus(for appMetadata: AppMetadata) throws -> Status {
        guard let currentVersion = currentVersionProvider() else {
            throw FetchError.bundleShortVersion
        }

        switch currentVersion.compare(appMetadata.version, options: .numeric) {
        case .orderedSame, .orderedDescending:
            return .upToDate
        case .orderedAscending:
            return .updateAvailable(version: appMetadata.version, storeURL: appMetadata.trackViewUrl)
        }
    }

    public func fetchUpdateStatus(_ completion: @escaping (Result<Status, Error>) -> Void) -> AnyCancellable {
        urlSession
            .dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AppMetadataResults.self, decoder: decoder)
            .tryMap { metadataResults in
                guard let appMetadata = metadataResults.results.first else {
                    throw FetchError.metadata
                }
                return try updateStatus(for: appMetadata)
            }
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    completion(.failure(error))
                }
            }, receiveValue: { status in
                completion(.success(status))
            })
    }
}

extension UpdateStatusFetcher {
    enum FetchError: Error {
        case metadata
        case bundleShortVersion
    }
}

struct AppMetadata: Codable {
    let trackViewUrl: URL
    let version: String
}

struct AppMetadataResults: Codable {
    let results: [AppMetadata]
}

