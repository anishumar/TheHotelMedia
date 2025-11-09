//
//  CollaborateViewModel.swift
//  TheHotelMedia
//
//  Created by MAC on 07/02/25.
//

import SwiftUI
import SwiftfulRouting
import Combine

class CollaborateViewModel: ObservableObject {
    
    var router: AnyRouter
    let dataManager = CollaborationDataManager()
    let tagPeopleDataManager = TagPeopleDataManager()
    var cancellables = Set<AnyCancellable>()
    var task: Task<(), Never>? = nil
    @Published var searchFieldText: String = ""
    @Published var profiles: [SearchProfile] = []
    @Published var newProfiles: [SearchProfile] = []
    @Published var isPagination: Bool = false
    @Published var selectedProfiles: [SearchProfile] = []
    @Published var showLoadingIndicator: Bool = false
    @Published var pageNumber: Int = 1
    @Published var totalPageNumber: Int = 1
    @Published var recentQuery: String = ""
    
    
    init(router: AnyRouter, selectedProfiles: [SearchProfile]? = nil) {
        self.router = router
        if let selectedProfiles {
            self.selectedProfiles = selectedProfiles
        }
        addSubscribers()
        getProfiles(pageNo: 1)
    }
    
    
    func addSubscribers() {
        $searchFieldText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }
                
                guard recentQuery != query else { return }
                recentQuery = query
                
                isPagination = false
                
                // Fetch search data
                pageNumber = 1
                totalPageNumber = 1
                
                getProfiles(query: query, pageNo: pageNumber)
            }
            .store(in: &cancellables)
        
        
        $newProfiles
            .map({ [weak self] (profiles) -> [SearchProfile] in
                guard let self else { return []}
                
                var array: [SearchProfile] = []
                for profile in profiles {
                    var mutableProfile = profile
                    if selectedProfiles.contains(where: {$0.id == profile.id}) {
                        mutableProfile.isSelected = true
                        array.append(mutableProfile)
                    } else {
                        mutableProfile.isSelected = false
                        array.append(mutableProfile)
                    }
                }
                
                return array
            })
            .sink { [weak self] profiles in
                guard let self else { return }
                
                if isPagination {
                    self.profiles += profiles
                } else {
                    self.profiles = profiles
                }
            }
            .store(in: &cancellables)
    }
    
    
    func dismissScreen() {
        router.dismissScreen()
    }
    
    
    func didTapProfileView(profile: SearchProfile) {
        if let index = profiles.firstIndex(where: {$0.id == profile.id}) {
            
            guard let isSelected = profiles[index].isSelected else {
                profiles[index].isSelected = true
                selectedProfiles.append(profile)
                return
            }
            
            profiles[index].isSelected = !isSelected
            
            if let isSelected = profiles[index].isSelected {
                if isSelected {
                    selectedProfiles.append(profile)
                } else {
                    selectedProfiles.removeAll(where: {$0.id == profile.id})
                }
            }
        }
    }
    
    
    func didDeselectProfile(profile: SearchProfile) {
        selectedProfiles.removeAll(where: {$0.id == profile.id})
        
        if let index = profiles.firstIndex(where: {$0.id == profile.id}) {
            profiles[index].isSelected = false
        }
    }
}


// MARK: - Networking
extension CollaborateViewModel {
    
    func getProfiles(query: String = "", pageNo: Int) {
        
        guard pageNumber <= totalPageNumber else { return }
        
        showLoadingIndicator = true
        
        task = Task {
            do {
                let result = try await tagPeopleDataManager.getTagPeople(pageNo: pageNo, query: query)
                
                let range = 200...204
                
                await MainActor.run {
                    showLoadingIndicator = false
                    if result.status && range.contains(result.statusCode) {
                        if let data = result.data {
                            newProfiles = data
                        }
                        pageNumber = result.pageNo ?? 1
                        totalPageNumber = result.totalPages ?? 1
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
}

