//
//  UserSelectionViewModel.swift
//  HotelMedia
//
//  Created by MAC on 07/02/25.
//

import Foundation
import Combine
import SwiftfulRouting

class UserSelectionViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = SearchDataManager()
    var cancellables = Set<AnyCancellable>()
    
    @Published var searchFieldText: String = ""
    @Published var searchProfileData: [SearchProfileData] = []
    @Published var profileDataPageNo: Int = 1
    @Published var profileDataTotalPages: Int = 1
    @Published var showLoadingIndicator: Bool = false
    
    var onUserSelected: ((String, String) -> Void)? // ID, Username
    var recentQuery: String = ""
    private var searchDataTask: Task<Void, Never>?
    
    init(router: AnyRouter, onUserSelected: ((String, String) -> Void)?) {
        self.router = router
        self.onUserSelected = onUserSelected
        addSubscribers()
    }
    
    private func addSubscribers() {
        $searchFieldText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }
                guard recentQuery != query else { return }
                recentQuery = query
                
                searchProfileData.removeAll()
                profileDataPageNo = 1
                getProfileResults(query: query, resetData: true)
            }
            .store(in: &cancellables)
    }
    
    func getProfileResults(query: String, resetData: Bool) {
        guard profileDataPageNo <= profileDataTotalPages else { return }
        
        showLoadingIndicator = true
        
        searchDataTask?.cancel()
        searchDataTask = Task {
            do {
                // Using nil for lat/lng/radius as we just want global user search
                let result = try await dataManager.getSearchProfileResults(
                    query: query,
                    pageNo: profileDataPageNo,
                    selectedTypes: [],
                    isnearby: false,
                    lat: nil,
                    lng: nil,
                    radius: 50
                )
                
                await MainActor.run {
                    showLoadingIndicator = false
                    let range = 200...204
                    
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            if resetData {
                                searchProfileData = data
                            } else {
                                searchProfileData += data
                            }
                        }
                        
                        profileDataPageNo = result.pageNo ?? 1
                        profileDataTotalPages = result.totalPages ?? 1
                    }
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    print(error)
                }
            }
        }
    }
    
    func dismissScreen() {
        router.dismissScreen()
    }
}
