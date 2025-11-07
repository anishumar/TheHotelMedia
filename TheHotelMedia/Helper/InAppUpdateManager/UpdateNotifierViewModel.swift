//
//  UpdateNotifierViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 08/01/25.
//

import Combine
import SwiftUI

class UpdateNotifierViewModel: ObservableObject {
    @Published var updateAvailable: Bool = false
    @Published var updateURL: URL? = nil
    @Published var showAlert: Bool = false

    private var cancellable: AnyCancellable?

    func checkForUpdate() {
        let fetcher = UpdateStatusFetcher()

        cancellable = fetcher.fetchUpdateStatus { [weak self] result in
            switch result {
            case .success(let status):
                switch status {
                case .upToDate:
                    print("App is up to date")
                case .updateAvailable(_, let storeURL):
                    DispatchQueue.main.async {
                        self?.updateAvailable = true
                        self?.updateURL = storeURL
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self?.showAlert = true
                        }
                    }
                }
            case .failure(let error):
                print("Failed to check for updates: \(error)")
            }
        }
    }
}
